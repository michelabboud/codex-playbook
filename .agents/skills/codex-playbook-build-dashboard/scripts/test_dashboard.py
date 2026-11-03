#!/usr/bin/env python3
"""Behavioral tests. All state is run-owned; browser launchers are mocked."""
import concurrent.futures
import datetime as dt
import importlib.util
import json
import os
from pathlib import Path
import re
import shlex
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

    def plan(self) -> dict[str, Any]:
        return {"id": "dashboard-plan", "title": "Explicit current plan", "objective": "Show what is being built",
                "source": str(self.base / "not-a-file-to-read" / "PLAN.md"), "status": "active", "phase": "Implement",
                "current_step": "build", "next_step": "Verify the resulting behavior",
                "steps": [{"id": "build", "title": "Build the feature", "status": "running"},
                          {"id": "verify", "title": "Verify the feature", "status": "queued"}]}

    def test_declared_plan_only_replace_clear_and_ordinary_updates_preserve_history(self):
        self.init()
        declaration = self.plan()
        plan_path = self.base / "explicit-plan.json"
        plan_path.write_text(json.dumps(declaration))
        first = self.update("--plan-json", str(plan_path))["session"]
        self.assertEqual(first["history"][-1]["kind"], "session")
        self.assertEqual(first["history"][-1]["data"], {"project_plan": declaration})
        self.assertNotIn("project_plan", first)
        self.assertEqual(first["tasks"], {})
        first_event = first["history"][-1]
        self.update("--note", "An ordinary session update leaves the declared plan intact")
        self.update("--task", "task", "--add", "--task-title", "An independent task snapshot")
        own = self.cli("read")["sessions"][0]
        self.assertEqual(own["history"][1], first_event)
        self.assertNotIn("project_plan", own["history"][-1]["data"])
        self.assertNotIn("project_plan", own["history"][-2]["data"])
        replacement = {**declaration, "title": "Updated complete declaration", "phase": "Verify", "current_step": "verify", "next_step": ""}
        plan_path.write_text(json.dumps(replacement))
        own = self.update("--plan-json", str(plan_path), "--note", "Replace explicitly")["session"]
        self.assertEqual(own["history"][-1]["data"], {"note": "Replace explicitly", "project_plan": replacement})
        own = self.update("--clear-plan")["session"]
        self.assertEqual(own["history"][-1]["data"], {"project_plan": None})
        self.assertEqual(own["history"][1], first_event)
        self.assertFalse(Path(declaration["source"]).exists())
        dashboard.validate_board(self.board())

    def test_plan_declarations_remain_scoped_to_exact_project_run_and_session(self):
        self.init()
        other = self.identity[:-1] + ["codex-b"]
        self.init(other)
        sibling_before = self.cli("read", "--session", "codex-b")["sessions"][0]
        path = self.base / "plan.json"
        path.write_text(json.dumps(self.plan()))
        self.update("--plan-json", str(path))
        self.update("--clear-plan")
        self.assertEqual(self.cli("read", "--session", "codex-b")["sessions"][0], sibling_before)
        before = self.snapshot()
        wrong = self.identity[:-1] + ["not-initialized"]
        self.cli("update", *wrong, "--plan-json", str(path), expected=2)
        self.assertEqual(self.snapshot(), before)

    def test_invalid_declared_plans_leave_state_unchanged_and_read_validation_rejects_them(self):
        self.init()
        valid = self.plan()
        path = self.base / "plan.json"
        invalid = [None, [], {}, {**valid, "extra": "not allowed"}, {k: v for k, v in valid.items() if k != "phase"},
                   {**valid, "id": "../escape"}, {**valid, "title": " "}, {**valid, "objective": "x" * (dashboard.MAX_TEXT + 1)},
                   {**valid, "source": 12}, {**valid, "phase": "bad\x01control"}, {**valid, "status": "running"},
                   {**valid, "current_step": "undeclared"}, {**valid, "current_step": None}, {**valid, "steps": {}},
                   {**valid, "steps": valid["steps"] * 51}, {**valid, "steps": valid["steps"] + [valid["steps"][0]]},
                   {**valid, "steps": [{"id": "build", "title": "Build", "status": "running", "extra": True}]},
                   {**valid, "steps": [{"id": "build", "title": "", "status": "running"}]},
                   {**valid, "steps": [{"id": "build", "title": "Build", "status": "imaginary"}]}]
        before = self.snapshot()
        for value in invalid:
            with self.subTest(value=str(value)[:100]):
                path.write_text(json.dumps(value))
                self.cli("update", *self.identity, "--plan-json", str(path), "--note", "Do not partially commit", expected=2)
                self.assertEqual(self.snapshot(), before)
                if value is not None:
                    board = self.board()
                    next(iter(board["sessions"].values()))["history"].append({"at": dashboard.now(), "kind": "session", "data": {"project_plan": value}})
                    with self.assertRaises(dashboard.DashboardError):
                        dashboard.validate_board(board)
        path.write_text("{malformed")
        self.cli("update", *self.identity, "--plan-json", str(path), expected=2)
        self.assertEqual(self.snapshot(), before)
        path.write_text(json.dumps(valid))
        self.cli("update", *self.identity, "--plan-json", str(path), "--clear-plan", expected=2)
        self.assertEqual(self.snapshot(), before)

    def test_plan_file_is_bounded_and_protected_before_state_creation(self):
        path = self.base / "plan.json"
        path.write_text(json.dumps(self.plan()))
        args = dashboard.parser().parse_args(["--state-dir", str(self.state), "update", *self.identity, "--plan-json", str(path)])
        with mock.patch.object(dashboard, "MAX_FILE_BYTES", 64):
            self.assertRaisesRegex(dashboard.DashboardError, "oversized", dashboard.run, args)
        self.assertFalse(self.state.exists())
        if hasattr(os, "symlink"):
            alias = self.base / "plan-alias.json"
            alias.symlink_to(path)
            args.plan_json = str(alias)
            self.assertRaisesRegex(dashboard.DashboardError, "symlink", dashboard.run, args)
            self.assertFalse(self.state.exists())

    def test_empty_steps_and_all_declared_plan_statuses_are_valid(self):
        self.init()
        path = self.base / "plan.json"
        for status in ("active", "blocked", "completed", "cancelled"):
            plan = {**self.plan(), "steps": [], "current_step": "", "status": status}
            path.write_text(json.dumps(plan))
            self.update("--plan-json", str(path))
            self.assertEqual(self.cli("read")["sessions"][0]["history"][-1]["data"]["project_plan"], plan)

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

    def test_context_is_optional_event_snapshot_and_never_changes_v1_task_schema(self):
        self.init()
        other = self.identity[:-1] + ["codex-b"]
        self.init(other)
        self.update("--task", "test", "--add", "--task-title", "Context task", identity=other)
        sibling_before = next(s for s in self.cli("read")["sessions"] if s["session"] == "codex-b")
        context = {"description": "What this task changes", "model": "reported-model", "effort": "high",
                   "agent_id": "worker-1", "agent_url": "https://example.com/agent/1?q=%27",
                   "codex_thread_id": "12345678-1234-5678-abcd-123456789abc", "worktree": str(self.project),
                   "command": "python3 'quoted command.py'", "last_progress": "2026-11-03T12:00:00Z",
                   "next_checkpoint": "2026-11-03T12:10:00+02:00", "blocker": "", "decision": "Use file-only storage"}
        flags = [part for name, value in context.items() for part in ("--" + name.replace("_", "-"), value)]
        self.update("--task", "test", "--add", "--task-title", "Context task", *flags)
        sessions = {s["session"]: s for s in self.cli("read")["sessions"]}
        self.assertEqual(sessions["codex-b"], sibling_before)
        own = sessions["codex-a"]
        self.assertEqual(set(own["tasks"]["test"]), {"id", "title", "status", "owner", "detail", "evidence", "updated"})
        self.assertEqual(own["history"][-1]["data"]["agent_context"], context)
        self.update("--task", "test", "--model", "replacement")
        own = self.cli("read", "--session", "codex-a")["sessions"][0]
        self.assertEqual(own["history"][-1]["data"]["agent_context"], {"model": "replacement"})
        self.update("--task", "test", "--detail", "Ordinary legacy-compatible update")
        own = self.cli("read", "--session", "codex-a")["sessions"][0]
        self.assertNotIn("agent_context", own["history"][-1]["data"])
        self.assertEqual(own["history"][-3]["data"]["agent_context"], context)

    def test_bad_context_and_context_without_task_leave_all_state_unchanged(self):
        self.init()
        before = self.snapshot()
        for flag in dashboard.CONTEXT_FIELDS:
            self.cli("update", *self.identity, "--" + flag.replace("_", "-"), "value", expected=2)
        rejected = {"agent-url": ["javascript:alert(1)", "codex://thread/1", "http://example.com/", "https://u:secret@example.com", "https://example.com/a b", "https://example.com\\path", "https://example.com:bad/"],
                    "codex-thread-id": ["arbitrary-session", "1234567812345678abcd123456789abc", "12345678-1234-5678-ABCD-123456789ABC"],
                    "last-progress": ["2026-11-03T12:00:00", "just now"],
                    "next-checkpoint": ["2026-11-03", "in ten minutes"],
                    "description": ["x" * (dashboard.MAX_TEXT + 1), "bad\x01text"]}
        for flag, values in rejected.items():
            for value in values:
                with self.subTest(flag=flag, value=value[:60]):
                    self.cli("update", *self.identity, "--task", "bad", "--add", "--task-title", "Bad context", "--" + flag, value, expected=2)
        self.assertEqual(self.snapshot(), before)

    def test_historic_task_event_extra_keys_preserved_and_optional_context_validated_on_read(self):
        self.init()
        self.update("--task", "test", "--add", "--task-title", "Legacy task")
        board = self.board()
        session = next(iter(board["sessions"].values()))
        event = session["history"][-1]
        event["data"]["historic_extra"] = {"preserve": [1, True, None]}
        (self.state / "board.json").write_text(json.dumps(board))
        self.cli("read")
        self.update("--note", "Preserve unknown historic metadata")
        self.assertEqual(next(iter(self.board()["sessions"].values()))["history"][1]["data"]["historic_extra"], {"preserve": [1, True, None]})
        for invalid in (None, [], {}, {"unexpected": "field"}, {"model": 12}, {"agent_url": "javascript:alert(1)"}, {"codex_thread_id": "unknown"}, {"next_checkpoint": "later"}):
            event["data"]["agent_context"] = invalid
            (self.state / "board.json").write_text(json.dumps(board))
            before = self.snapshot()
            self.cli("read", expected=2)
            self.cli("update", *self.identity, "--note", "Must refuse corrupted metadata", expected=2)
            self.assertEqual(self.snapshot(), before)

    def test_context_timestamps_use_the_same_second_precision_grammar_as_the_browser(self):
        self.init()
        self.update("--task", "time", "--add", "--task-title", "Reported time")
        for valid in ("2026-11-03T08:30:00Z", "2026-11-03T08:30:00.123456+02:00", "2024-02-29T23:59:59-23:59"):
            with self.subTest(valid=valid):
                self.update("--task", "time", "--last-progress", valid, "--next-checkpoint", valid)
                own = self.cli("read")["sessions"][0]
                self.assertEqual(own["history"][-1]["data"]["agent_context"], {"last_progress": valid, "next_checkpoint": valid})
        before = self.snapshot()
        for invalid in ("2026-11-03 08:30+0200", "2026-11-03T08:30Z", "2026-11-03T08:30:00+0200", "20261103T083000+0200", "2026-W45-2T08:30:00+02:00", "2026-02-29T08:30:00Z", "2026-11-03T08:30:00+01:60", "2026-11-03T08:30:00+24:00"):
            for flag in ("--last-progress", "--next-checkpoint"):
                with self.subTest(invalid=invalid, flag=flag):
                    self.cli("update", *self.identity, "--task", "time", flag, invalid, expected=2)
                    self.assertEqual(self.snapshot(), before)
                board = self.board()
                next(iter(board["sessions"].values()))["history"][-1]["data"]["agent_context"] = {flag[2:].replace("-", "_"): invalid}
                with self.assertRaises(dashboard.DashboardError):
                    dashboard.validate_board(board)

    def test_locate_does_not_create_state_and_quotes_actual_opener(self):
        self.state = self.base / "state '$ dangerous; $(touch never) état 🦊"
        located = self.cli("locate")
        self.assertFalse(self.state.exists())
        self.assertFalse(located["exists"])
        self.assertFalse(located["available"])
        self.assertEqual(located["dashboard"], str(self.state / "tasks.html"))
        self.assertEqual(shlex.split(located["opener_command"]), [sys.executable, str(HELPER.resolve()), "--state-dir", str(self.state), "open", "--again"])
        self.assertEqual(located["opener_argv"], shlex.split(located["opener_command"]))
        self.init()
        before = {path.name: path.read_bytes() for path in self.state.iterdir()}
        located = self.cli("locate")
        self.assertTrue(located["exists"])
        self.assertTrue(located["available"])
        self.assertEqual({path.name: path.read_bytes() for path in self.state.iterdir()}, before)

    def test_locate_reports_unowned_or_missing_html_without_mutation(self):
        self.state.mkdir()
        page = self.state / "tasks.html"
        page.write_text("User page")
        located = self.cli("locate")
        self.assertTrue(located["exists"])
        self.assertFalse(located["available"])
        self.assertEqual(list(self.state.iterdir()), [page])
        self.assertEqual(page.read_text(), "User page")
        self.state = self.base / "owned-state"
        self.init()
        (self.state / "tasks.html").unlink()
        located = self.cli("locate")
        self.assertFalse(located["exists"])
        self.assertFalse(located["available"])
        self.assertFalse((self.state / "tasks.html").exists())

    @unittest.skipIf(os.name == "nt", "WSL location conversion fixture")
    def test_locate_wsl_uses_encoded_windows_browser_url_without_launch(self):
        self.state = self.base / "space ' # ? % $(danger)"
        args = dashboard.parser().parse_args(["--state-dir", str(self.state), "locate"])
        translated = "\\\\wsl.localhost\\Fedora42\\home\\space ' # ? % $(danger) état 🦊\\tasks.html"
        with mock.patch.object(dashboard, "is_wsl", return_value=True), mock.patch.object(dashboard.shutil, "which", return_value="/mock/wslpath"), mock.patch.object(dashboard.subprocess, "run", return_value=subprocess.CompletedProcess([], 0, translated + "\n", "")) as convert:
            located = dashboard.run(args)
        self.assertEqual(located["url"], "file://wsl.localhost/Fedora42/home/space%20%27%20%23%20%3F%20%25%20%24%28danger%29%20%C3%A9tat%20%F0%9F%A6%8A/tasks.html")
        convert.assert_called_once_with(["wslpath", "-w", str(self.state / "tasks.html")], capture_output=True, text=True, timeout=10, check=False)
        self.assertFalse(self.state.exists())
        for result in (subprocess.CompletedProcess([], 1, "", ""), subprocess.CompletedProcess([], 0, "relative\\path", "")):
            with mock.patch.object(dashboard, "is_wsl", return_value=True), mock.patch.object(dashboard.shutil, "which", return_value="/mock/wslpath"), mock.patch.object(dashboard.subprocess, "run", return_value=result):
                located = dashboard.run(args)
                self.assertIsNone(located["url"])
                self.assertIn("url_reason", located)

    def test_platform_detection_and_native_windows_command_quoting_mocked(self):
        with mock.patch.object(dashboard.os, "name", "nt"):
            self.assertEqual(dashboard.platform_kind(), "windows")
            argv = ["C:\\Program Files\\Python\\python.exe", "C:\\é ' & $(danger)\\dashboard.py", "open"]
            command, shell = dashboard.opener_command(argv)
            self.assertEqual(shell, "powershell")
            self.assertEqual(command, "& 'C:\\Program Files\\Python\\python.exe' 'C:\\é '' & $(danger)\\dashboard.py' 'open'")
        with mock.patch.object(dashboard.os, "name", "posix"), mock.patch.object(dashboard.sys, "platform", "darwin"):
            self.assertEqual(dashboard.platform_kind(), "macos")
        with mock.patch.object(dashboard.os, "name", "posix"), mock.patch.object(dashboard.sys, "platform", "linux"), mock.patch.object(dashboard, "is_wsl", return_value=False):
            self.assertEqual(dashboard.platform_kind(), "linux")
        with mock.patch.object(dashboard.os, "name", "posix"), mock.patch.object(dashboard.sys, "platform", "linux"), mock.patch.object(dashboard, "is_wsl", return_value=True):
            self.assertEqual(dashboard.platform_kind(), "wsl")

    def test_missing_browser_launchers_leave_literal_manual_path(self):
        path = self.base / "no launcher état ' $(danger).html"
        with mock.patch.object(dashboard, "is_wsl", return_value=False), mock.patch.object(dashboard.shutil, "which", return_value=None), mock.patch.object(dashboard.subprocess, "run") as launch:
            with self.assertRaises(dashboard.DashboardError) as failure:
                dashboard.launch_browser(path)
            launch.assert_not_called()
            self.assertIn("Open this file manually: " + str(path), str(failure.exception))

    def test_explicit_open_creates_empty_owned_board_and_retains_failed_launch(self):
        args = dashboard.parser().parse_args(["--state-dir", str(self.state), "open"])
        with mock.patch.object(dashboard, "launch_browser", side_effect=dashboard.DashboardError("No display")):
            self.assertRaises(dashboard.DashboardError, dashboard.run, args)
        self.assertEqual(self.board()["sessions"], {})
        self.assertIsNone(self.board()["opened"])
        dashboard.validate_board(self.board())
        with mock.patch.object(dashboard, "launch_browser", return_value="mock-launcher") as launch:
            self.assertTrue(dashboard.run(args)["opened"])
            self.assertFalse(dashboard.run(args)["opened"])
            launch.assert_called_once()
        self.assertEqual(self.board()["sessions"], {})

    def test_empty_open_refuses_unowned_nonempty_directory_without_launch(self):
        self.state.mkdir()
        page = self.state / "tasks.html"
        page.write_text("My existing page")
        args = dashboard.parser().parse_args(["--state-dir", str(self.state), "open"])
        with mock.patch.object(dashboard, "launch_browser") as launch:
            self.assertRaises(dashboard.DashboardError, dashboard.run, args)
            launch.assert_not_called()
        self.assertEqual(list(self.state.iterdir()), [page])
        self.assertEqual(page.read_text(), "My existing page")

    @unittest.skipUnless(hasattr(os, "symlink"), "Requires symlink support")
    def test_locate_and_empty_open_refuse_symlink_state_without_mutation(self):
        target = self.base / "owned-by-someone-else"
        target.mkdir()
        self.state.symlink_to(target, target_is_directory=True)
        located = self.cli("locate")
        self.assertFalse(located["available"])
        args = dashboard.parser().parse_args(["--state-dir", str(self.state), "open"])
        with mock.patch.object(dashboard, "launch_browser") as launch:
            self.assertRaises(dashboard.DashboardError, dashboard.run, args)
            launch.assert_not_called()
        self.assertEqual(list(target.iterdir()), [])

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
        # Include the actual template size so design growth cannot make even an
        # empty recovery fail. The repeated Unicode title exceeds the remaining
        # HTML budget after JSON ASCII escaping; the UTF-8 registry still fits.
        template_bytes = (HELPER.parent.parent / "assets" / "dashboard.html").stat().st_size
        html_budget = template_bytes + 8 * 1024
        for existing in (False, True):
            self.state = self.base / f"unicode-state-{existing}"
            with self.subTest(existing=existing), mock.patch.object(dashboard, "MAX_FILE_BYTES", html_budget):
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

    @unittest.skipUnless(shutil.which("node"), "Browser-derived metrics require an available JavaScript runtime")
    def test_browser_task_counts_and_staleness_follow_task_clock(self):
        # Execute the actual browser helpers, without duplicating their logic in Python.
        template = HELPER.parent.parent / "assets" / "dashboard.html"
        source = template.read_text()
        helpers = source[source.index("function elapsedSeconds("):source.index("function node(")]
        current = dt.datetime(2026, 11, 3, 12, tzinfo=dt.timezone.utc)
        recent = (current - dt.timedelta(seconds=1)).isoformat()
        old = (current - dt.timedelta(minutes=11)).isoformat()
        statuses = ["done", "running", "testing", "review", "blocked", "failed", "queued", "cancelled"]
        session = {"status": "active", "updated": recent,
                   "tasks": {status: {"status": status, "updated": old} for status in statuses}}
        script = "const staleSeconds=" + str(dashboard.STALE_SECONDS) + ";\n" + helpers + r"""
const data=JSON.parse(require('node:fs').readFileSync(0,'utf8'));
const current=Date.parse(data.current),session=data.session;
const initial=snapshotMetrics([session],current);
const later=snapshotMetrics([session],current+600000);
const completed=snapshotMetrics([{...session,status:'completed'}],current+600000);
const empty=snapshotMetrics([],current);
const cancelled=snapshotMetrics([{...session,tasks:{cancelled:session.tasks.cancelled}}],current);
console.log(JSON.stringify({initial,later,completed,empty,cancelled,
    before:isStale(new Date(current-599000).toISOString(),true,current),
    boundary:isStale(new Date(current-600000).toISOString(),true,current),
    future:elapsedSeconds(new Date(current+60000).toISOString(),current)}));
"""
        result = subprocess.run([shutil.which("node"), "-e", script],
                                input=json.dumps({"session": session, "current": current.isoformat()}),
                                text=True, capture_output=True, timeout=10)
        self.assertEqual(result.returncode, 0, result.stderr)
        metrics = json.loads(result.stdout)
        self.assertEqual(metrics["initial"], {"done": 1, "total": 7, "active": 3,
                         "blockedFailed": 2, "queued": 1, "remaining": 6, "cancelled": 1,
                         "staleTasks": 3, "staleSessions": 0})
        self.assertEqual(metrics["later"]["staleSessions"], 1)
        self.assertEqual(metrics["completed"]["staleSessions"], 0)
        self.assertEqual(metrics["completed"]["staleTasks"], 3)
        self.assertEqual(metrics["empty"]["total"], 0)
        self.assertEqual(metrics["empty"]["remaining"], 0)
        self.assertEqual(metrics["cancelled"]["total"], 0)
        self.assertEqual(metrics["cancelled"]["remaining"], 0)
        self.assertEqual(metrics["cancelled"]["staleTasks"], 0)
        self.assertFalse(metrics["before"])
        self.assertTrue(metrics["boundary"])
        self.assertEqual(metrics["future"], 0)

    @unittest.skipUnless(shutil.which("node"), "Browser live-region regression requires an available JavaScript runtime")
    def test_browser_age_tick_only_announces_changed_live_region_text(self):
        source = (HELPER.parent.parent / "assets" / "dashboard.html").read_text()
        helpers = source[source.index("function elapsedSeconds("):source.index("function node(")]
        updater = source[source.index("function updateAges("):source.index("const refresh=")]
        script = "const staleSeconds=" + str(dashboard.STALE_SECONDS) + ";\n" + helpers + updater + r"""
function trackedElement(){let text='';return {writes:0,hidden:false,className:'',
    get textContent(){return text},set textContent(value){text=value;this.writes++}}}
const elements={summary:trackedElement(),attention:trackedElement(),'board-age':trackedElement()};
const document={getElementById:id=>elements[id]};
const start=Date.parse('2026-11-03T12:00:00Z'),stamp=new Date(start).toISOString();
let clock=start;Date.now=()=>clock;
const board={updated:stamp,revision:1};
const selectedSessions=[{status:'active',updated:stamp,tasks:{build:{status:'running',updated:stamp}}}];
const age=trackedElement(),ages=[{el:age,value:stamp,active:true,kind:'Task'}];
function snapshot(){return {summaryWrites:elements.summary.writes,attentionWrites:elements.attention.writes,
    hidden:elements.attention.hidden,attention:elements.attention.textContent,age:age.textContent}}
updateAges();const initial=snapshot();
clock+=1000;updateAges();const unchanged=snapshot();
clock=start+staleSeconds*1000;updateAges();const threshold=snapshot();
clock+=1000;updateAges();const staleUnchanged=snapshot();
console.log(JSON.stringify({initial,unchanged,threshold,staleUnchanged}));
"""
        result = subprocess.run([shutil.which("node"), "-e", script],
                                text=True, capture_output=True, timeout=10)
        self.assertEqual(result.returncode, 0, result.stderr)
        ticks = json.loads(result.stdout)
        for tick in ticks.values():
            self.assertEqual(tick["summaryWrites"], 1)
        self.assertEqual(ticks["initial"]["attentionWrites"], 1)
        self.assertEqual(ticks["unchanged"]["attentionWrites"], 1)
        self.assertEqual(ticks["threshold"]["attentionWrites"], 2)
        self.assertEqual(ticks["staleUnchanged"]["attentionWrites"], 2)
        self.assertTrue(ticks["unchanged"]["hidden"])
        self.assertFalse(ticks["threshold"]["hidden"])
        self.assertIn("1 stale active task", ticks["threshold"]["attention"])
        self.assertIn("1 stale active session", ticks["threshold"]["attention"])
        self.assertIn("10 minutes", ticks["threshold"]["age"])
        self.assertIn("stale", ticks["threshold"]["age"])

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
        html = (self.state / "tasks.html").read_text()
        self.assertIn("<!-- codex-build-task-dashboard-v1 -->", html)
        embedded = re.search(r'id="board-data">(.*?)</script>', html, re.S)
        self.assertIsNotNone(embedded)
        assert embedded is not None
        self.assertEqual(json.loads(embedded[1]), json.loads(before))
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
