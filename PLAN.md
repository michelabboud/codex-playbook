# Plan

## Batch — The local layer (0.1.6)

**Status:** Review passed; publication candidate — approved 2026-09-21 (the owner's word in conversation).
One batch of five tasks; tasks 2 and 3 touch `scripts/`, the risk-class files,
and take a deep review at task grain. The batch closes with a deep review on the
Strong tier from the second model family; nothing is pushed before it is ruled.

**Plan:** `docs/plans/2026-09-21-local-layer-plan.md`
**Decision:** `docs/adr/0005-the-local-layer.md`
**Review:** `docs/reviews/2026-09-21-local-layer-mechanical-review.md` ·
`…-validation.md` — mechanical, target `5c90bb6`: **FAIL**, one blocking
finding, five of five confirmed by the coordinator.

- [x] 1 · Rules text — the `AGENTS.md` local-layer paragraph, the self-update
  sentence corrected, one pointer line in all sixteen managed skills, asserted
  from the inventory — 2026-09-21.
- [x] 2 · `scripts/check-local.sh` and `tests/check_local_test.sh` — 2026-09-21.
- [x] 3 · The installer's source preflight, its refusal tests, and the local
  file's survival through install, `--replace-agents` and restore — 2026-09-21.
- [x] 4 · `templates/playbook-local.md`, `INSTALL.md`, and the
  `codex-playbook-self-update` skill — 2026-09-21.
- [x] 5 · Propagation and close-out at 0.1.6 — 2026-09-21.
- [x] 6 · The mechanical review's five findings repaired, with informational
  I1 and I2 — the parser scans code spans and fails closed, all 44 shared
  vectors run, the template ships no live entry, and finding 3's three
  guarantees are asserted — 2026-09-21. The repair was subsequently committed
  locally; its lane report is `LANE-B2-REPORT.md`.
- [x] Focused mechanical re-check of the repair, at the depth of the review
  that found the defect — final mechanical PASS at `fd2443f`, recorded in
  `docs/reviews/2026-09-23-gpt6-sol-symlink-chain-reviews.md`.
- [x] Deep review of the risk-class installer/checker repair and batch; findings
  ruled — the `fd2443f` deep FAIL was repaired, then focused deep PASS at
  `267dfb5`, recorded in `docs/reviews/2026-09-23-gpt6-sol-chain-re-review-pass.md`.
- [ ] `checkpoint/0.1.6` tagged and pushed — **only after** the Claude edition's
  `checkpoint/0.1.16` exists, as the parity matrix records. That source tag
  is now published at `97938d0`; verify this edition's exact final candidate
  and remote refs before checking off publication.

**Repair round 2 — 2026-09-21.** Sol's deep review found ten blockers. The
authority boundary, parser fail-closed cases, restoration preflight, and Claude
guide contradictions are repaired in local commits. The remaining rule-section
anchor contract is now implemented and recorded in ADR 0006; all changes remain
local pending Sol's focused re-review.

**Repair round 3 — 2026-09-23.** A pinned-source focused diagnostic on
`358ab65` returned FAIL; its four findings are recorded in
`docs/reviews/2026-09-23-local-layer-focused-diagnostic.md`. The restore loader
gap and the BOM, CRLF-heading, and overlapping-quote defects have regression
tests and local fixes. This is still the original unruled local-layer batch,
not a new model-routing batch. A focused deep re-review of the fix commit at
the required tier, the outstanding mechanical re-check, and the original
task-grain/batch reviews are still owed before publication.

**Hygiene and GPT-6 routing, 2026-09-23.** The owner requested both additions
while the local-layer batch remains held. The hygiene checkpoint preserves logs
outside Git by default and commits reports, documents, and guides; a dated
non-installed note evaluates Sol/Luna without changing the model-neutral
managed roster or the mechanical-review floor. Review remains owed.

**Repair round 4 — 2026-09-23.** The owner approved fail-closed local-symlink
and checkpoint-router compatibility checks. They are implemented locally with
red-to-green lifecycle regressions and remain held for focused re-review.

**Candidate review and repair, 2026-09-23.** Independent review of local commit
`43a5580` failed on ambiguous HOME/symlink target paths and on an interrupted
upgrade whose automatic rollback was rejected by deliberate restore's strict
router check. The installer now validates path encoding and rolls back its own
transaction from exact preserved originals; deliberate restore remains strict.
The owner's task-continuity, subagent communication, Herdr, hygiene, and GPT-6
requests join this held candidate. Full suites and independent focused
re-review are required before the Claude-first publication sequence resumes.

The first pinned repair candidate `01c6e9a` also failed independent review:
the script's own checkout path could end in a newline and resolve to a sibling
checkout. Both scripts now reject that path before source resolution; absolute,
relative, and symlink-alias regressions were red before the repair and green
after. A fresh GPT-6 Sol review is owed on the new pinned candidate.

The GPT-6 Sol deep review of `fd2443f` failed: a local-file symlink chain can
pass through a managed skill and end outside it, yet become dangling when the
skill is replaced. The mechanical re-check passed with a minor changelog
wording correction. A red-to-green chain-dependency repair for both install
and restore is implemented locally. Its pinned candidate was reviewed as
recorded below.

The fresh GPT-6 Sol focused deep re-review of `267dfb5` returned **PASS**;
the base failed the new install/restore chain tests, while the pinned repair
and full verification suite passed. Claude-first publication remains the
sequencing gate; no Codex tag or push has happened yet.

## Task — Non-blocking review pipeline (parity with source 0.1.13 → 0.1.15)

**Status:** Complete — 2026-09-20, published as `checkpoint/0.1.4` — approved 2026-09-20 (the owner's "go"; ceiling reading (a), two closed batches plus the one being built). Revision 1 was
reviewed by Astra the same day (*proceed with changes*; eleven findings, all confirmed).
The first candidate then **failed** its deep review (Sol; eight findings, all confirmed, six blocking)
and was never published; the ceiling became an admission rule and the source was corrected again to 0.1.15.
One logical task, not a phase: it closes once, as 0.1.4.

**Plan:** `docs/plans/2026-09-20-non-blocking-review-pipeline-port-plan.md`
**Review:** `docs/reviews/2026-09-20-astra-pipeline-port-plan-opinion.md` · `…-cold-read.md` · `…-validation.md` · `docs/reviews/2026-09-20-sol-0.1.4-deep-review.md` · `…-validation.md` · `docs/reviews/2026-09-20-sol-0.1.4-re-review.md` · `…-validation.md` · `docs/reviews/2026-09-20-sol-0.1.4-third-review.md` · `…-validation.md` · `docs/reviews/2026-09-20-sol-0.1.4-fourth-review.md` · `…-validation.md` · `docs/reviews/2026-09-20-sol-0.1.4-fifth-review.md` · `…-validation.md`

- [x] Owner's go, including the ceiling decision (plan §0) — 2026-09-20.
- [x] Source corrected first (`claude-code-playbook` 0.1.14, `checkpoint/0.1.14`) — 2026-09-20.
- [x] ADR 0003 written at decision time — 2026-09-20.
- [x] Contract locked with failing tests (50 canonical IDs, single-owner roster, accounting wording) — 2026-09-20.
- [x] Rules 3.1, 3.3, 3.5 and the roster reference written; manifest, matrix, page, docs synchronized — 2026-09-20.
- [x] First candidate deep-reviewed and failed; ADR 0004 written at decision time; source corrected again to 0.1.15 — 2026-09-20.
- [x] Repaired contract locked with failing tests (worked cases row by row, nested-resource inventory, installer preflight refusals) — 2026-09-20.
- [x] Repair implemented: admission rule and worked cases, the stated ownership boundary, `config/managed-resources.txt` and its preflight — 2026-09-20.
- [x] Repair re-reviewed and failed (Sol; ten findings, nine confirmed, five blocking); rule 3.5 completed in the source first; installer preflight and the worked-cases test hardened — 2026-09-20.
- [x] Second repair reviewed (Sol; six findings, all confirmed): installer and tests passed, rule 3.5 failed on two omitted states; the owner chose to restate the ceiling as one invariant; source corrected first — 2026-09-20.
- [x] Restated rule reviewed (Sol; six findings, all confirmed, four blocking, two created by the restatement); rule completed in the source first — ad-hoc batches, reviewed fixes, closed-work-only merges, a residual clause — 2026-09-20.

Publication order: the source is pushed and tagged `checkpoint/0.1.15` first; the parity matrix cites it.

- [x] Deep review run the way the new rule says; findings ruled — the sixth review of the day passed (Sol; two findings, one minor in the source, one informational here); `docs/reviews/2026-09-20-sol-0.1.4-fifth-review-validation.md` — 2026-09-20.
- [x] 0.1.4 verified, tagged `checkpoint/0.1.4`, pushed — after the source's `checkpoint/0.1.15` — 2026-09-20.

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
