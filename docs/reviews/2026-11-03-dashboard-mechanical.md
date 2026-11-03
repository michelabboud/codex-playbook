# Dashboard mechanical review — 2026-11-03

## Input and isolation

- Base: `9b0f6e38f569daa262132ad7bfd50b9d84bf92d9`.
- Target: `02aa0019a04edd46795a775490774f7fa7c1fd4d`.
- Scope: production local-file dashboard; packaging, input handling, tests and requested behavior. No product edits, new worktrees or broad repeated checks.
- Reviewer: native Codex child; coordinator dispatch metadata reports `gpt-6.1-sol` / `high`, `fork_turns=none`. Exact model self-identification is unavailable in the child's exposed runtime.
- Isolation: fresh task context with the approved brief and instruction environment; shared filesystem. This is an independent child review, not a separately isolated process or a dual-blind claim. No other review findings or coordinator report were read. Pinned Git objects were used for candidate source. The live instruction skills and local layer were read as reviewer instructions, not as evidence of candidate behavior.
- Excluded inputs: other files under `docs/reviews/`, coordinator reports, other reviewer findings. No dedicated isolated scratch directory was supplied; no scratch execution occurred.

## Initial cold-read note

Saved after inspecting the pinned source and before opening the approved validation receipts. No confirmed blocking defect found in this initial read. Candidate source preserves exact v1 task fields and stores optional validated context only in task-history event data. The browser binds context to the newest matching task snapshot, distinguishes worker and coordinator identities, uses text nodes for reported data and only accepts HTTPS agent navigation. Project/task ordering, status filters, inspector, retained history pagination, solid-color themes, packaged opener inventory and startup notice are present.

CONFIRMED: source implements the requested bounded project/task presentation, optional agent details and explicit navigation fallback; no inferred worker or automatic native client route is apparent.

REFUTED: the change does not add new fields to the v1 task schema, execute reported commands, create a transcript service, or claim that browser refresh proves worker liveness.

UNVERIFIED: test receipt provenance/results, actual browser behavior, native macOS/Windows execution and instruction-based startup behavior. These remain to be assessed from the approved receipts; source presence alone does not establish runtime acceptance.

## Completed mechanical findings

**Verdict: changes required for M1.** The initial cold note above remains unchanged in substance. M1 was identified during the subsequent bounded check of session-history discoverability; it is an ordinary independent finding, not claimed as initial cold-read corroboration.

### M1 — CONFIRMED — medium functional blocker: taskless session details and history become inaccessible

Target: `.agents/skills/codex-playbook-build-dashboard/assets/dashboard.html:999` and `:1052` (also `:1127` and `:1152`).

A valid session can have an empty task dictionary: ordinary `init` permits no initial tasks, and producers can post session-only notes, build/review gates and handoff state. In the target, `render()` creates task records only, chooses a selected task only from those records and passes its lookup into `renderInspector()`. When the selected session has no tasks, `renderInspector(undefined)` displays only “Select a task…” and returns before rendering the coordinator fields, acceptance gates and session history. The run/session dropdowns still list the record, but selecting it cannot reveal those details. If a project contains both populated and taskless sessions, its populated tasks cannot reveal another session's history either.

This is a reachable regression from the base, whose renderer emitted every session's header, note, gates, update time and saved history even when the task list was empty (base template lines 31–35). It violates the stated requirement to keep retained history discoverable. No bytes are lost from the registry, but the browser loses access to meaningful existing reported state.

Restore a session-inspection route independent of task selection, including for a selected taskless session. Keep worker context absent when no task is selected. Add a focused browser/UI regression with a taskless session containing a session note, distinct gates and history; verify these remain discoverable both alone and alongside a populated session. Existing empty-board coverage has zero sessions and does not exercise this state.

## Evidence assessed

Approved receipts were read only after the cold note:

- `/home/michel/.local/state/codex-playbook/20261103-dashboard/verify-integrated.txt`: `All 246 rulebook verification checks passed.`, `All 217 local-layer staleness assertions passed.`, `All 813 installer lifecycle assertions passed.` It also records an actual failed 38-test dashboard run: one obsolete-heading failure and two capacity-fixture errors. It is **not** a green aggregate receipt.
- `/home/michel/.local/state/codex-playbook/20261103-dashboard/backend-template-regressions-fixed.txt`: the two affected test methods pass. The pinned test source now checks rendered board recovery rather than the old heading and sizes the capacity fixture relative to the real template. These are meaningful fixture repairs rather than removal of the underlying safeguards.
- `/home/michel/.local/state/codex-playbook/20261103-dashboard/dashboard-final.txt`: `Ran 38 tests in 11.625s` followed by `OK`; coordinator reports exit 0 and no product changes after the pinned target. This supersedes the dashboard portion of the failed aggregate, not its preserved failure record.
- The integrated receipt separately reports all five dedicated UI helper tests passing. Those execute pure functions extracted from the real template with Node; they do not exercise the entire DOM or a real native client.
- `/home/michel/.local/state/codex-playbook/20261103-dashboard/browser-receipt.md`: fixture-based file-URL checks report desktop/mobile dimensions, project ordering, theme following, keyboard tabs, filter persistence, context absence, paginated history, escaped markup and no application errors. Pinned Git-object SHA-256 values independently match both hashes in that receipt: HTML `037d76f33193d7a2da2a743c4696e81bc4aab71a30ee1d2200fdb26e57af3a88`; UI test helper `2f43153c29740d611f00dc1bb079bd324c8e7c7d1f1085fb97131bdae67a77d7`.

No broad tests were repeated in this review, and the shared receipts are not a second independent execution. Raw backend/aggregate receipts do not themselves embed a commit/hash manifest or complete invocation header; attribution to the target relies on the coordinator's explicit candidate/no-product-change statement plus the pinned source inspection. Native Windows/macOS behavior is represented by mocked dispatch/quoting tests, with a real Windows child bridge check on the WSL host where reported; this does not establish execution of the complete helper on either native host.

## Acceptance boundaries

CONFIRMED: managed inventories include the opener skill, YAML metadata and new UI test resource; aggregate verification invokes both dashboard test suites. Context input validation, inert command display, JSON/DOM escaping, immutable historical context preservation, exact snapshot association and independent worker/coordinator identities are implemented. OS detection and literal argument handling are present for WSL, Linux, macOS and native Windows. Shared tests/browser receipts support the reported scopes above. M1 remains a confirmed functional blocker.

REFUTED: no new v1 task fields, inferred worker identity, native deep-link scheme, shell execution UI, transcript bridge or claim of worker liveness is introduced. The failed integrated receipt was not actually a passing full aggregate, and the subsequent 38-test success does not erase it.

UNVERIFIED: automatic startup compliance in a fresh installed Codex session; actual native macOS/Windows end-to-end execution; destination correctness for arbitrary publisher-supplied HTTPS agent links; native client agent routing and OS clipboard permissions. The candidate documentation already distinguishes these limits. These are not additional findings absent a contrary product claim.
