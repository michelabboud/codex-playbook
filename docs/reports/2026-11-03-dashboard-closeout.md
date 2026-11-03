# Project dashboard and portable opener

## What was built

A compact project console with active-first tabs and tasks, a task/agent inspector,
search and run/session/status filters, bounded scrolling and ten-event history
pages. Light, dark and system themes use solid colors. Navigation choices survive
refreshes. Global stale/blocked attention remains visible on inactive projects.

Optional agent context lives in task history without changing the v1 registry
schema. Only the newest matching task snapshot supplies current context. Explicit
worker UUIDs generate inert resume commands; publisher-supplied HTTPS links are
optional. Coordinator identity never substitutes for worker identity.

The packaged opener detects WSL, Linux, macOS and native Windows. Read-only locate
reports an actual URL and shell-specific command; explicit opening can initialize
an empty owned board. Startup instructions announce the link and skill once without
automatically launching a browser. No transcript bridge, watcher, new service,
external dependency or undocumented native protocol was introduced.

## Verification evidence

Pinned implementation: `02aa0019a04edd46795a775490774f7fa7c1fd4d`.
Base: `9b0f6e38f569daa262132ad7bfd50b9d84bf92d9`.
Coordinator aggregate execution passed 246 rulebook checks, 217 local-layer
assertions, 813 installer assertions and five new UI behavior tests. That aggregate
failed on two legacy dashboard fixture assumptions: an obsolete heading and a
32 KiB limit below the redesigned template size. Both failures remain retained.
The test-only correction preserves full registry equality and Unicode capacity
refusal/recovery assertions. The coordinator then reran all 38 dashboard tests:
exit zero, 11.625 seconds. Unchanged aggregate subsets were not repeated.

The UI worker exercised real file URLs at 1440x1000 and 390x844: themes, keyboard
tabs, persisted choices, global warnings, stale thresholds, history paging, literal
markup, empty state and distinct worker/coordinator commands. No body overflow,
console errors or warnings were reported. Clipboard success/denial used browser
stubs; native external agent routing was not executed. Coordinator inspected the
screenshots and raw receipts; this is not a second independent browser run.

WSL path conversion was exercised on this host. macOS and native Windows handler
selection and quoting use simulated platform tests; native OS qualification is
unverified. No performance or model-efficiency benchmark is claimed.

Raw receipts and screenshots: `~/.local/state/codex-playbook/20261103-dashboard/`.
Independent reviews found two UI regressions: taskless sessions lost access to
notes/gates/history, and mobile details returned to the task list on auto-refresh.
Repair `f2c1ef4fa5f6de810994abfce1f992d85e2523fb` passes seven UI tests. Both
new regressions failed before the fix; direct browser checks confirm active and
completed taskless context and exact mobile Details/session restoration after a
real automatic refresh. The coordinator also reran the two existing count/age
and quiet live-region tests on the repair: passed in 0.061 seconds. Original
findings remain separate from successor review. See the
[mechanical review](../reviews/2026-11-03-dashboard-mechanical.md) and
[deep review](../reviews/2026-11-03-dashboard-deep.md).

## Assumptions and decisions

One task and checkpoint, no phase release. Solo-maintainer main workflow follows
the repository convention. The board reports agent submissions; stale means
unconfirmed activity, never proof of a dead agent. Native navigation is conditional
on a supplied supported destination; it does not promise a live transcript window.

Model ledger: Astra xhigh architecture consultation; Sol high UI and backend
implementation; independent Sol high mechanical and Sol xhigh deep review.
Review children started without conversation history but shared the filesystem;
no separate-process dual-blind or cross-family corroboration is claimed. Runtime
token usage and exact queue/latency measurements are unavailable. Two actionable
UI defects were found, one per reviewer. One open batch was carried; neither
three-unruled nor admission-with-two events occurred. No new worktree or agent
polling loop was introduced.

## Concerns and installation boundary

Source publication does not replace installed 0.1.21 rules. The existing review
Override at local line 35 and subagent Override at line 47 fail the new-source
preflight. Preserve Task Orc accepted-prerequisite semantics while refreshing the
review anchor; express the existing Top-planning/review-only restriction as an Add
because the displaced Top-start sentence is gone. Preserve all model bindings and
other local constraints. Point local dashboard L1 to the maintained `.agents/skills`
copy; do not delete the older `.codex/skills` copy. No local layer was edited. An exact proposed patch and proposed copy are retained
in the private receipt directory; the proposed copy passes the local-layer checker.

After owner authorization and reconciliation, backup-first replacement covers
`~/.codex/AGENTS.md` and the 21 managed skill directories listed by
`config/managed-skills.txt` under `~/.agents/skills/`. The opener ships with that
installation. Existing sessions may retain old instructions. Older producers can
render an older template until updated. A source-rendered preview alone does not
prove persistent adoption of the new publisher.

The user queued a read-only LSP hook diagnosis after dashboard close-out. It is
separate from dashboard acceptance and does not authorize plugin replacement.

## Hygiene and close-out

No worktree, dependency environment, build cache or background service created by
this task. Private receipts/screenshots occupy 1,187,495 apparent bytes at close-out, retained as task evidence; owner is this task, next review at installation.
Existing temporary test fixture teardown ran. No cross-project deletion or bytes
reclaimed is claimed. Both focused reviews accepted repair `f2c1ef4`. The live board was rendered from
that source and `open --again` returned `opened: true` through `powershell.exe`.
Publication is checkpoint `0.1.23`; the handoff records the source/install boundary.
