# Plan — port the non-blocking review pipeline into Codex Playbook (→ 0.1.4)

- **Status:** DRAFT — awaiting the owner's go (rule 7.1). Advisory review requested from Astra.
- **Written:** 2026-09-20, by the planning seat (Claude Fable 5.1). Nothing in this repository
  is changed by this plan except this file and its `PLAN.md` row.
- **Source of truth:** `claude-code-playbook` commit `6926f8c`, tag `checkpoint/0.1.13` —
  `rules/REVIEWS.md` (rules 3.1, 3.3, 3.5), `rules/ROSTER.md`,
  `docs/guides/non-blocking-review-pipeline.md`, `docs/adr/0001-development-runs-ahead-of-review.md`.

## 1. The problem being solved

Mechanical reviews are slow; deep reviews are slow *and* expensive in tokens. Either way
development halts while it waits. The source rulebook solved this on 2026-09-20; this
repository still carries the old two-sentence rule 3.3 — "review batch N while batch N+1
builds" — with no mechanics, no limit, and no answer to how far development may run ahead.
This repository's identity is faithful parity with the source, so it is now one rule behind
(source: 50 rules; here: 49) and carries a weaker review rule than the one its owner works by.

## 2. What is ported (unchanged in substance)

1. **Rule 3.1 — three kinds of review, defined by what they close:** mechanical (a task) ·
   deep (a batch, or a risk-class task) · **high deep** (a milestone or a release — a gate).
2. **Rule 3.3 — the pipelining mechanics:** a review's input is a commit, never a working
   tree · the reviewer reads git objects only and builds in its own detached worktree with its
   own build-output directory · the brief defines what counts as blocking · the coordinator —
   never the reviewer — commits the review's output, that one path only · in-process
   subagents do not count as blind; a blind reviewer's cold-read note is what counts as
   independent corroboration.
3. **Rule 3.5 (new, the 50th rule) — how far development may run ahead:** mechanical review
   never holds development · deep review to a ceiling of **two unruled batches under a line's
   tip**, counted by **git ancestry** (a branch off unreviewed work inherits; a merge adds and
   waits if it would exceed) · three waits at any depth · high deep reviews are gates and the
   count drains to zero before one · the planner owns the stall · review capacity is shared.
4. The guide (reasoning, failure modes, evidence and its limits) and the decision record.

## 3. Decisions this plan proposes — each with a recommendation

**D1 · Rule 3.5 becomes canonical ID number 50.** The test suite pins "the canonical 49 IDs"
in the manifest, the rule headings, the visual dataset and the parity matrix. All four move
to 50 together, test first. *No alternative: parity with the source requires it.*

**D2 · The roster stays capability-based — no product names — and gains a Strong tier.**
This repository deliberately names no model ("Model names change. Re-evaluate the runtime's
available roster instead of encoding a stale product name"). That already solves the problem
the source solved with `ROSTER.md`, and more strictly. So: keep it. Changes:
- four tiers **Top · Strong · Standard · Fast** — the current "Deep" tier is renamed **Top**,
  because "the Deep tier" and "a deep review" would otherwise name two different things;
- **Strong** is new: deep review had been assigned to the Standard tier, the same tier as
  implementation and as the mechanical review it is supposed to out-think;
- an **optional second family**, by capability: "a model of another family at the matching
  tier, when one is genuinely reachable" — for a decorrelated dual-blind pair. No names.
- *Rejected:* a named roster (Codex models by product name, Claude as second family). It
  would reverse a recorded stance of this repository for no gain the capability wording
  does not already give. *The owner may overrule — it is his to call.*

**D3 · One owner for the roster, as a reference file bundled inside an existing skill.**
Today the roster table is duplicated verbatim in `codex-playbook-reviews` and
`codex-playbook-subagents`. Recommendation: move it to
`.agents/skills/codex-playbook-subagents/references/roster.md` (tiers, kinds of review, the
measurement, the second-family note); both skills point to it and keep a one-line summary.
The installer already copies whole skill directories (`cp -pR`), so nothing in the install,
restore or lifecycle contracts changes.
- *Rejected:* a 17th skill, `codex-playbook-roster`. "Sixteen skills" is pinned in roughly
  seventeen places — tests, installer docs, README, ARCHITECTURE, the page, and ADR 0002,
  which cannot be edited, only superseded — and the 8000-character discovery-metadata budget
  would take the hit. Too much structure for a definitions table.
- *Rejected:* leaving the table duplicated and adding a row to each copy. Two copies is how
  the source got its version-carrier drift.

**D4 · Codex adaptations, marked "Adapted" in the parity matrix.** Only where Codex differs:
"in-process subagents of one session" is reworded for Codex's own subagent/thread model;
a reviewer under a read-only sandbox cannot create its own detached worktree, so **the
coordinator creates it and hands the reviewer the path**; "the harness notifies on
completion" is worded for whatever Codex actually does. *Astra's view is sought on exactly
these — see §7.*

**D5 · ADR 0003** records the decision and every intentional parity difference (D2, D3, D4).
ADR 0002's "49 rules" stays as written — an ADR is never edited; 0003 notes the count moved.

**D6 · Solo repository: the work goes straight to `main`, one commit per task-level change,
tag `checkpoint/0.1.4`, pushed.** Both GitHub accounts in this history are the owner's. No
`v*` release: this is a task-level port, not a phase.

## 4. Tasks — test first, because this repository's contract is its tests

| # | Task | Tier | Done when |
|---|---|---|---|
| **T1** | **Lock the contract, RED.** `tests/rulebook_test.sh`: canonical IDs 49 → 50 with `3.5` after `3.4` (manifest, headings, page dataset, parity matrix). New assertions: the reviews skill holds a `3.5` heading; the roster table appears in exactly one file; no file but the roster reference carries a tier *definition*; the tier names are Top/Strong/Standard/Fast. | Standard | the suite **fails** on exactly the new assertions, output quoted |
| **T2** | **Rules text.** `codex-playbook-reviews/SKILL.md`: rules 3.1, 3.3, 3.4 wording, new 3.5, dual-review paragraph, the dependent-work note, the measured-not-assumed paragraph; front-matter description "3.1-3.5". | **Top** — it is law, not mechanics | reads faithfully against the source; D4 adaptations applied |
| **T3** | **Roster reference** (D3) + `codex-playbook-subagents/SKILL.md` pointing at it, tier names throughout, escalation ladder Fast → Standard → Strong → Top. | Top for the file, Standard for propagation | one roster; both skills point to it |
| **T4** | **Router and inventory.** `AGENTS.md` router row "3.1–3.4" → "3.1–3.5"; `config/rule-manifest.tsv` row for 3.5; discovery-metadata budget re-measured (≤ 8000). | Standard | tests for router + manifest GREEN |
| **T5** | **Parity matrix** `docs/reports/2026-09-17-rule-parity-matrix.md`, updated in place with a dated revision note (the tests pin its path): 3.1 Adapted, 3.3 Direct + Adapted (D4), 3.4 Adapted, **3.5 new — Direct**, and a source-file note that `rules/ROSTER.md` maps to the roster reference. | Standard | matrix test GREEN at 50 |
| **T6** | **Visual playbook** `docs/index.html`: dataset entries 3.1, 3.3, 3.4, new 3.5; "49" → "50" in title, meta, eyebrow. Checked at desktop and mobile widths, keyboard operation, `prefers-reduced-motion` (CONTRIBUTING requires it) — by driving a real browser, not by reading the file. | Standard | page test GREEN; browser check recorded |
| **T7** | **Docs.** `docs/guides/non-blocking-review-pipeline.md` (ported, Codex wording); ADR 0003 + index row; README (count, a short "review without stalling" section, the tailoring note); ARCHITECTURE; PROGRESS; `PLAN.md` Phase 3; CHANGELOG 0.1.4; BACKLOG — the same open items the source logged (the ceiling rests on one friendly programme; the blind-leak mechanism is untested; should risk-domain implementation start on Strong). | Standard, ADR by Top | every "49" outside history and ADR 0002 reads 50 |
| **T8** | **Version 0.1.4** in every carrier: `VERSION`, `AGENTS.md`, README, PROGRESS, the page wordmark. | Standard | `scripts/verify.sh` "public version carriers match VERSION" |
| **T9** | **Verify, GREEN.** `./tests/rulebook_test.sh` · `./tests/install_test.sh` · `./scripts/verify.sh`, decisive lines quoted. | coordinator | all three pass |
| **T10** | **Review.** One batch → one **deep** review at the batch boundary, run **the way the new rule says**: against the commit, git objects only, the brief defining blocking, a second-family reviewer as a separate process, a cold-read note first. Mechanical review per task-level commit. The Top seat validates every finding. | Strong + second family | findings ruled; blockers fixed in their own commits |
| **T11** | **Close out.** Tag `checkpoint/0.1.4`, push `main`, close-out report. | coordinator | remote `VERSION` reads 0.1.4 |

T2 and T3 are written by the Top seat because the wording of a rule *is* the design. T1 and
T4–T8 are mechanical propagation and go to a Standard lane. T1 runs first; T2/T3 can run
while T1 is reviewed; T4–T8 depend on T2/T3.

## 5. Risks

- **The metadata budget.** The reviews skill's description grows ("3.1-3.5"); the suite caps
  discovery metadata at 8000 characters. Measure in T4, before anything else lands.
- **Skill length.** Rule 3.3's mechanics and 3.5 roughly double the reviews skill. It loads
  on demand, so the cost is paid only when a reviewer is dispatched — which is when it is
  needed. If it proves too long, the mechanics move to a bundled reference file the same way
  the roster does; decide on evidence, not now.
- **Cross-skill file reference.** The reviews skill will point at a file inside the
  subagents skill's directory. If Codex resolves bundled references only relative to the
  loading skill, D3 needs a copy per skill or a different home. *Astra's view sought.*
- **Parity drift the other way.** The owner's private rules dropped Rust/unsafe from rule
  3.2's risk list on 2026-09-19; neither public edition did. Out of scope here; noted so
  nobody "fixes" it by accident.

## 6. What this plan does not do

No named roster (D2). No 17th skill (D3). No change to the installer, restore or lifecycle
contracts. No `v*` release. No change to rules outside section 3 and the roster wording in
section 8.

## 7. Questions put to Astra (advisory — the owner decides)

1. Is D2 right for a Codex-first rulebook — capability tiers with no product names — or does
   a Codex operator actually need names to act? How should **Strong** versus **Top** be
   expressed in Codex terms: a different model, or the same model at a different reasoning
   effort?
2. D3: will Codex load a reference file bundled in *another* skill's directory when a skill
   points to it by path? If not, where should a single-owner roster live?
3. D4: which of rule 3.3's mechanics do not hold as written under Codex — sandbox modes,
   subagents, worktrees, completion notification — and how should each be worded?
4. Rule 3.5: anything in the ceiling, the ancestry counting or the three waits that is wrong,
   unclear, or would be gamed in practice?
5. What did this plan miss?
