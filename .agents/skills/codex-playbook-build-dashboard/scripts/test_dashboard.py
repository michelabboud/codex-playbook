#!/usr/bin/env python3
"""Behavioral tests. All state is run-owned; browser launchers are mocked."""
import concurrent.futures
import datetime as dt
import importlib.util
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest import mock
from typing import Any

sys.dont_write_bytecode = True
HELPER = Path(__file__).with_name("dashboard.py")
spec = importlib.util.spec_from_file_location("dashboard", HELPER)
assert spec is not None and spec.loader is not None
dashboard = importlib.util.module_from_spec(spec)
spec.loader.exec_module(dashboard)


class DashboardBehavior(unittest.TestCase):
    temp: Any = None
    base: Path = Path()
    state: Path = Path()
    project: Path = Path()
    identity: list[str] = []

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="codex-dashboard-test-")
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name).resolve()
        self.state = self.base / "state"
        self.project = self.base / "project"
        self.project.mkdir()
        self.identity = ["--project", str(self.project), "--run", "build-1", "--session", "codex-a"]

    def cli(self, *args, expected=0) -> Any:
        result = subprocess.run([sys.executable, "-B", str(HELPER), "--state-dir", str(self.state), *args], capture_output=True, text=True, timeout=30)
        self.assertEqual(result.returncode, expected, result.stderr)
        return json.loads(result.stdout) if expected == 0 else result

    def init(self, identity=None, *extra):
        return self.cli("init", *(identity or self.identity), *extra)

    def update(self, *extra, identity=None):
        return self.cli("update", *(identity or self.identity), *extra)

    def board(self):
        return json.loads((self.state / "board.json").read_text())

    def snapshot(self):
        return {name: (self.state / name).read_bytes() for name in ("board.json", "tasks.html")}

    def test_create_resume_preserves_failure_and_initial_history(self):
        initial = self.base / "tasks.json"
        initial.write_text(json.dumps([{"id": "test", "title": "Regression", "status": "queued"}]))
        created = self.init(None, "--tasks", str(initial))
        self.assertFalse(created["resumed"])
        self.update("--task", "test", "--status", "failed", "--detail", "Expected 1, received 0", "--evidence", "https://example.com/check/1")
        self.update("--task", "test", "--status", "testing", "--detail", "Repair retest running")
        before = self.snapshot()
        resumed = self.init()
        self.assertTrue(resumed["resumed"])
        self.assertEqual(self.snapshot(), before)
        session = self.cli("read")["sessions"][0]
        self.assertEqual(session["tasks"]["test"]["status"], "testing")
        self.assertEqual(session["history"][0]["data"]["tasks"]["test"]["status"], "queued")
        self.assertEqual(session["history"][1]["data"]["status"], "failed")
        self.assertEqual(session["tasks"]["test"]["evidence"], ["https://example.com/check/1"])
        self.cli("init", *self.identity, "--tasks", str(initial), expected=2)
        self.assertEqual(self.snapshot(), before)

    def test_unknown_run_task_and_duplicate_add_are_refused(self):
        self.init()
        before = self.snapshot()
        wrong = self.identity[:-1] + ["codex-unknown"]
        self.cli("update", *wrong, "--note", "Do not create a session", expected=2)
        self.cli("update", *self.identity, "--task", "unknown", "--status", "done", expected=2)
        self.assertEqual(self.snapshot(), before)
        self.update("--task", "test", "--add", "--task-title", "Test")
        before = self.snapshot()
        self.cli("update", *self.identity, "--task", "test", "--add", "--task-title", "Replace", expected=2)
        self.assertEqual(self.snapshot(), before)

    def test_invalid_ids_schema_status_and_evidence_do_not_mutate(self):
        self.init()
        before = self.snapshot()
        for task in ("../escape", ".", "..", "bad/id", "x y"):
            self.cli("update", *self.identity, "--task", task, "--add", "--task-title", "Denied", expected=2)
        self.cli("update", *self.identity, "--session-status", "imaginary", expected=2)
        for url in ("javascript:alert(1)", "https://u:secret@example.com", "file://evil/share", "https://example.com/a b", "data:text/html,hello"):
            self.cli("update", *self.identity, "--task", "link", "--add", "--task-title", "Link", "--evidence", url, expected=2)
        self.assertEqual(self.snapshot(), before)
        board = self.board()
        board["schema"] = 99
        (self.state / "board.json").write_text(json.dumps(board))
        self.cli("read", expected=2)

    def test_cross_session_and_project_concurrent_posts_preserve_all(self):
        identities = [self.identity]
        second = self.base / "another-project"
        second.mkdir()
        for i in range(1, 6):
            identities.append(["--project", str(second if i % 2 else self.project), "--run", "build-1", "--session", f"codex-{i}"])
        with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
            list(pool.map(self.init, identities))
        def post(item):
            identity, number = item
            return self.update("--task", f"check-{number}", "--add", "--task-title", f"Check {number}", "--status", "running", identity=identity)
        jobs = [(identity, number) for identity in identities for number in range(4)]
        with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
            list(pool.map(post, jobs))
        state = self.cli("read")
        self.assertEqual(len(state["sessions"]), 6)
        self.assertEqual(state["revision"], 30)
        for session in state["sessions"]:
            self.assertEqual(len(session["tasks"]), 4)
            self.assertEqual(len(session["history"]), 5)
        embedded = re.search(r'id="board-data">(.*?)</script>', (self.state / "tasks.html").read_text(), re.S)
        self.assertIsNotNone(embedded)
        assert embedded is not None
        self.assertEqual(json.loads(embedded[1])["revision"], state["revision"])

    def test_concurrent_updates_to_same_task_preserve_different_fields(self):
        self.init()
        self.update("--task", "test", "--add", "--task-title", "Regression")
        with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
            futures = [pool.submit(self.update, "--task", "test", "--owner", "Reviewer"), pool.submit(self.update, "--task", "test", "--detail", "Result recorded")]
            for future in futures:
                future.result()
        task = self.cli("read")["sessions"][0]["tasks"]["test"]
        self.assertEqual(task["owner"], "Reviewer")
        self.assertEqual(task["detail"], "Result recorded")

    def test_malicious_markup_is_json_escaped(self):
        attack = '</script><script>alert("bad")</script><img src=x onerror=alert(1)>&'
        self.init(None, "--title", attack)
        self.update("--task", "markup", "--add", "--task-title", attack, "--detail", attack)
        html = (self.state / "tasks.html").read_text()
        self.assertNotIn(attack, html)
        self.assertNotIn("<img src=x", html)
        encoded = re.search(r'id="board-data">(.*?)</script>', html, re.S)
        assert encoded is not None
        restored = json.loads(encoded[1])
        self.assertEqual(next(iter(restored["sessions"].values()))["title"], attack)
        self.assertNotIn("<", encoded[1])

    def test_template_markers_and_markup_preserve_complete_embedded_board(self):
        self.project = self.base / "__BOARD_JSON__-__STALE_SECONDS__"
        self.project.mkdir()
        self.identity[1] = str(self.project)
        summary = '"__BOARD_JSON__" __STALE_SECONDS__ </script><script>alert("data")</script>&'
        links = [
            "https://example.com/__BOARD_JSON__/__STALE_SECONDS__?detail=%3Ctag%3E%26",
            (self.project / "__STALE_SECONDS__-__BOARD_JSON__.md").as_uri(),
        ]
        self.init(None, "--title", summary)
        self.update("--title", summary, "--note", summary, "--task", "tokens", "--add",
                    "--task-title", summary, "--owner", summary, "--detail", summary,
                    "--evidence", links[0], "--evidence", links[1])
        expected = self.board()
        registry_bytes = (self.state / "board.json").read_bytes()
        for rerender in (False, True):
            with self.subTest(rerender=rerender):
                if rerender:
                    self.cli("render")
                self.assertEqual((self.state / "board.json").read_bytes(), registry_bytes)
                html = (self.state / "tasks.html").read_text()
                embedded = re.search(r'id="board-data">(.*?)</script>', html, re.S)
                self.assertIsNotNone(embedded)
                assert embedded is not None
                self.assertNotIn("<", embedded[1])
                self.assertEqual(json.loads(embedded[1]), expected)

    def test_unicode_html_capacity_refusal_preserves_state_and_next_post(self):
        # UTF-8 registry text fits this limit, but ASCII-escaped HTML expands past it.
        for existing in (False, True):
            self.state = self.base / f"unicode-state-{existing}"
            with self.subTest(existing=existing), mock.patch.object(dashboard, "MAX_FILE_BYTES", 32 * 1024):
                def invoke(*args):
                    parsed = dashboard.parser().parse_args(["--state-dir", str(self.state), *args])
                    return dashboard.run(parsed)
                if existing:
                    invoke("init", *self.identity)
                before = {
                    name: (self.state / name).read_bytes() if (self.state / name).exists() else None
                    for name in ("board.json", "tasks.html")
                }
                if existing:
                    proposed = ("update", *self.identity, "--task", "unicode", "--add", "--task-title", "é" * 2000)
                else:
                    proposed = ("init", *self.identity, "--title", "é" * 2000)
                with self.assertRaisesRegex(dashboard.DashboardError, "capacity"):
                    invoke(*proposed)
                after = {
                    name: (self.state / name).read_bytes() if (self.state / name).exists() else None
                    for name in ("board.json", "tasks.html")
                }
                self.assertEqual(after, before)
                if not existing:
                    invoke("init", *self.identity)
                invoke("update", *self.identity, "--note", "A valid post still works after capacity refusal")
                invoke("render")
                html = (self.state / "tasks.html").read_text()
                embedded = re.search(r'id="board-data">(.*?)</script>', html, re.S)
                assert embedded is not None
                self.assertEqual(json.loads(embedded[1]), self.board())

    def test_staleness_is_per_session_and_completed_is_not_live(self):
        self.init()
        other = self.identity[:-1] + ["codex-b"]
        self.init(other)
        store = dashboard.Store(self.state)
        with store.locked():
            board = store.load()
            key = dashboard.key_for(str(self.project), "build-1", "codex-a")
            board["sessions"][key]["updated"] = (dt.datetime.now(dt.timezone.utc) - dt.timedelta(minutes=11)).isoformat()
            store.save(board)
        sessions = {s["session"]: s for s in self.cli("read")["sessions"]}
        self.assertTrue(sessions["codex-a"]["stale"])
        self.assertFalse(sessions["codex-b"]["stale"])
        self.update("--session-status", "completed")
        self.assertFalse(self.cli("read", "--session", "codex-a")["sessions"][0]["stale"])

    def test_build_review_release_and_task_done_are_independent(self):
        self.init()
        self.update("--task", "build", "--add", "--task-title", "Build", "--status", "done", "--build", "passed", "--review", "failed", "--release", "pending")
        session = self.cli("read")["sessions"][0]
        self.assertEqual((session["build"], session["review"], session["release"]), ("passed", "failed", "pending"))
        self.update("--session-status", "handoff", "--note", "Review repair remains open")
        self.assertEqual(self.cli("read")["sessions"][0]["status"], "handoff")

    @unittest.skipIf(os.name == "nt", "POSIX symlink/hardlink fixture")
    def test_symlink_and_hardlink_hazards_are_refused(self):
        self.init()
        user_file = self.base / "user-data"
        user_file.write_text("preserve me")
        (self.state / "tasks.html").unlink()  # This test's generated output only.
        (self.state / "tasks.html").symlink_to(user_file)
        before = (self.state / "board.json").read_bytes()
        self.cli("update", *self.identity, "--note", "Denied", expected=2)
        self.assertEqual((self.state / "board.json").read_bytes(), before)
        self.assertEqual(user_file.read_text(), "preserve me")
        self.cli("read")  # Registry remains readable independently of broken rendering.
        (self.state / "tasks.html").unlink()
        os.link(user_file, self.state / "tasks.html")
        self.cli("render", expected=2)
        alias = self.base / "state-alias"
        alias.symlink_to(self.state, target_is_directory=True)
        self.assertRaises(dashboard.DashboardError, dashboard.Store, alias)

    def test_unowned_user_html_is_not_overwritten(self):
        self.init()
        (self.state / "tasks.html").write_text("my unrelated page")
        before = (self.state / "board.json").read_bytes()
        self.cli("update", *self.identity, "--note", "Do not replace", expected=2)
        self.assertEqual((self.state / "tasks.html").read_text(), "my unrelated page")
        self.assertEqual((self.state / "board.json").read_bytes(), before)

    def test_unowned_nonempty_state_and_relative_state_are_refused(self):
        self.state.mkdir()
        (self.state / "notes.txt").write_text("User file")
        self.cli("init", *self.identity, expected=2)
        self.assertEqual(list(self.state.iterdir()), [self.state / "notes.txt"])
        self.assertRaises(dashboard.DashboardError, dashboard.state_root, "relative-dir")

    def test_user_html_swapped_after_registry_commit_is_preserved(self):
        self.init()
        previous_revision = self.board()["revision"]
        user_html = b"<!doctype html><title>User-authored page</title><p>Preserve this page.</p>"
        actual_write = dashboard.atomic_write
        writes = []
        def swap_after_registry(path, content):
            writes.append(path)
            actual_write(path, content)
            if path == self.state / "board.json":
                (self.state / "tasks.html").write_bytes(user_html)
        note = "Registry update committed before the ownership change"
        args = dashboard.parser().parse_args(["--state-dir", str(self.state), "update", *self.identity, "--note", note])
        with mock.patch.object(dashboard, "atomic_write", side_effect=swap_after_registry):
            with self.assertRaisesRegex(dashboard.DashboardError, "unrecognized HTML file") as refused:
                dashboard.run(args)
        self.assertEqual(writes, [self.state / "board.json"])
        self.assertEqual((self.state / "tasks.html").read_bytes(), user_html)
        self.assertNotIn(user_html.decode(), str(refused.exception))
        self.assertNotIn(note, str(refused.exception))
        committed = (self.state / "board.json").read_bytes()
        self.assertEqual(self.board()["revision"], previous_revision + 1)
        self.assertEqual(self.cli("read")["sessions"][0]["note"], note)
        self.cli("render", expected=2)
        self.assertEqual((self.state / "tasks.html").read_bytes(), user_html)
        self.assertEqual((self.state / "board.json").read_bytes(), committed)

    def test_render_recovers_missing_html_without_changing_registry(self):
        self.init()
        before = (self.state / "board.json").read_bytes()
        (self.state / "tasks.html").unlink()
        self.cli("render")
        self.assertIn("Every session. One view.", (self.state / "tasks.html").read_text())
        self.assertEqual((self.state / "board.json").read_bytes(), before)

    def test_open_is_shared_once_and_failures_are_not_marked_open(self):
        self.init()
        args = dashboard.parser().parse_args(["--state-dir", str(self.state), "open"])
        with mock.patch.object(dashboard, "launch_browser", side_effect=dashboard.DashboardError("No display")):
            self.assertRaises(dashboard.DashboardError, dashboard.run, args)
        self.assertIsNone(self.board()["opened"])
        with mock.patch.object(dashboard, "launch_browser", return_value="mock-launcher") as launch:
            self.assertTrue(dashboard.run(args)["opened"])
            other = self.identity[:-1] + ["codex-b"]
            self.init(other)
            self.assertFalse(dashboard.run(args)["opened"])
            launch.assert_called_once()
            args.again = True
            self.assertTrue(dashboard.run(args)["opened"])
            self.assertEqual(launch.call_count, 2)

    def test_opener_linux_and_macos_fallback_arguments_are_data(self):
        path = self.base / "quotes ' ; $(echo danger) dashboard.html"
        with mock.patch.object(dashboard.sys, "platform", "darwin"), mock.patch.object(dashboard.shutil, "which", return_value="/mock/launcher"), mock.patch.object(dashboard.subprocess, "run", return_value=subprocess.CompletedProcess([], 0, "", "")) as launch:
            self.assertEqual(dashboard.launch_browser(path), "open")
            self.assertEqual(launch.call_args.args[0], ["open", path.as_uri()])
            self.assertNotIn("shell", launch.call_args.kwargs)
        with mock.patch.object(dashboard.sys, "platform", "linux"), mock.patch.dict(os.environ, {"WSL_DISTRO_NAME": ""}), mock.patch.object(dashboard.os, "uname", return_value=type("Uname", (), {"release": "linux"})()), mock.patch.object(dashboard.shutil, "which", return_value="/mock/launcher"), mock.patch.object(dashboard.subprocess, "run", side_effect=[subprocess.CompletedProcess([], 1, "", ""), subprocess.CompletedProcess([], 0, "", "")]) as launch:
            self.assertEqual(dashboard.launch_browser(path), "gio")
            self.assertEqual(launch.call_args.args[0], ["gio", "open", path.as_uri()])

    @unittest.skipIf(os.name == "nt", "WSL conversion fallback fixture")
    def test_wsl_conversion_failure_uses_available_linux_fallback(self):
        for error in (subprocess.TimeoutExpired(["wslpath"], 10), OSError("conversion unavailable")):
            with self.subTest(error=type(error).__name__):
                self.state = self.base / type(error).__name__
                self.init()
                args = dashboard.parser().parse_args(["--state-dir", str(self.state), "open"])
                def response(argv, **kwargs):
                    if argv[0] == "wslpath":
                        raise error
                    self.assertEqual(argv, ["xdg-open", (self.state / "tasks.html").as_uri()])
                    return subprocess.CompletedProcess(argv, 0, "", "")
                with mock.patch.object(dashboard.sys, "platform", "linux"), mock.patch.dict(os.environ, {"WSL_DISTRO_NAME": "Ubuntu"}), mock.patch.object(dashboard.shutil, "which", return_value="/mock/launcher"), mock.patch.object(dashboard.subprocess, "run", side_effect=response):
                    result = dashboard.run(args)
                self.assertTrue(result["opened"])
                self.assertEqual(result["launcher"], "xdg-open")
                self.assertIsNotNone(self.board()["opened"])

    @unittest.skipIf(os.name == "nt", "WSL conversion fallback fixture")
    def test_wsl_conversion_timeout_and_failed_fallbacks_keep_manual_hint(self):
        self.init()
        before = self.snapshot()
        args = dashboard.parser().parse_args(["--state-dir", str(self.state), "open"])
        attempted = []
        def response(argv, **kwargs):
            attempted.append(argv[0])
            if argv[0] == "wslpath":
                raise subprocess.TimeoutExpired(argv, 10, output="do-not-expose-output", stderr="do-not-expose-stderr")
            return subprocess.CompletedProcess(argv, 1, "do-not-expose-output", "do-not-expose-stderr")
        with mock.patch.object(dashboard.sys, "platform", "linux"), mock.patch.dict(os.environ, {"WSL_DISTRO_NAME": "Ubuntu"}), mock.patch.object(dashboard.shutil, "which", return_value="/mock/launcher"), mock.patch.object(dashboard.subprocess, "run", side_effect=response):
            with self.assertRaises(dashboard.DashboardError) as failed:
                dashboard.run(args)
        self.assertEqual(attempted, ["wslpath", "xdg-open", "gio"])
        self.assertIn("Open this file manually: " + str(self.state / "tasks.html"), str(failed.exception))
        self.assertNotIn("do-not-expose", str(failed.exception))
        self.assertIsNone(self.board()["opened"])
        self.assertEqual(self.snapshot(), before)

    def test_wsl_powershell_path_not_interpolated_into_code(self):
        path = self.base / "page '$([System.IO.File]::Delete('x')).html"
        windows_path = "\\\\wsl.localhost\\Ubuntu\\home\\page '$([System.IO.File]::Delete('x')).html"
        def response(argv, **kwargs):
            if argv[0] == "wslpath":
                return subprocess.CompletedProcess(argv, 0, windows_path + "\n", "")
            self.assertEqual(argv[0], "powershell.exe")
            self.assertNotIn(windows_path, argv[-1])
            self.assertEqual(kwargs["env"]["CODEX_BUILD_DASHBOARD_PATH"], windows_path)
            self.assertEqual(kwargs["env"]["WSLENV"], "KEEP/p:OTHER/lw:CODEX_BUILD_DASHBOARD_PATH/w")
            self.assertNotIn("shell", kwargs)
            return subprocess.CompletedProcess(argv, 0, "", "")
        with mock.patch.object(dashboard.sys, "platform", "linux"), mock.patch.dict(os.environ, {"WSL_DISTRO_NAME": "Ubuntu", "WSLENV": "KEEP/p:CODEX_BUILD_DASHBOARD_PATH/p:OTHER/lw"}), mock.patch.object(dashboard.shutil, "which", return_value="/mock/launcher"), mock.patch.object(dashboard.subprocess, "run", side_effect=response):
            self.assertEqual(dashboard.launch_browser(path), "powershell.exe")
            self.assertEqual(os.environ["WSLENV"], "KEEP/p:CODEX_BUILD_DASHBOARD_PATH/p:OTHER/lw")

    @unittest.skipUnless(os.name != "nt" and (os.environ.get("WSL_DISTRO_NAME") or "microsoft" in os.uname().release.lower()) and shutil.which("wslpath") and shutil.which("powershell.exe"), "Requires real WSL Windows interop")
    def test_real_windows_child_receives_literal_path(self):
        # Read the environment as JSON. No Start-Process, path evaluation, or browser.
        path = self.base / "spaces ' quotes $(not-executed) dashboard.html"
        plans = dashboard.browser_commands(path)
        self.assertEqual(plans[0][0][0], "powershell.exe")
        argv, _, env = plans[0]
        probe = list(argv[:-1]) + ['ConvertTo-Json -Compress -InputObject $env:CODEX_BUILD_DASHBOARD_PATH']
        result = subprocess.run(probe, env=env, capture_output=True, text=True, timeout=10)
        self.assertEqual(result.returncode, 0, "Windows environment probe failed")
        self.assertEqual(json.loads(result.stdout.strip()), env["CODEX_BUILD_DASHBOARD_PATH"])

    def test_filter_and_generated_session_id(self):
        with mock.patch.dict(os.environ, {"CODEX_THREAD_ID": ""}):
            created = self.cli("init", "--project", str(self.project), "--run", "build-1")
        self.assertTrue(created["session"].startswith("session-"))
        self.assertEqual(len(self.cli("read", "--project", str(self.project), "--run", "build-1", "--session", created["session"])["sessions"]), 1)
        self.assertEqual(self.cli("read", "--session", "unknown")["sessions"], [])

    def test_native_windows_handler_receives_literal_path(self):
        path = self.base / "page ' $(danger).html"
        with mock.patch.object(dashboard.os, "name", "nt"), mock.patch.object(dashboard.os, "startfile", create=True) as opener:
            self.assertEqual(dashboard.launch_browser(path), "Windows default browser")
            opener.assert_called_once_with(str(path))

    def test_unset_or_empty_xdg_uses_home_state_fallback(self):
        fallback = Path.home() / ".local" / "state" / "build-task-dashboard"
        with mock.patch.dict(os.environ, {}, clear=True), mock.patch.object(dashboard.Path, "home", return_value=fallback.parents[2]):
            self.assertEqual(dashboard.state_root(None), fallback)
        with mock.patch.dict(os.environ, {"XDG_STATE_HOME": ""}):
            self.assertEqual(dashboard.state_root(None), fallback)
        configured = self.base / "configured-state"
        with mock.patch.dict(os.environ, {"XDG_STATE_HOME": str(configured)}):
            self.assertEqual(dashboard.state_root(None), configured / "build-task-dashboard")


if __name__ == "__main__":
    unittest.main(verbosity=2)
