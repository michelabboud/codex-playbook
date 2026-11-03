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
timestamps. The `open` command records successful launches so later calls avoid
reopening the shared view across sessions. This is best effort: a crash after
browser launch but before recording success can cause a later `open` to launch
again. `open --again` deliberately reopens a window the user closed. Failed launches
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

## Task-level visibility (0.1.22)

The view includes per-task age and stale running/testing/review tasks, even when
another task has refreshed the session. Counts distinguish done, active, queued,
blocked/failed and remaining tasks; cancelled tasks are reported separately and
excluded from the denominator. Counts are not an estimate of time remaining.
The stale summary uses the browser clock, never claims an agent is dead, and
directs the owner to inspect native status and last output. No external watchdog
is installed. See [efficient operations](efficient-codex-operations.md).

## Project console and agent details (0.1.23)

Invoke `$codex-playbook-open-dashboard` from Codex. The skill resolves the packaged
helper and opens the existing board; if none exists, an explicit open creates an
empty owned board. A startup announcement supplies the actual browser-friendly
URL and command without launching a window. `locate` is read-only, including on
an uninitialized machine. On WSL, the helper translates the actual distribution
path rather than hardcoding one user's URL.

Project tabs order active work first. Within a project, running/testing/review
work comes first, with blocked/failed and queued work also visible. Completed
history remains available in bounded navigation. Select a task to inspect its
full description, ownership, recorded activity, acceptance, evidence and history.
Theme choices are light, dark and system; navigation persists across refresh.

Publish agent context with task updates, for example:

```sh
python3 "$DASHBOARD_HELPER" update --project "$PROJECT" --run "$RUN" --session "$SESSION" \
  --task implement --status running --owner "Implementation worker" \
  --description "Build and validate the requested behavior" \
  --model "actual-model-id" --effort "high" \
  --codex-thread-id "00000000-0000-4000-8000-000000000001" \
  --last-progress "2026-11-03T08:00:00+00:00" \
  --next-checkpoint "2026-11-03T08:10:00+00:00"
```

Replace example values with observed values. Other optional flags are `--agent-id`,
`--agent-url`, `--worktree`, `--command`, `--blocker` and `--decision`. Never publish
secrets, raw environment values or token-bearing URLs/commands. Only provide an
agent URL after confirming that it targets the intended agent in your client.

Context is a complete snapshot attached to that task-history event. Include it
again when posting subsequent updates; fields are not implicitly carried forward.
The inspector uses only the newest task event when all current task fields match.
Ordinary older-publisher updates preserve historical metadata but make the current
association unavailable. Same task IDs in different sessions remain independent.

The agent panel separates a worker from its coordinator. An explicit HTTPS URL
can open the agent where supported; a verified UUID can be copied as a resume
command, while a generic agent ID can only be copied. Missing information is
reported as unavailable. This is reported task activity, not a streamed agent
transcript, and nothing in the browser executes shell commands or kills agents.

## Platform behavior

| Environment | Browser launch | Location and opening command |
|---|---|---|
| WSL | Windows default browser through `wslpath` and PowerShell | Windows-accessible file URI for the detected distribution; POSIX command in WSL |
| macOS | `open` | Native file URI and shell-quoted Python command |
| Native Windows | Default file handler | Native file URI and a PowerShell command with quoted executable/arguments |
| Linux desktop | `xdg-open`, then `gio` | Native file URI and shell-quoted Python command |

`locate` reports the detected platform, command shell and argument list. Use the
reported shell rather than copying POSIX syntax into PowerShell. Paths containing
spaces, Unicode and apostrophes are data, never shell code. A missing launcher or
WSL conversion is reported; the helper does not invent a working URL or claim a
window opened. Python 3 is required; Windows may expose it as `py -3` or `python`.
Native Windows/macOS execution requires those hosts; mocked platform tests do not
establish native-machine acceptance.


## Now across projects and current plans

The default Now tab brings together reported active tasks across every project.
Project tabs keep focused views available. Stale reports and blockers stay visible;
completed work remains inspectable without filling the active-work section. Task
identities include project, run and session, so repeated names never merge work.

Small charts show current task-status counts and task-update events recorded in
six ten-minute bins over the last hour. A quiet chart means no recorded events,
not proof of an idle/dead agent. These charts do not measure productivity, elapsed
time remaining or token usage. Text counts accompany the visuals.

Every project coordinator explicitly declares its current plan using
`update --plan-json /absolute/path/to/plan.json` and its project/run/session flags.
The exact JSON contract and example are in the
[publisher skill](../../.agents/skills/codex-playbook-build-dashboard/SKILL.md#progress-discipline).
Declare the actual authorized objective, current phase, steps, current step and
next action, with a source such as PLAN.md or the current user request. The helper
reads only the explicitly supplied JSON file; it never discovers a project's plan.

The Current plan view shows declaration age separately from session activity.
Publish a complete replacement when the plan changes. Ordinary updates retain it;
`--clear-plan` explicitly withdraws it while preserving history. Mark finished
plans completed. Missing plans say Not declared; the UI never reconstructs them
from task names. Multiple sessions can declare plans for one project and remain
visibly separate, rather than silently assigning one coordinator authority over
another. Plan completion counts describe steps, not a predicted finish time.
