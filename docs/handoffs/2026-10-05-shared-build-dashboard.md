# Shared build dashboard handoff — 2026-10-05

## Current state

The local skill and managed package are implemented. The shared Windows Chrome
window is open at `~/.local/state/build-task-dashboard/tasks.html`. Coordinator
and two scoped Codex workers posted independent entries across NHB and this
repository. Actual browser verification observed revision14→15 automatically
in10067ms, and the selected project filter persisted. Owned preview processes
were stopped; the user's browser window remains open.

A real WSL opener failure was retained and repaired with child-only WSLENV
export. A later empty-XDG fallback mismatch was repaired with a regression.
Local behavioral, source package and installation checks remain separate from
pinned-source review and checkpoint publication; final receipts follow in the
close-out report. No whole live rulebook install or upgrade was performed.

## Durable identities and next action

State directory: `~/.local/state/build-task-dashboard/`. Coordinator session
`01a0ccc4-b541-7233-847f-78ff14efa7bc`; Playbook run
`shared-dashboard-20261005`; NHB run `stable-0.53.6`. Workers use distinct
`dashboard-skill-worker-20261005` and `dashboard-package-worker-20261005` IDs.
Each producer must update only its own complete project/run/session identity.
Use the helper relative to the actual skill folder. Preserve history and
state on any validation/lock error; do not bypass the lock or hand-edit JSON.

Final helper source 1378f4f has 24 passing tests and accepted independent
mechanical/deep focused reviews. All earlier failures and seals are retained.

Source `checkpoint/0.1.13` is published at
`f70ca00b684bb5d5eecf5c509a1753cd31ebf9c4`. The final tree passed 193
rulebook checks, 217 local-layer and 789 installer assertions, and 24 dashboard
tests, exit 0. Atomic push and remote peeled-tag/main equality were directly
verified. This main-line receipt does not move the source tag. The existing
GitHub Pages site also reports this commit built without an error.

The dashboard task is complete. Next approved work is the separate NHB stable
release: frozen candidate 0316b9ac passed local checks, while hosted Linux cannot
start until GitHub billing/spending admission is restored. Source mechanical
and final release acceptance remain separate. Keep producer IDs and state.
