# Execution efficiency and visibility

## What changed

Bound unsuccessful attempts and missed progress checkpoints. Keep ordinary
planning with a capable coordinator, start with at most two implementation workers,
and distinguish cloud-agent count from host admission. Require scoped tests and
focused re-review; confirmed security defects and material unresolved acceptance
uncertainty still block. Unrelated findings no longer silently expand the task.

The dashboard shows per-task age, stale active tasks and remaining counts separately
from session updates. It remains a reported-state board without an autonomous
watchdog. Record storage destinations before creating output; another mount such
as `/mnt/d` is not a silent fallback. Every large artifact requires a specific
removed, retained or blocked disposition; deletion safeguards are unchanged.

## Verification evidence

Implementation candidate `f1eca0f38b8aa05861ee6cf3779246bcc56ff6c5` passed
`./scripts/verify.sh`, exit 0:

```text
All 244 rulebook verification checks passed.
All 217 local-layer staleness assertions passed.
All 789 installer lifecycle assertions passed.
Ran 25 tests in 6.173s
OK
All Codex Playbook verification checks passed.
```

Raw receipts: `~/.local/state/codex-playbook/20261103-efficiency/`.
`verify-initial.log` preserves the router-size and two stale-assertion failures;
`rulebook-corrected.log` preserves a remaining 43-byte router overrun;
`verify-final.log` records the aggregate pass. Final router: 12,269 bytes under
the 12,288-byte budget. Later focused repair evidence is in the handoff.

The implementation worker directly exercised the rendered dashboard: independent
stale tasks under a fresh session, correct counts/filtering, advancing clock,
warning clearing and 390px layout without overflow/errors. Public rule-map browser
checks confirmed 0.1.22, exact searches for 7.2/8.1, visible keyboard focus and Enter
activation, zero console/page errors and no overflow at 1440/390px. These are
worker-reported runtime results, not a second coordinator browser execution.

[Mechanical review](../reviews/2026-11-03-efficiency-mechanical.md) accepted the
source and directly inspected the receipt. [Deep review](../reviews/2026-11-03-efficiency-deep.md)
found repeated unchanged live-region writes and required a focused repair; original
finding and successor acceptance remain separate records.

## Assumptions and decisions

One task/checkpoint, no phase release. Solo-maintainer main workflow follows this
repository's convention. No dependency installation, daemon, saved model-default
change, cross-project cleanup or installed-rule replacement. Main/docs source
publication can update the existing GitHub Pages destination; source push and
public deployment evidence remain separate.

Model ledger: Astra xhigh design consultation; Sol high dashboard implementation
and browser checks; independent Sol high mechanical review and Sol xhigh deep
review. This is not cross-family corroboration. Token usage and comparative model
performance are unavailable. The [operations guide](../guides/efficient-codex-operations.md)
recommends a measured Sol-medium coordinator trial, not proven superiority.

## Installation proposal and concerns

Before changes, installed 0.1.21 global rules and all 26 managed skill files matched
source. Local Overrides still match that installation but are stale against this
candidate. Reconcile them before replacement, preserving their meaning:

1. Local review Override at line 35: refresh its section digest, keeping Task Orc's
   accepted-prerequisite restriction and quoted phrase unchanged.
2. Local subagent Override at line 47: its quoted `start on the Top tier` is gone.
   Express the existing restriction as an Add: Top is planning/review-only; hard
   implementation starts Strong and implementation escalation ends at Strong.
   Preserve the owner's dated model/effort bindings.
3. Local L1 dashboard instruction: point to `~/.agents/skills` instead of its older
   `~/.codex/skills` copy. No deletion of that older copy is proposed.

Do not disable the verifier or silently edit the local layer. After explicit
replacement authorization and reconciliation, run the backup-first installer for
`~/.codex/AGENTS.md` and the 20 exact managed directories named in
`config/managed-skills.txt` beneath `~/.agents/skills/`. Verify the recovery
checkpoint, installed bytes and local compatibility. Source publication does not
update existing sessions. The live browser preview was rendered from this checkout;
an older producer can render its older template until its installation is updated.

## Hygiene and close-out

No worktree, build cache, dependency environment or background service was created
by this run. Five pre-existing Hexe worktrees were listed, not declared dead or
removed. No cross-project bytes reclaimed. Private failure/success logs occupied
200 KiB allocated by `du -sk` after the final review repair; retained by this task
as evidence, next review at installation. Tests used existing isolated fixture
teardown. Source/docs are intentional retained deliverables. The working filesystem
had approximately 18 GiB available.

The previous installation receipt records only 2.96 GiB reclaimed; it does not prove
historical cleanup of hundreds of GiB. This revision makes no measured speed or
overall-cleanup claim. Final commit/tag/push and repair acceptance are recorded
in the current handoff.

Repair `52f7cd0` passed26 dashboard tests in5.925s (coordinator receipt); focused
deep re-review passed. Earlier policy/checker/installer evidence is reused only
for unchanged rules, scripts, package inventory and schema; the dashboard behavior
was rerun on the repaired bytes. No full-suite execution on the repair is claimed.
