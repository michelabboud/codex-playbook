# Validation of Astra's opinion on the pipeline port plan

**Reviewed:** the plan at `a654bde`. **Reviewer:** Astra (`gpt-6-astra`, xhigh, separate
process, read-only worktree). **Raw report:** `2026-09-20-astra-pipeline-port-plan-opinion.md`
and its cold-read note, committed byte-identical at `2e02ece` before this validation was
written. **Validator:** the planning seat (Claude Fable 5.1), 2026-09-20, re-deriving each
finding against the pinned commits — C = `codex-playbook` `a654bde`, S = `claude-code-playbook`
`checkpoint/0.1.13`.

**Scoreboard: 11 findings — 11 CONFIRMED (2 with a narrowed severity), 0 REFUTED, 0 UNVERIFIED.
Five of them are defects in the source rule published on 2026-09-20, not only in this plan.**

| # | Astra's severity | Verdict | What I checked, and what it means |
|---|---|---|---|
| **F1** | blocking | **CONFIRMED — and it is in the source** | S `rules/REVIEWS.md` rule 3.5 says both "starting batch N+2 while N is still unruled is allowed" and "a third never starts". With N and N+1 closed and unruled and N+2 being built, **three** batch ranges hold unreviewed work. The owner's intent in conversation was explicit ("can it be N+2?" — yes), so the rule means *two closed unruled batches plus the one being built*; it must say so, and its exposure sentence ("the ceiling multiplied by the batch size") understates — it is up to three ranges. Astra prefers two slots *including* the active batch; that is the ceiling-of-one position the owner already overruled. His decision stands unless he reopens it on this corrected cost. |
| **F2** | blocking | **CONFIRMED — and it is in the source** | S rule 3.5: "A **merge adds** the two counts" (verified verbatim). Two lines sharing one unruled ancestor batch would count it twice. The same paragraph's own definition — "the unruled batches reachable from its tip" — is a set, and is right; the "adds" sentence contradicts it. Fix: the count after a merge is the **union** reachable from the merge commit. Also confirmed: a branch cut *inside* a batch inherits part of it though the batch tip is not its ancestor, so a batch counts when **any** of its commits is reachable; ancestry cannot see cherry-picks, squashes or copied code, which need a recorded mapping or a fresh review; and a blocker fixed on one line is not fixed on another until the fix is reachable from it. |
| **F3** | blocking | **CONFIRMED, severity narrowed to wording** | The source already says in-process subagents "do not count as blind" and that the mechanism is untested. Astra is right on two points: a separate process and a cold-read note are *controls*, not *proof* of independence; and "before it opens anything else" cannot mean before reading the code under review. The Codex port must not state a leak observed in one Claude session as a fact about Codex threads. |
| **F4** | blocking | **CONFIRMED** | Plan D4 said "the coordinator creates the worktree" and stopped. A reviewer in a read-only sandbox still cannot write build output or its cold-read note, and the coordinator may itself lack write access to git metadata. Astra's capability-based wording (his §3 table) replaces D4. |
| **F5** | blocking | **CONFIRMED — my inconsistency** | The plan called the work "Phase 3" in `PLAN.md`, "not a phase" in D6, and listed eleven "tasks" closing on one version and one tag. Under this repository's workflow skill those cannot all hold. It is **one logical task with eleven steps**. |
| **F6** | blocking | **CONFIRMED — and it is in the source** | S rule 3.5 drains "every outstanding deep review" before a high deep gate and says nothing of mechanical reviews that are missing, dead or timed out. A review that never returned is still owed. Related, also confirmed: the source's "a mechanical finding is local" overclaims — the roster's own measurement cites an *unenforced input limit* as a mechanical finding, and that can be a security defect. What stops the line is the finding's impact, not the kind of review that found it. |
| **F7** | minor | **CONFIRMED** | C `tests/install_test.sh` checks installed entry points, not nested files. The bundled roster needs install, upgrade, rollback and restore coverage, a missing-file case, and one fresh-session load from an unrelated directory. |
| **F8** | minor | **CONFIRMED** | Capability tiers do not select a runnable model and effort; an operator needs a dated binding, kept **outside** the managed packages so an upgrade cannot erase it. The nine-defect measurement was taken on two Claude models and must carry that provenance. Plan T10 made the second family mandatory while D2 made it optional — a contradiction. |
| **F9** | minor | **CONFIRMED — and it is in the source** | S rule 3.3 says the coordinator commits the report "staging that one path and nothing else". If something is *already staged*, adding one path commits the rest with it. The instruction must be: check the index, commit only that path. Also confirmed: in a rulebook repository documentation *is* the product, so "work on docs while the gate waits" can change the frozen candidate — that work belongs on a line not merged until the gate passes. |
| **F10** | minor | **CONFIRMED** | C workflow skill line 10 cites "rules 3.1–3.4" and line 57's ledger example says "the deep tier"; C `docs/index.html:174` carries "49-rule" in body text. All outside the plan's stated scope. **The same two stale spots exist in the source**: `rules/WORKFLOW.md` cites "rules 3.1–3.4" and its ledger example names models in lower case, which my capital-letter search for model names missed — so the claim "no model is named outside `ROSTER.md`" was false by one example. |
| **F11** | informational | **CONFIRMED** | Re-measured with the repository's own metric: **3,121 / 8,000** characters. The plan's metadata-budget risk was overstated and is withdrawn. |

**Astra's §6 — the missing control record — accepted.** Git supplies immutable inputs and
ancestry; it does not know which commits form a batch, which review is owed, or whether it was
ruled. Counting "by ancestry" is only computable against a small coordinator-kept ledger:
batch identity, base and target, kind, status, findings' dispositions, the line(s) a ruling
applies to. Also accepted: a reviewer outage leaves the review owed; two coordinators admitting
work from the same stale count can exceed the ceiling, so one coordinator owns admission; and
rule 8.1's host-load cap does not measure a remote model's allowance.

**One point where I hold my position:** the ceiling semantics (F1). Astra's two-slot reading is
coherent, but it re-argues a decision the owner made with the trade-off in front of him. What is
new — and what he is owed — is that I quoted the cost wrongly: worst-case exposure under his
choice is three batch ranges, not two.

**Astra's five `ESCALATE:` items stand as unverified** and are carried into the plan as
execution-time checks: cross-skill reference loading; context isolation across real launches;
which model and effort deserve Strong and Top; branch protection and push effects on this
remote; the source programme's raw records.
