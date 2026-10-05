#!/usr/bin/env python3
"""Durable, file-only task snapshots shared by independent Codex sessions."""
import argparse
import contextlib
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import stat
import subprocess
import sys
import tempfile
import time
import uuid
from typing import Any

SCHEMA = 1
OWNER = "codex-build-task-dashboard-v1\n"
MAX_FILE_BYTES = 32 * 1024 * 1024
MAX_TEXT = 4000
LOCK_SECONDS = 15
STALE_SECONDS = 600
ID = re.compile(r"[A-Za-z0-9][A-Za-z0-9_.-]{0,95}\Z")
TASK_STATUS = {"queued", "running", "testing", "review", "blocked", "failed", "done", "cancelled"}
SESSION_STATUS = {"active", "completed", "handoff", "stopped", "failed"}
GATES = {"pending", "passed", "failed", "unavailable", "not_required"}
RELEASE = {"not_requested", "pending", "published", "rejected"}


class DashboardError(Exception):
    pass


def now():
    return dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds")


def text(value, name, allow_empty=True):
    if not isinstance(value, str) or len(value) > MAX_TEXT or (not allow_empty and not value.strip()):
        raise DashboardError(f"Invalid {name}: expected text, at most {MAX_TEXT} characters")
    if any(ord(c) < 32 and c not in "\n\t" for c in value):
        raise DashboardError(f"Control characters in {name}")
    return value


def identifier(value, name):
    if not isinstance(value, str) or not ID.fullmatch(value) or value in {".", ".."}:
        raise DashboardError(f"Invalid {name}; use 1–96 letters, digits, dots, underscores or hyphens")
    return value


def timestamp(value):
    try:
        parsed = dt.datetime.fromisoformat(value)
        if parsed.tzinfo is None:
            raise ValueError("missing timezone")
        return parsed
    except (TypeError, ValueError):
        raise DashboardError("Invalid timestamp") from None


def enum(value, choices, name):
    if not isinstance(value, str) or value not in choices:
        raise DashboardError(f"Invalid {name}: choose {', '.join(sorted(choices))}")
    return value


def exact_fields(obj, fields, name):
    if not isinstance(obj, dict) or set(obj) != set(fields):
        raise DashboardError(f"Invalid {name} fields")


def evidence(values):
    from urllib.parse import urlsplit
    if not isinstance(values, list) or len(values) > 100:
        raise DashboardError("Evidence must be a list with at most 100 links")
    for value in values:
        text(value, "evidence URL", False)
        if any(c.isspace() for c in value) or "\\" in value:
            raise DashboardError("Evidence URLs must be encoded and contain no whitespace or backslashes")
        try:
            url = urlsplit(value)
            if url.username is not None or url.password is not None:
                raise ValueError("credentials")
            if url.scheme in {"http", "https"} and url.hostname:
                pass
            elif url.scheme == "file" and url.netloc in {"", "localhost"} and url.path.startswith("/"):
                pass
            else:
                raise ValueError("scheme")
        except ValueError:
            raise DashboardError("Evidence needs an absolute http(s) or local file URL without credentials") from None
    return values


def validate_task(task):
    exact_fields(task, {"id", "title", "status", "owner", "detail", "evidence", "updated"}, "task")
    identifier(task["id"], "task ID")
    text(task["title"], "title", False)
    enum(task["status"], TASK_STATUS, "task status")
    text(task["owner"], "owner")
    text(task["detail"], "detail")
    evidence(task["evidence"])
    timestamp(task["updated"])


def key_for(project, run, session):
    return hashlib.sha256(json.dumps([project, run, session], ensure_ascii=True).encode()).hexdigest()


def validate_board(board):
    exact_fields(board, {"schema", "revision", "updated", "opened", "sessions"}, "board")
    if board["schema"] != SCHEMA or type(board["revision"]) is not int or board["revision"] < 0:
        raise DashboardError("Unsupported schema or invalid revision")
    timestamp(board["updated"])
    if board["opened"] is not None:
        timestamp(board["opened"])
    if not isinstance(board["sessions"], dict):
        raise DashboardError("Invalid sessions")
    for key, session in board["sessions"].items():
        exact_fields(session, {"project", "run", "session", "title", "status", "note", "created", "updated", "build", "review", "release", "tasks", "history"}, "session")
        if not isinstance(session["project"], str) or not Path(session["project"]).is_absolute():
            raise DashboardError("Invalid project")
        identifier(session["run"], "run ID")
        identifier(session["session"], "session ID")
        if key != key_for(session["project"], session["run"], session["session"]):
            raise DashboardError("Session identity mismatch")
        text(session["title"], "session title", False)
        text(session["note"], "session note")
        enum(session["status"], SESSION_STATUS, "session status")
        enum(session["build"], GATES, "build acceptance")
        enum(session["review"], GATES, "review acceptance")
        enum(session["release"], RELEASE, "publication")
        timestamp(session["created"])
        timestamp(session["updated"])
        if not isinstance(session["tasks"], dict) or not isinstance(session["history"], list):
            raise DashboardError("Invalid task or history collection")
        for task_id, task in session["tasks"].items():
            validate_task(task)
            if task_id != task["id"]:
                raise DashboardError("Task identity mismatch")
        for event in session["history"]:
            exact_fields(event, {"at", "kind", "data"}, "history event")
            timestamp(event["at"])
            enum(event["kind"], {"created", "task", "session"}, "history kind")
            if not isinstance(event["data"], dict):
                raise DashboardError("Invalid history data")


def safe_path(path, directory=False, missing=False):
    """Reject symlink components and unexpected target types before every access."""
    path = Path(os.path.abspath(path))
    for component in list(reversed(path.parents)) + [path]:
        try:
            mode = component.lstat().st_mode
        except FileNotFoundError:
            if missing:
                continue
            raise DashboardError(f"Missing path: {component}") from None
        if stat.S_ISLNK(mode):
            raise DashboardError(f"Refusing symlink: {component}")
        if component != path and not stat.S_ISDIR(mode):
            raise DashboardError(f"Not a directory: {component}")
        if component == path and not (stat.S_ISDIR(mode) if directory else stat.S_ISREG(mode)):
            raise DashboardError(f"Unexpected path type: {path}")
    return path


def read_file(path):
    safe_path(path)
    flags = os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0)
    with os.fdopen(os.open(path, flags), "r", encoding="utf-8") as stream:
        info = os.fstat(stream.fileno())
        if not stat.S_ISREG(info.st_mode) or info.st_nlink != 1 or info.st_size > MAX_FILE_BYTES:
            raise DashboardError("Unsafe or oversized dashboard file")
        return stream.read(MAX_FILE_BYTES + 1)


def atomic_write(path, content):
    safe_path(path, missing=True)
    if path.exists() and path.stat().st_nlink != 1:
        raise DashboardError(f"Refusing hardlinked output: {path}")
    fd, tmp = tempfile.mkstemp(prefix=".write-", dir=path.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as stream:
            stream.write(content)
            stream.flush()
            os.fsync(stream.fileno())
        safe_path(path, missing=True)
        os.replace(tmp, path)
        if os.name != "nt":
            fd = os.open(path.parent, os.O_RDONLY | getattr(os, "O_DIRECTORY", 0))
            try:
                os.fsync(fd)
            finally:
                os.close(fd)
    finally:
        if os.path.exists(tmp):
            os.unlink(tmp)  # Only this command's never-published temporary file.


def state_root(override):
    if override:
        path = Path(override).expanduser()
    else:
        base = Path(os.environ.get("XDG_STATE_HOME") or str(Path.home() / ".local" / "state")).expanduser()
        path = base / "build-task-dashboard"
    if not path.is_absolute():
        raise DashboardError("State directory must be absolute")
    return path


class Store:
    def __init__(self, root, create=False):
        self.root = safe_path(root, directory=True, missing=create)
        self.board_path = self.root / "board.json"
        self.html_path = self.root / "tasks.html"
        if create:
            self.root.mkdir(mode=0o700, parents=True, exist_ok=True)
        safe_path(self.root, directory=True)
        info = self.root.stat()
        if hasattr(os, "getuid") and (info.st_uid != os.getuid() or info.st_mode & 0o022):
            raise DashboardError("State directory must be owned by you and not writable by others")
        # Owner creation uses exclusive creation, including across simultaneous first starts.
        marker = self.root / ".dashboard-owner"
        if create and not marker.exists():
            occupants = {p.name for p in self.root.iterdir()}
            if occupants and not marker.exists():
                raise DashboardError("Refusing to claim a nonempty unowned state directory")
            try:
                fd = os.open(marker, os.O_WRONLY | os.O_CREAT | os.O_EXCL | getattr(os, "O_NOFOLLOW", 0), 0o600)
                with os.fdopen(fd, "w", encoding="utf-8") as stream:
                    stream.write(OWNER)
            except FileExistsError:
                pass
        owner_text = read_file(marker)
        deadline = time.monotonic() + 1
        while create and not owner_text and time.monotonic() < deadline:
            time.sleep(0.02)
            owner_text = read_file(marker)
        if owner_text != OWNER:
            raise DashboardError("State directory has no recognized ownership marker")

    @contextlib.contextmanager
    def locked(self):
        path = self.root / ".lock"
        safe_path(path, missing=True)
        fd = os.open(path, os.O_RDWR | os.O_CREAT | getattr(os, "O_NOFOLLOW", 0), 0o600)
        try:
            info = os.fstat(fd)
            if not stat.S_ISREG(info.st_mode) or info.st_nlink != 1:
                raise DashboardError("Unsafe lock file")
            deadline = time.monotonic() + LOCK_SECONDS
            if os.name == "nt":
                import msvcrt
                if info.st_size == 0:
                    os.write(fd, b"0")
                def lock():
                    os.lseek(fd, 0, os.SEEK_SET)
                    msvcrt.locking(fd, msvcrt.LK_NBLCK, 1)
                def unlock():
                    os.lseek(fd, 0, os.SEEK_SET)
                    msvcrt.locking(fd, msvcrt.LK_UNLCK, 1)
            else:
                import fcntl
                def lock():
                    fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
                def unlock():
                    fcntl.flock(fd, fcntl.LOCK_UN)
            while True:
                try:
                    lock()
                    break
                except OSError:
                    if time.monotonic() >= deadline:
                        raise DashboardError("Dashboard lock timed out") from None
                    time.sleep(0.05)
            try:
                yield
            finally:
                unlock()
        finally:
            os.close(fd)

    def load(self, create=False) -> dict[str, Any]:
        if not self.board_path.exists():
            safe_path(self.board_path, missing=True)
            if not create:
                raise DashboardError("Unknown dashboard; use init first")
            if self.html_path.exists() or self.html_path.is_symlink():
                raise DashboardError("Refusing to replace an HTML file without its registry")
            return {"schema": SCHEMA, "revision": 0, "updated": now(), "opened": None, "sessions": {}}
        try:
            board = json.loads(read_file(self.board_path))
        except json.JSONDecodeError:
            raise DashboardError("Invalid registry JSON; preserve it for recovery") from None
        validate_board(board)
        return board

    def save(self, board):
        validate_board(board)
        content = json.dumps(board, ensure_ascii=False, indent=2) + "\n"
        if len(content.encode()) > MAX_FILE_BYTES:
            raise DashboardError("Registry capacity reached; preserve it and use a new explicit state directory")
        self.check_html()
        # Registry is authoritative; render can recover after interruption between replacements.
        atomic_write(self.board_path, content)
        self.render(board)

    def check_html(self):
        safe_path(self.html_path, missing=True)
        if self.html_path.exists() and "<!-- codex-build-task-dashboard-v1 -->" not in read_file(self.html_path):
            raise DashboardError("Refusing to replace an unrecognized HTML file")

    def render(self, board):
        self.check_html()
        template = (Path(__file__).resolve().parent.parent / "assets" / "dashboard.html").read_text(encoding="utf-8")
        # Escape HTML delimiters inside a JSON script element, even though rendering uses textContent.
        payload = json.dumps(board, ensure_ascii=True).replace("&", "\\u0026").replace("<", "\\u003c").replace(">", "\\u003e")
        atomic_write(self.html_path, template.replace('"__BOARD_JSON__"', payload).replace("__STALE_SECONDS__", str(STALE_SECONDS)))


def browser_commands(path):
    """Arguments are data; never interpolate paths into shell/PowerShell code."""
    uri = path.as_uri()
    if os.name == "nt":
        return [(None, str(path), None)]
    commands = []
    if sys.platform == "darwin":
        commands.append((["open", uri], None, None))
    elif os.environ.get("WSL_DISTRO_NAME") or "microsoft" in os.uname().release.lower():
        if shutil.which("wslpath") and shutil.which("powershell.exe"):
            result = subprocess.run(["wslpath", "-w", str(path)], capture_output=True, text=True, timeout=10, check=False)
            windows_path = result.stdout.rstrip("\r\n")
            if result.returncode == 0 and windows_path and not any(ord(c) < 32 for c in windows_path):
                env = os.environ.copy()
                env["CODEX_BUILD_DASHBOARD_PATH"] = windows_path
                # WSL does not export arbitrary Linux environment variables to Windows.
                # The path is already translated; /w exports it without /p retranslation.
                entries = [entry for entry in env.get("WSLENV", "").split(":") if entry and entry.split("/", 1)[0].casefold() != "codex_build_dashboard_path"]
                env["WSLENV"] = ":".join(entries + ["CODEX_BUILD_DASHBOARD_PATH/w"])
                script = '$ErrorActionPreference = "Stop"; Start-Process -FilePath $env:CODEX_BUILD_DASHBOARD_PATH'
                commands.append((["powershell.exe", "-NoProfile", "-NonInteractive", "-Command", script], None, env))
    commands.extend([(["xdg-open", uri], None, None), (["gio", "open", uri], None, None)])
    return commands


def launch_browser(path):
    errors = []
    for argv, native, env in browser_commands(path):
        try:
            if native:
                os.startfile(native)
                return "Windows default browser"
            assert argv is not None
            if not shutil.which(argv[0]):
                continue
            result = subprocess.run(argv, env=env, capture_output=True, text=True, timeout=10, check=False)
            if result.returncode == 0:
                return argv[0]
            errors.append(f"{argv[0]} exited {result.returncode}")
        except (OSError, subprocess.TimeoutExpired) as error:
            errors.append(f"{argv[0] if argv else 'Windows opener'}: {type(error).__name__}")
    raise DashboardError("Browser launch unavailable (" + "; ".join(errors) + "). Open this file manually: " + str(path))


def project_path(value):
    path = Path(value).expanduser().resolve(strict=True)
    if not path.is_dir():
        raise DashboardError("Project must be an existing directory")
    return str(path)


def session_identity(args):
    project = project_path(args.project)
    run = identifier(args.run, "run ID")
    session = identifier(args.session, "session ID")
    return project, run, session, key_for(project, run, session)


def load_initial_tasks(path) -> dict[str, Any]:
    if path is None:
        return {}
    raw = json.loads(read_file(Path(path).expanduser()))
    if not isinstance(raw, list):
        raise DashboardError("Initial tasks must be a JSON array")
    tasks = {}
    for item in raw:
        if not isinstance(item, dict) or set(item) - {"id", "title", "status", "owner", "detail", "evidence"}:
            raise DashboardError("Invalid initial task fields")
        task = {"id": item.get("id"), "title": item.get("title"), "status": item.get("status", "queued"), "owner": item.get("owner", ""), "detail": item.get("detail", ""), "evidence": item.get("evidence", []), "updated": now()}
        validate_task(task)
        if task["id"] in tasks:
            raise DashboardError("Duplicate initial task ID")
        tasks[task["id"]] = task
    return tasks


def run(args):
    root = state_root(args.state_dir)
    identity = None
    if args.command in {"init", "update"}:
        if args.command == "init" and not args.session:
            args.session = os.environ.get("CODEX_THREAD_ID") or "session-" + uuid.uuid4().hex[:16]
        identity = session_identity(args)
    initial = load_initial_tasks(args.tasks) if args.command == "init" else None
    store = Store(root, create=args.command == "init")
    with store.locked():
        board = store.load(create=args.command == "init")
        if args.command == "init":
            assert identity is not None and initial is not None
            project, run_id, session_id, key = identity
            resumed = key in board["sessions"]
            if resumed:
                if args.tasks is not None or args.title is not None:
                    raise DashboardError("Existing session: resume without --tasks/--title; update explicitly")
            else:
                title = text(args.title or f"{Path(project).name} · {run_id}", "session title", False)
                at = now()
                session = {"project": project, "run": run_id, "session": session_id, "title": title, "status": "active", "note": "", "created": at, "updated": at, "build": "pending", "review": "pending", "release": "not_requested", "tasks": initial, "history": [{"at": at, "kind": "created", "data": {"title": title, "tasks": json.loads(json.dumps(initial))}}]}
                board["sessions"][key] = session
                board["revision"] += 1
                board["updated"] = at
                store.save(board)
            if resumed:
                store.render(board)
            return {"resumed": resumed, "project": project, "run": run_id, "session": session_id, "dashboard": str(store.html_path), "revision": board["revision"]}
        if args.command == "update":
            assert identity is not None
            key = identity[3]
            if key not in board["sessions"]:
                raise DashboardError("Unknown project/run/session; initialize explicitly")
            session = board["sessions"][key]
            at = now()
            changes = {name: getattr(args, name) for name in ("title", "note", "build", "review", "release") if getattr(args, name) is not None}
            if args.session_status:
                changes["status"] = args.session_status
            if changes:
                for name in {"title", "note"} & changes.keys():
                    text(changes[name], name, name == "note")
                session.update(changes)
                session["history"].append({"at": at, "kind": "session", "data": changes.copy()})
            task_fields = ("task_title", "status", "owner", "detail", "evidence")
            if not args.task and (args.add or any(getattr(args, name) is not None for name in task_fields)):
                raise DashboardError("Task fields require --task")
            if args.task:
                task_id = identifier(args.task, "task ID")
                existing = session["tasks"].get(task_id)
                if args.add and existing:
                    raise DashboardError("Task already exists; omit --add to update")
                if not existing and not args.add:
                    raise DashboardError("Unknown task; add explicitly with --add --task-title")
                task = dict(existing) if existing else {"id": task_id, "title": args.task_title, "status": "queued", "owner": "", "detail": "", "evidence": [], "updated": at}
                for name in task_fields:
                    value = getattr(args, name)
                    if value is not None:
                        if name == "evidence":
                            task[name] = list(dict.fromkeys(task[name] + value))
                        else:
                            task["title" if name == "task_title" else name] = value
                task["updated"] = at
                validate_task(task)
                session["tasks"][task_id] = task
                session["history"].append({"at": at, "kind": "task", "data": dict(task)})
            if not changes and not args.task:
                raise DashboardError("No update supplied")
            session["updated"] = at
            board["updated"] = at
            board["revision"] += 1
            store.save(board)
            return {"revision": board["revision"], "session": session}
        if args.command == "open":
            store.render(board)
            if board["opened"] and not args.again:
                return {"opened": False, "reason": "Previously opened; use --again only when the window was closed", "dashboard": str(store.html_path)}
            launcher = launch_browser(store.html_path)
            board["opened"] = now()
            board["revision"] += 1
            store.save(board)
            return {"opened": True, "launcher": launcher, "dashboard": str(store.html_path)}
        if args.command == "render":
            store.render(board)
            return {"dashboard": str(store.html_path), "revision": board["revision"]}
        if args.command == "read":
            selected = board["sessions"].values()
            if args.project:
                project = project_path(args.project)
                selected = [s for s in selected if s["project"] == project]
            for field in ("run", "session"):
                value = getattr(args, field)
                if value:
                    identifier(value, field)
                    selected = [s for s in selected if s[field] == value]
            current = dt.datetime.now(dt.timezone.utc)
            sessions = [{**s, "stale": s["status"] == "active" and (current - timestamp(s["updated"])).total_seconds() >= STALE_SECONDS} for s in selected]
            return {"schema": board["schema"], "revision": board["revision"], "updated": board["updated"], "dashboard": str(store.html_path), "sessions": sessions}


def parser():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--state-dir", help="Explicit isolated directory; defaults to $XDG_STATE_HOME/build-task-dashboard")
    commands = p.add_subparsers(dest="command", required=True)
    init = commands.add_parser("init", help="Create a session, or resume the same identity without replacing tasks")
    update = commands.add_parser("update", help="Update only a known project/run/session")
    for command in (init, update):
        command.add_argument("--project", required=True)
        command.add_argument("--run", required=True)
        command.add_argument("--session", required=command is update)
        command.add_argument("--title")
    init.add_argument("--tasks", help="JSON array of initial task records")
    update.add_argument("--task")
    update.add_argument("--add", action="store_true")
    update.add_argument("--task-title")
    update.add_argument("--status", choices=sorted(TASK_STATUS))
    update.add_argument("--owner")
    update.add_argument("--detail")
    update.add_argument("--evidence", action="append")
    update.add_argument("--session-status", choices=sorted(SESSION_STATUS))
    update.add_argument("--note")
    update.add_argument("--build", choices=sorted(GATES))
    update.add_argument("--review", choices=sorted(GATES))
    update.add_argument("--release", choices=sorted(RELEASE))
    op = commands.add_parser("open", help="Open the shared board once across sessions")
    op.add_argument("--again", action="store_true", help="Explicitly reopen after a user closed the browser")
    rd = commands.add_parser("read", help="Read durable state and derived staleness")
    for name in ("project", "run", "session"):
        rd.add_argument("--" + name)
    commands.add_parser("render", help="Recover HTML from the authoritative registry")
    return p


def main():
    try:
        print(json.dumps(run(parser().parse_args()), ensure_ascii=False, indent=2))
        return 0
    except (DashboardError, OSError, UnicodeError, json.JSONDecodeError, subprocess.TimeoutExpired) as error:
        # Never dump input contents, environment, browser stderr, credentials or log bodies.
        print(f"dashboard: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
