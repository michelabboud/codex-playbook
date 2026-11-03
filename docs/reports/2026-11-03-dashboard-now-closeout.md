# All-project activity and declared plans

## What was built

The default Now tab collects active work across projects, with fresh reports
first, blockers visible and stale reports retained. Ended sessions cannot appear
as current active work because of an old running-task snapshot. Project tabs and
the task/session/agent inspector remain available. The layout uses solid colors,
compact metrics, quieter attention messages and bounded mobile/desktop panes.

Small charts show recorded task updates in six ten-minute bins and current stored
status counts. Text equivalents and explicit scopes accompany the charts. These
are reported events/snapshots, not verified liveness, productivity or time estimates.

Each coordinator explicitly publishes a complete current-plan declaration with
objective, phase, source, current step, next action and declared steps. Latest
declaration/clear applies only to its owner session. Concurrent declarations retain
their origins, and ended-owner plans remain visibly retained rather than current.
Missing plans say Not declared. The renderer never reads a project's plan files.
The publisher skill now requires declaration and meaningful plan-state updates.

## Verification evidence

Base: `8eb4d53e7f6910f053fb1d655349d9be485f53e9`.
Frozen implementation: `078b93ab8ef3c4f0d52e0f04fd85e130593a4e46`.
Coordinator `./scripts/verify.sh` completed with exit zero on that candidate:

```text
All 246 rulebook verification checks passed.
All 217 local-layer staleness assertions passed.
All 813 installer lifecycle assertions passed.
Ran 43 tests in 14.271s
OK
Ran 10 tests in 0.282s
OK
All Codex Playbook verification checks passed.
```

The raw aggregate receipt includes command, commit, start/end timestamps and exit
status. Location: `~/.local/state/codex-playbook/20261103-dashboard-now/`.
The backend's five focused tests passed and its actual 0.1.23 compatibility probe
verified declarations, clears, ordinary updates and other-session preservation.
Those early receipts are retained in the preceding `20261103-dashboard/` directory
as `backend-plans-before.txt`, `backend-plans-after.txt` and
`backend-plans-legacy-compatibility.txt`; they are not duplicate executions.

The UI worker verified real file URLs at 1440x1000 and 390x844, no document
overflow and zero console errors/warnings. Checks cover Now ordering, ended-session
exclusion, project identities, exact chart counts, plan replacement/clear/concurrent
origins, inert source text, missing/taskless/empty states, keyboard navigation,
light/dark/system themes and pane/filter/project persistence. Seven screenshots
and the hash-bearing browser receipt are retained. Coordinator inspected desktop
and mobile screenshots; this is not a second independent browser execution.

A test fixture initially used arbitrary session keys; validation caught it, and
the generator was corrected to canonical keys before runtime acceptance. A small
frontend/backend full-string ID mismatch was corrected before the frozen candidate.
No product acceptance is based on those earlier failing checks.

Independent source reviews: [mechanical](../reviews/2026-11-03-dashboard-now-mechanical.md)
and [deep](../reviews/2026-11-03-dashboard-now-deep.md). The mechanical reviewer
accepted source conformance before the aggregate finished; the coordinator later
verified the complete exit-zero receipt. The deep reviewer accepted both pinned
source and the final shared receipts, independently matching their source hashes.
Neither reviewer found a blocking or minor defect. Their evidence scopes remain distinct.

## Assumptions and decisions

One task/checkpoint, no phase release. ADR0019 is the design contract. Exact v1
session/task schemas are preserved: plan metadata is in ordinary session history.
No dependencies, service, transcript access, automatic project discovery or new
native-launch behavior. Existing macOS/Windows qualification limits remain.

Model ledger: Sol high UI/backend implementation; independent Sol high mechanical
and Sol xhigh deep review. Fresh-context review children share the filesystem;
no separate-process dual-blind or cross-family claim. Tokens/queue-time metrics
are unavailable. One batch was carried; no admission with two outstanding batches
and no three-unruled event occurred. Tests ran once at the integrated boundary;
reviewers did not repeat the broad suite.

## Concerns and observations

Installed global rules remain 0.1.21 pending the previously proposed protected
replacement and local reconciliation. The source-rendered shared dashboard can
be overwritten with an older template by an old installed producer. This change
does not silently replace managed skills or personal rules. Updated publishers
must load the declaration instructions before existing sessions adopt them.

Pre-existing Optional[str] typing warnings in two Node test subprocess helpers
were observed by LSP and recorded in BACKLOG.md; no new plan-related type warning
or runtime failure was found. No unrelated fix lane was opened.

## Hygiene and close-out

No worktrees, dependency environments, build caches or background services created
for this dashboard task. Receipt/screenshots occupy approximately 1.2 MiB and are
retained by this task for review at installation; temporary tests used their
existing fixture teardown. Backend receipts add a few KiB in the preceding task
directory. No cross-project cleanup or reclaimed-byte claim. The current handoff
records final review disposition, checkpoint publication and live rendering.
