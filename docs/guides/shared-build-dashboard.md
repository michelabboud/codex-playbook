# Shared local build task dashboard

The build dashboard gives the owner one browser view of build work reported by
multiple Codex sessions. It refreshes automatically and retains failures and
evidence across later updates. Reported task state does not prove that a build,
review, checkpoint, or release passed; attach the actual command result or
evidence location when reporting a gate.

The mandatory skill router loads
[`codex-playbook-build-dashboard`](../../.agents/skills/codex-playbook-build-dashboard/SKILL.md)
for authorized build and release work. Each session records its own project,
run, and session identity. Load the skill's instructions before posting from an
existing session: installing new metadata does not change a running session's
knowledge.

Use one shared state directory across sessions on the same machine. The helper
updates only the named project/run/session entry, locks shared writes, and
preserves other sessions' work. Start with a concrete task list and update it on
meaningful transitions: starting a task, a failed check, a review decision,
completion, or handoff. A failed attempt stays visible after the next attempt
passes. A stale session indicates that its last report is old; it does not prove
that its process stopped.

The helper requires Python 3.9 or later and uses only the standard library. It
writes a shared registry and HTML view to
`${XDG_STATE_HOME:-$HOME/.local/state}/build-task-dashboard/`; no server, port,
or background process is needed. The browser reloads the saved view every ten
seconds, and refresh can be paused. Sessions post meaningful transitions; the
browser refresh itself supplies no process heartbeat.

The browser view is local. The dashboard reports work; it does not execute
builds, manage compile leases, claim ports or container ownership, approve
cleanup, or authorize access to another project. Keep credentials, private log
contents, and other secrets out of titles, details, and evidence labels. Link to
authorized evidence instead. MAI access remains subject to the existing
explicit permission boundary.

## Start, update, and inspect

Resolve `DASHBOARD_HELPER` to `scripts/dashboard.py` inside the actual installed
skill directory. Use the canonical project directory, a durable run slug, and
this session's own ID. `CODEX_THREAD_ID` supplies the session ID when available;
otherwise omit `--session` from the first `init` and save its returned ID.

```bash
python3 "$DASHBOARD_HELPER" init --project "$PROJECT" --run "$RUN" --session "$SESSION"
python3 "$DASHBOARD_HELPER" open
python3 "$DASHBOARD_HELPER" update --project "$PROJECT" --run "$RUN" --session "$SESSION" \
  --task verify --add --task-title "Verify the changed behavior" --status testing
python3 "$DASHBOARD_HELPER" read --project "$PROJECT" --run "$RUN" --session "$SESSION"
```

Use `init --tasks /absolute/path/tasks.json` to start with the agreed task list.
Resuming an existing identity with plain `init` preserves its tasks and prior
timestamps. The `open` command opens the shared view once across sessions;
`open --again` deliberately reopens a window the user closed. Failed launches
leave the board eligible to open later and report its path for manual opening.

Task updates append history and evidence. Report actual gate results with
`--build`, `--review`, and `--release`; a completed task does not implicitly set
those gates. Use `--session-status handoff` and a concise `--note` when handing
off ownership. The skill reference lists all allowed statuses and commands.

The registry is authoritative. `render` regenerates the HTML view if an
interrupted write left it behind the saved state. Invalid schemas, unsafe paths,
and lock timeouts are errors: preserve the board and investigate the reported
cause. `--state-dir /absolute/private/path` before the command selects an
explicit separate board for isolated tests. All collaborating sessions must use
the same directory to appear in the same view.

## Installation and recovery

The playbook installer places this skill under
`$HOME/.agents/skills/codex-playbook-build-dashboard`, alongside the other
managed playbook skills. It installs the helper, browser template, behavioral
tests, and invocation metadata from the exact managed resource inventory.
Install and restore retain the playbook's existing symlink refusals and local
layer protections.

An upgrade replaces the managed skill tree with the source tree. The recovery
checkpoint preserves the complete prior tree, including additional prior files
and permissions. Restoring that checkpoint reinstates that prior tree. The
dashboard's reported task state lives outside the managed skill tree, so source
installation and skill restoration do not modify dashboard state. Do not put
live state inside a managed skill directory.

## Validation

Run `./scripts/verify.sh` from the repository root. It checks numbered rule
parity, the exact active skill/resource inventory, dashboard behavior, and the
isolated installer lifecycle. Installer tests use temporary homes and Codex
directories; they never install into the user's actual configuration.
