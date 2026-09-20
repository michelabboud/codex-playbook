# Plan — port the non-blocking review pipeline into Codex Playbook (→ 0.1.4)

- **Status:** DRAFT, **revision 2** — awaiting the owner's go (rule 7.1). Revision 1 (`a654bde`)
  was reviewed by Astra the same day: *proceed with changes*, eleven findings, all confirmed —
  `docs/reviews/2026-09-20-astra-pipeline-port-plan-opinion.md` and `…-validation.md`. §0 below
  is what changed; the body is rewritten to match.
- **Written:** 2026-09-20, by the planning seat (Claude Fable 5.1). Nothing in this repository
  is changed by this plan except this file and its `PLAN.md` row.
- **Source of truth:** `claude-code-playbook` commit `6926f8c`, tag `checkpoint/0.1.13` —
  `rules/REVIEWS.md` (rules 3.1, 3.3, 3.5), `rules/ROSTER.md`,
  `docs/guides/non-blocking-review-pipeline.md`, `docs/adr/0001-development-runs-ahead-of-review.md`.

## 0. What revision 2 changes, and the one decision it needs

**Five of Astra's findings are defects in the source rule itself**, published 2026-09-20 in
`claude-code-playbook` 0.1.13 and in the owner's private rules — not only in this plan. So the
order of work changes: **correct the source first (0.1.14), then port the corrected text**, so
this edition's rule 3.5 is a *Direct* port and not a private fork of a known-wrong sentence.

Source corrections (Step 0):
1. **The ceiling says what it counts** (F1) — see the decision below.
2. **A merge is a set union, not a sum** (F2). The count is whatever unruled batches are
   reachable from the merge commit; a batch counts when *any* of its commits is reachable, so a
   branch cut inside a batch inherits it; cherry-picks, squashes and copied code carry no
   ancestry and need a recorded mapping or a fresh review; a blocker fixed on one line is not
   fixed on another until the fix is reachable from it.
3. **Every lower review is settled before a high deep gate — mechanical included** (F6). A
   review that is missing, dead or timed out is still owed. And what stops the line is a
   finding's impact, never the kind of review that found it: "a mechanical finding is local"
   goes, because an unenforced input limit is a mechanical finding *and* can be a security defect.
4. **"Commit only that path", not "stage only that path"** (F9): check the index first, because
   anything already staged rides along. And gate-time work happens on a line that is not merged
   into the frozen candidate — in a rulebook, documentation is the product.
5. **Independence is a set of controls, not a proof** (F3): a separate process and an early note
   reduce contamination and record its limits; they do not establish blindness. The cold-read
   note is written after the brief and the material under review, before anything else.
6. **A small review ledger** (Astra §6): git knows ancestry, not which commits form a batch,
   which review is owed, or whether it was ruled. The coordinator keeps that record — batch
   identity, base and target, kind, status, dispositions, the lines a ruling applies to — and
   one coordinator owns admission, so two cannot admit work from the same stale count.
7. Two stale spots in the source's `WORKFLOW.md`: "rules 3.1–3.4", and a ledger example that
   names models in lower case (which falsified "no model is named outside `ROSTER.md`").

**The one decision that is the owner's (F1).** Rule 3.5 allows batch N+2 to start while N is
unruled, and also says "a third never starts". With N and N+1 closed and unruled and N+2 being
built, three batch ranges hold unreviewed work — so the rule must pick:
- **(a) Two closed unruled batches, plus the one being built** — what the owner chose in
  conversation ("can it be N+2?"). It keeps a review outage from becoming a development
  outage. Its honest worst case is **three** batch ranges, not the "double" the planning seat
  quoted. *Recommended: keep it, say it plainly, and correct the exposure sentence.*
- **(b) Two slots including the batch being built** — Astra's preference: N in review and N+1
  building use both; N+2 waits. Literal, simplest to enforce, exposure two ranges — and it is
  the ceiling-of-one the owner already moved away from, because any slow review halts the line.

## 1. The problem being solved

Mechanical reviews are slow; deep reviews are slow *and* expensive in tokens. Either way
development halts while it waits. The source rulebook solved this on 2026-09-20; this
repository still carries the old two-sentence rule 3.3 — "review batch N while batch N+1
builds" — with no mechanics, no limit, and no answer to how far development may run ahead.
This repository's identity is faithful parity with the source, so it is now one rule behind
(source: 50 rules; here: 49) and carries a weaker review rule than the one its owner works by.

## 2. What is ported (from the corrected source, 0.1.14)

1. **Rule 3.1 — three kinds of review, defined by what they close:** mechanical (a task) ·
   deep (a batch, or a risk-class task) · **high deep** (a milestone or a release — a gate).
2. **Rule 3.3 — the pipelining mechanics:** a review's input is a commit, never a working
   tree · the reviewer reads git objects only and builds in its own detached worktree with its
   own build-output directory · the brief defines what counts as blocking · the coordinator —
   never the reviewer — commits the review's output, that one path only · in-process
   subagents do not count as blind; a blind reviewer's cold-read note is what counts as
   independent corroboration.
3. **Rule 3.5 (new, the 50th rule) — how far development may run ahead:** mechanical review
   never holds development · deep review to a ceiling of two unruled batches under a line's
   tip — **worded per the owner's decision in §0** — counted by **git ancestry** against a
   coordinator-kept ledger (a branch off unreviewed work inherits; a merge takes the **union**
   and waits if it would exceed) · three waits at any depth · high deep reviews are gates, and
   **every lower review, mechanical included, is settled** before one · the planner owns the stall · review capacity is shared.
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
  tier, when one is genuinely reachable" — for a decorrelated dual-blind pair. No names. When
  none is reachable the pair is two fresh same-family sessions, the limitation recorded.
- **a dated operator binding, outside the managed packages** (F8): tiers are law, but an
  operator dispatches a model and an effort. The binding records role, model identifier,
  effort, date and rationale, and lives where an installer upgrade cannot erase it; its exact
  home is settled in ADR 0003. Strong and Top are defined by responsibility — they may be two
  models, or one model at two efforts, or the same configuration when the roster is small;
  never a weaker assignment invented to fill a row.
- the nine-defect measurement keeps its provenance: it was taken on two Claude models and
  validates no Codex configuration. Standard is a conservative floor pending a Codex measurement.
- *Rejected:* a named roster (Codex models by product name, Claude as second family). It
  would reverse a recorded stance of this repository for no gain the capability wording
  does not already give. *The owner may overrule — it is his to call.*

**D3 · One owner for the roster, as a reference file bundled inside an existing skill.**
Today the roster table is duplicated verbatim in `codex-playbook-reviews` and
`codex-playbook-subagents`. Recommendation: move it to
`.agents/skills/codex-playbook-subagents/references/roster.md` (tiers, kinds of review, the
measurement, the second-family note) — unnumbered definitions only, never a numbered rule,
because the ownership tests scan entry points. The reviews skill carries an explicit
instruction, not a bare link: *read `../codex-playbook-subagents/references/roster.md`,
resolved from this skill's own directory; if it is missing, report the missing prerequisite
before assigning a reviewer.* No absolute `$HOME` path, so repository and installed copies
each resolve to their own package. Fallback if a client will not follow a sibling reference:
the reviews skill invokes the subagents skill — never a second copy of the table.
The installer already copies whole skill directories (`cp -pR`), so nothing in the install,
restore or lifecycle contracts changes.
- *Rejected:* a 17th skill, `codex-playbook-roster`. "Sixteen skills" is pinned in roughly
  seventeen places — tests, installer docs, README, ARCHITECTURE, the page, and ADR 0002,
  which cannot be edited, only superseded — and the 8000-character discovery-metadata budget
  would take the hit. Too much structure for a definitions table.
- *Rejected:* leaving the table duplicated and adding a row to each copy. Two copies is how
  the source got its version-carrier drift.

**D4 · Codex adaptations — capabilities and information flow, not Claude process terms**
(rewritten from Astra's §3, accepted whole; marked "Adapted" in the parity matrix):
- *Input:* pin the full target commit and, for a change review, the base; a moving branch name
  is not a pin. Source is inspected through git objects; tests run only from an isolated
  snapshot of the pinned target, with dedicated writable build, cache and temp locations.
- *Who prepares the snapshot:* whoever holds the permission — worktree creation needs
  filesystem **and** git-metadata write access, and the coordinator is not automatically
  outside the sandbox. A capability check, not an assumed escape hatch.
- *Review-only authority versus a read-only filesystem* are different things. If the active
  sandbox cannot write the report or the cold-read note, findings return through the response
  channel, unrun checks are marked unavailable, and required checks go to an already-authorized
  lane. **Never widen the sandbox to make the rule look satisfied.**
- *Context:* a fresh review context holding the approved brief and inputs only; record what
  isolation the runtime actually provides. Nothing about Claude sessions is asserted of Codex.
- *Completion:* register how completion is signalled; handle completion, failure, timeout and
  interruption; an exited worker is not an accepted review.
- *Stop the line:* stop new dependent dispatch and keep already-running dependent results from
  being accepted until triage — preserving their work, never killing it.

**D5 · ADR 0003** records the decision and every intentional parity difference (D2, D3, D4).
ADR 0002's "49 rules" stays as written — an ADR is never edited; 0003 notes the count moved.

**D6 · One logical task, eleven steps, one version, one tag** (F5 — revision 1 called this
"Phase 3", "not a phase" and "eleven tasks" at once). It is a single task in the workflow
skill's vocabulary: it closes once, as 0.1.4 with `checkpoint/0.1.4`, straight to `main` —
both GitHub accounts in this history are the owner's, by his word. No `v*` release. Before the
push, the remote's branch protection and any push-triggered automation are read, not assumed.

## 4. Steps of the one task — test first, because this repository's contract is its tests

| # | Step | Tier | Done when |
|---|---|---|---|
| **S0** | **Correct the source first.** `claude-code-playbook` 0.1.14 and the owner's private rules: the seven corrections in §0, with the owner's ceiling decision. Its own commit, tag and push. | **Top** | source rule 3.5 says what it counts; merge is a union; gates settle every lower review |
| **S0b** | **Decide and record before building:** ADR 0003 written at decision time, not at close-out. Preflight the capabilities the later steps need — a reviewer lane, a build lane, a real browser. | Top | ADR 0003 committed; preflight recorded |
| **T1** | **Lock the contract, RED.** `tests/rulebook_test.sh`: canonical IDs 49 → 50 with `3.5` after `3.4` (manifest, headings, page dataset, parity matrix). New assertions: the reviews skill holds a `3.5` heading; the roster table appears in exactly one **normative** file (scoped to `AGENTS.md` and the skill packages — history and evidence are exempt); the tier names are Top/Strong/Standard/Fast; **behavioural cases** for the accounting — union on merge, a branch cut inside a batch, a missing mechanical review holding a gate — not only heading matches. RED evidence is kept inside this task; a deliberately failing suite is never a checkpoint. | Standard | the suite **fails** on exactly the new assertions, output quoted |
| **T2** | **Rules text.** `codex-playbook-reviews/SKILL.md`: rules 3.1, 3.3, 3.4 wording, new 3.5, dual-review paragraph, the dependent-work note, the measured-not-assumed paragraph; front-matter description "3.1-3.5". | **Top** — it is law, not mechanics | reads faithfully against the source; D4 adaptations applied |
| **T3** | **Roster reference** (D3) + `codex-playbook-subagents/SKILL.md` pointing at it, tier names throughout, escalation ladder Fast → Standard → Strong → Top. | Top for the file, Standard for propagation | one roster; both skills point to it |
| **T4** | **Router and inventory.** `AGENTS.md` router row "3.1–3.4" → "3.1–3.5"; `config/rule-manifest.tsv` row for 3.5; the workflow skill's two stale spots (its "rules 3.1–3.4" citation and the "deep tier" ledger example); nested-resource coverage in `tests/install_test.sh` — install, upgrade, rollback, restore, a missing-file case. | Standard | tests for router + manifest GREEN |
| **T5** | **Parity matrix** `docs/reports/2026-09-17-rule-parity-matrix.md`, updated in place with a dated revision note (the tests pin its path): 3.1 Adapted, 3.3 Direct + Adapted (D4), 3.4 Adapted, **3.5 new — Direct**, rule 8.1's row, a dated provenance note saying which rows moved to source 0.1.14 and which stay at the earlier source, and a source-file note that `rules/ROSTER.md` maps to the roster reference. | Standard | matrix test GREEN at 50 |
| **T6** | **Visual playbook** `docs/index.html`: dataset entries 3.1, 3.3, 3.4, new 3.5; "49" → "50" in title, meta, eyebrow **and the body text at line 174**. Checked at desktop and mobile widths, keyboard operation, `prefers-reduced-motion` (CONTRIBUTING requires it) — by driving a real browser, not by reading the file. | Standard | page test GREEN; browser check recorded |
| **T7** | **Docs.** `docs/guides/non-blocking-review-pipeline.md` (ported, Codex wording); ADR 0003 + index row; README (count, a short "review without stalling" section, the tailoring note); ARCHITECTURE; PROGRESS; `PLAN.md` Phase 3; CHANGELOG 0.1.4; BACKLOG — the same open items the source logged (the ceiling rests on one friendly programme; the blind-leak mechanism is untested; should risk-domain implementation start on Strong). | Standard, ADR by Top | every "49" outside history and ADR 0002 reads 50 |
| **T8** | **Version 0.1.4** in every carrier: `VERSION`, `AGENTS.md`, README, PROGRESS, the page wordmark. | Standard | `scripts/verify.sh` "public version carriers match VERSION" |
| **T9** | **Verify, GREEN.** `./tests/rulebook_test.sh` · `./tests/install_test.sh` · `./scripts/verify.sh`, decisive lines quoted. | coordinator | all three pass |
| **T10** | **Review.** One batch → one **deep** review at the batch boundary, run **the way the new rule says**: against the commit, git objects only, the brief defining blocking, base and target pinned, a fresh-context reviewer, a cold-read note first, raw output committed before triage. A second-family reviewer **when one is reachable**, otherwise a recorded same-family pair. **The coordinator validates routine findings; only policy changes and unresolved disputes go to the Top seat.** Fixes are reviewed against the updated candidate. | Strong (+ second family if reachable) | findings ruled; blockers fixed in their own commits |
| **T11** | **Close out.** Tag `checkpoint/0.1.4`, push `main`, close-out report. | coordinator | remote `VERSION` reads 0.1.4 |

S0, S0b, T2 and T3 are written by the Top seat because the wording of a rule *is* the design.
T1 and T4–T8 are mechanical propagation and go to a Standard lane — but no step hands
unresolved policy to a lane as if it were text replacement. The roster's interface (T3) is
settled before anyone writes either consumer. T9 runs `scripts/verify.sh`, which already
executes both suites — no gratuitous repeat runs. One fresh-session load of the installed
roster reference, from an unrelated directory, is part of T9.

## 5. Risks

- ~~The metadata budget~~ — withdrawn (F11): measured at 3,121 of 8,000 characters, and
  "3.1-3.4" → "3.1-3.5" adds none.
- **Unverified at plan time, checked at execution** (Astra's `ESCALATE:` items): whether Codex
  follows a reference into a sibling skill's directory; what isolation real reviewer launches
  provide; which model and effort deserve Strong and Top; this remote's branch protection.
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
contracts. No `v*` release. No change to rules outside section 3, the roster wording in
section 8, and the two stale references in the workflow skill that the rename and rule 3.5 touch.

## 7. Questions put to Astra in revision 1 (answered — see the review files)

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
