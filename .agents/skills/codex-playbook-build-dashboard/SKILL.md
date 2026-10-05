---
name: codex-playbook-build-dashboard
description: Maintain a persistent local browser task board for implementation and build work, shared across Codex sessions and projects. Use when starting or resuming a build, posting task progress, failures, reviews, acceptance, or a handoff; also when explicitly requested as a dashboard. Automatically refresh the saved view while each session posts its own truthful updates.
---

# Shared build task dashboard

*Local layer: if `playbook-local.md` exists in the Codex home, its entries apply only within the non-authorizing, never-weaken boundary in (`AGENTS.md`, "The local layer").*

Use this skill for build and implementation requests. Create or resume this session's tasks, open the shared browser view once, and update it throughout the work. The skill is automatically discoverable and can also be invoked as `$codex-playbook-build-dashboard`. It supports the existing task; project authorization, reviews and release requirements continue to apply.

The helper uses Python 3.9+ and the standard library. It maintains one shared HTML view and a lock-protected registry at `${XDG_STATE_HOME:-$HOME/.local/state}/build-task-dashboard/`. All Codex sessions using that directory contribute to the same view. Each project, run and session has an independent identity and history. No server, port, package installation or background process is needed.

## Start or resume

Resolve `scripts/dashboard.py` relative to **this actual skill folder**. Installed locations can differ; do not assume the current directory or a particular user's home. In the examples, `DASHBOARD_HELPER` is that absolute script path, `PROJECT` is the canonical project directory, `RUN` is a durable task/run slug, and `SESSION` is this Codex session's ID.

Use the harness thread ID (`CODEX_THREAD_ID`) when available. Otherwise omit `--session` on the first `init`: the helper returns a new ID. Save that returned ID in the working context and handoff, and use it for every subsequent post. Independent Codex sessions use **different session IDs**, even when building the same run. A resumed thread uses its saved identity. A session ID scopes edits; it is not authentication against another process running as the same OS user. Never post to another session's identity without an explicit handoff.

```bash
python3 "$DASHBOARD_HELPER" init --project "$PROJECT" --run "$RUN" --session "$SESSION"
python3 "$DASHBOARD_HELPER" open
```

`init` resumes an existing identity without replacing tasks or refreshing its timestamps. On a first start, optionally provide `--title` and `--tasks /absolute/path/tasks.json`. Initial tasks are a JSON array, for example:

```json
[
  {"id":"implement","title":"Implement the requested behavior","owner":"Codex","status":"running","detail":"Source changes in progress"},
  {"id":"verify","title":"Verify the changed behavior","status":"queued"},
  {"id":"review","title":"Independent source review","status":"queued"},
  {"id":"close-out","title":"Documentation and source checkpoint","status":"queued"}
]
```

Use the actual agreed tasks, dependencies and owners. Add the platform, release or runtime gates required by the current task; a local-only configuration change does not acquire repository or release work. `init` with `--title`/`--tasks` refuses to replace an existing session. Resume without those flags, then post explicit changes.

`open` opens the central file once across all sessions. WSL uses `wslpath` and PowerShell with the path passed as data through a child-only `WSLENV` entry; unrelated bridge entries remain intact. Linux uses `xdg-open`/`gio`, macOS uses `open`, native Windows uses its default file handler. Launch failures report the file to open manually and do not mark it opened. If the user closed the window, `open --again` deliberately reopens it. Never repeat that flag on every session or status update.

## Post truthful transitions

Post when work starts, a meaningful task status changes, a check finishes, a failure occurs, review findings arrive, repairs start, close-out completes, or ownership is handed off. For a long-running command, record its start and result; do not fabricate intermediate progress or infer liveness from a recent browser refresh. The model posts snapshots; the browser reloads the saved HTML every ten seconds. There is no autonomous scheduler or heartbeat. Refresh can be paused in the browser.

```bash
python3 "$DASHBOARD_HELPER" update --project "$PROJECT" --run "$RUN" --session "$SESSION" \
  --task verify --status testing --detail "Focused regression is running on the current candidate."
python3 "$DASHBOARD_HELPER" update --project "$PROJECT" --run "$RUN" --session "$SESSION" \
  --task verify --status failed --detail "Regression failed; repair is now in progress." \
  --evidence "file:///absolute/path/to/evidence-summary.md"
python3 "$DASHBOARD_HELPER" update --project "$PROJECT" --run "$RUN" --session "$SESSION" \
  --task runtime --add --task-title "Native runtime acceptance" --status queued --owner "Runtime reviewer"
```

An existing task may update `--task-title`, `--status`, `--owner`, `--detail`, and append `--evidence`. Add a new task with `--add`; unknown tasks and unknown session/run edits are refused. Task statuses are `queued`, `running`, `testing`, `review`, `blocked`, `failed`, `done`, `cancelled`. Retries update the current task; its previous failed status and evidence remain in saved history. No command deletes tasks, history or sessions.

Keep acceptance explicit and separate:

```bash
python3 "$DASHBOARD_HELPER" update --project "$PROJECT" --run "$RUN" --session "$SESSION" \
  --build passed --review pending --release not_requested \
  --note "Focused checks passed; independent review remains open."
python3 "$DASHBOARD_HELPER" update --project "$PROJECT" --run "$RUN" --session "$SESSION" \
  --session-status handoff --note "Candidate and evidence paths are in the saved handoff; runtime acceptance remains open."
```

Build/review values: `pending`, `passed`, `failed`, `unavailable`, `not_required`. Publication values: `not_requested`, `pending`, `published`, `rejected`. Session values: `active`, `completed`, `handoff`, `stopped`, `failed`. A done task, passing build, source push or checkpoint does not establish release publication or native/runtime acceptance. Include the frozen candidate/commit and gate scope in task details or evidence summaries when relevant. Only set the applicable gate passed after direct evidence for that candidate. On completion or interruption, save the true remaining acceptance and session state. Include the dashboard path, project/run/session identity, verified results and next action in the existing handoff.

## Inspect and recover

```bash
python3 "$DASHBOARD_HELPER" read
python3 "$DASHBOARD_HELPER" read --project "$PROJECT" --run "$RUN" --session "$SESSION"
python3 "$DASHBOARD_HELPER" render
```

`read` returns durable records and marks active snapshots stale after ten minutes without a post. This means activity is unconfirmed, not that work stopped. The browser groups by project, filters by run/session, shows per-session timestamps, and exposes saved history. Completed and failed sessions remain visible.

The JSON registry is authoritative; `render` regenerates HTML if a command was interrupted between the two atomic replacements. Concurrent producers serialize both updates under the shared lock. Every update targets a complete project/run/session identity, so identically named tasks in different sessions cannot collide. A lock timeout or invalid state is an error, never permission to bypass the lock, clear state or silently start a replacement board.

`--state-dir /absolute/private/path` before the subcommand creates an isolated board for tests or an explicitly separate view. Sessions must use the same state directory to share a view. The helper rejects unsafe IDs, symlink components, hardlinked files, unknown schemas, and unowned/nonempty state directories. It only replaces its recognized generated files. Do not edit the registry by hand, clean old state implicitly, overwrite user files or migrate an existing board without a specific authorized task. If capacity is reached, preserve the old board and use a new explicit state directory.

Post concise human-authored summaries and evidence links. Never copy credential values, environment dumps, full command output, raw logs, signed URLs or token-bearing links into the board. The helper does not read logs, discover secrets or upload state. Use only public HTTP(S) URLs or absolute local file URLs without embedded credentials. When viewing from a Windows browser through WSL, local evidence URLs must be Windows-accessible (for example a properly encoded WSL UNC file URL); a Linux `/home/...` file URL will not resolve there. All dynamic dashboard text is rendered as text, not executable markup. Browser launch paths are passed as arguments/data, never shell code.

For behavioral validation, run `python3 scripts/test_dashboard.py` from this skill folder. Tests use isolated temporary state and mock browser launchers; they open no browser windows.
