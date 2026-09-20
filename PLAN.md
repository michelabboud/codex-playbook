# Plan

## Task — Non-blocking review pipeline (parity with source 0.1.13 → 0.1.14)

**Status:** Draft, revision 2 — written 2026-09-20, awaiting the owner's go. Revision 1 was
reviewed by Astra the same day (*proceed with changes*; eleven findings, all confirmed).
One logical task, not a phase: it closes once, as 0.1.4.

**Plan:** `docs/plans/2026-09-20-non-blocking-review-pipeline-port-plan.md`
**Review:** `docs/reviews/2026-09-20-astra-pipeline-port-plan-opinion.md` · `…-cold-read.md` · `…-validation.md`

- [ ] Owner's go, including the ceiling decision (plan §0).
- [ ] Source corrected first (`claude-code-playbook` 0.1.14).
- [ ] ADR 0003 written at decision time; capabilities preflighted.
- [ ] Contract locked with failing tests (50 canonical IDs, single-owner roster, accounting cases).
- [ ] Rules 3.1, 3.3, 3.5 and the roster reference written; manifest, matrix, page, docs synchronized.
- [ ] Deep review run the way the new rule says; findings ruled.
- [ ] 0.1.4 verified, tagged `checkpoint/0.1.4`, pushed.

## Phase 2 — Faithful modular rule migration

**Status:** Complete — 2026-09-17

**Design:** `docs/plans/2026-09-17-modular-rule-parity-design.md`

**Implementation:** `docs/plans/2026-09-17-modular-rule-parity-implementation-plan.md`

- [x] Corrective architecture approved.
- [x] Rule and installer contracts locked with failing tests.
- [x] All 49 source rules migrated into the global router and topic skills.
- [x] Backup-first installation and format-compatible restoration verified.
- [x] Public docs and visual playbook corrected.
- [x] Independent reviews completed and pull request opened.
- [x] Follow-up: restored the five partnership principles to the visual
  playbook and added a regression contract — 2026-09-17.

## Phase 1 — First public release

**Status:** Complete

**Design:** `docs/plans/2026-09-16-initial-release-design.md`

**Implementation:** `docs/plans/2026-09-16-initial-release-implementation-plan.md`

- [x] Public repository created.
- [x] Global rules and architecture established.
- [x] Codex-native skills and installation guidance written.
- [x] Public documentation and source-parity report written.
- [x] Visual rule map implemented and inspected.
- [x] Repository verification completed.
- [x] v0.1.0 release package and publication evidence prepared.
