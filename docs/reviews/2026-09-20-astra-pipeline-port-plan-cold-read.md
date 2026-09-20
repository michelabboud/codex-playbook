# Astra cold read — non-blocking review pipeline port

Recorded 2026-09-20, before opening any object from `claude-code-playbook`.

Review target: `codex-playbook` commit `a654bde2637fd64dfacee551351c447b6a549338`.
This is advisory, not implementation approval. The lane was dispatched as
`gpt-6-astra`; provider runtime identity is not independently measured.

## Inputs actually read

All repository content below came from `git show a654bde:<path>`:

- `docs/plans/2026-09-20-non-blocking-review-pipeline-port-plan.md` (the plan).
- `AGENTS.md`.
- `.agents/skills/codex-playbook-reviews/SKILL.md`.
- `.agents/skills/codex-playbook-subagents/SKILL.md`.
- `tests/rulebook_test.sh`.
- The writing, repository, collaboration, and documentation skills.

I also listed the target tree and resolved the full commit identifier. A narrow
memory-registry search found no relevant record; no prior review was used.
I have not read the sibling source, its guide or ADR, the installer, the workflow
skill, or external Codex documentation. The supplied brief and plan already
describe the source's intended design, so this is independent of its detailed
text, not a claim of zero prior framing or statistical independence.

## Provisional verdict

**Proceed with changes.** Bounding speculative development and reviewing an
immutable candidate are sound aims. Several operational definitions need to be
settled before the port can safely govern other projects.

## First impressions, in priority order

1. **Define the review state machine, not just the ceiling.** Plan lines 29–33
   introduce two “unruled batches under a line's tip,” without defining whether an
   open batch counts, when a ruling removes debt, or whether accepting a report
   with confirmed blockers drains the count. A dispatch cap must apply before
   starting the work that crosses it, not just after committing it. A branch must
   inherit unresolved prerequisites; a merge should union their identities,
   counting shared ancestors once. Cherry-picks and squash integration need an
   explicit provenance rule because reachability alone does not describe every
   semantic dependency. Check whether the source already handles these cases.

2. **A pre-created worktree does not solve a read-only build.** D4, plan lines
   70–75, solves who runs `git worktree add`, but builds and tests still need
   writes for outputs, caches, generated sources, lockfiles, and temporary data.
   Separate source inspection from execution. The rule needs to state the actual
   allowed write roots, what happens when they are insufficient, and who owns
   cleanup. A detached worktree is not a containment boundary; the existing
   subagents skill correctly says so at lines 28–29.

3. **Blindness is about information exposure, not process topology.** Plan lines
   26–28 and 97 risk making “separate process” and “cold-read note” proxies for
   independence. A fresh-context thread can be less contaminated than a process
   handed prior findings or shared reviewer artifacts. A cold-read note proves
   neither inaccessible findings nor independent failure modes. Specify the
   neutral brief, context inheritance, available files, artifact embargo, and
   the order of cold read versus reconciliation. Label reduced diversity honestly.

4. **Keep capability tiers, but supply an actionable runtime binding.** D2 is
   reasonable as durable policy. It is incomplete without recording the actual
   available model and supported reasoning effort selected for each role. There
   is no evidence yet that Strong versus Top must correspond to different models
   or that changing effort guarantees a stronger reviewer. Current subagents
   lines 22–25 already treat model and effort as separate controls. A second
   family should remain conditional on actual availability and authority; T10
   currently makes one mandatory while D2 makes it optional.

5. **One roster reference is sensible; test installed access, not just copying.**
   D3 should not require a new skill. The reviews skill should explicitly require
   reading the reference before selecting a reviewer, with a path resolved from
   its own location. Merely linking does not establish that the reference is
   loaded. The proposed T1 checks test textual uniqueness, but not resolution,
   packaging, restore, or missing-reference behavior. I have not yet inspected
   `install.sh`, so I cannot affirm the claim that lifecycle contracts are
   unaffected. The two existing tables are similar, not verbatim identical.

6. **Risk override and stop semantics need to survive the new slogan.** Existing
   reviews lines 38–40 close batches at expensive-to-undo dependencies and stop
   dispatch after blocker findings. “Mechanical review never holds development”
   (plan line 30) cannot mean that a blocker discovered mechanically is ignored.
   The two-batch ceiling should be a maximum, not permission to proceed through
   a risky dependency. What happens to already-running dependent workers when a
   blocker arrives also needs a rule, beyond “no further dispatch.”

7. **Decide whether T1–T11 are tasks or steps of one task.** D6 says one commit
   per task-level change and one `checkpoint/0.1.4`; T1 deliberately leaves tests
   red, T8 performs the only version bump, and T9 finally verifies the batch
   (plan lines 80–102). This may conflict with per-task verification and closeout.
   Read the workflow skill before ruling. Calling T7 “Phase 3” while D6 declares
   no phase also deserves clarification.

8. **Do not turn historical counts into live policy accidentally.** T7's broad
   “every 49 outside history and ADR 0002” instruction needs scoped current
   carriers. The new owner test must distinguish normative definitions from
   dated plans, historical review evidence, and the visual playbook. Literal
   absence of every duplicated definition across every file is too broad.

9. **The evidence claim needs a Codex limitation.** Existing reviews line 22
   ports a nine-defect source benchmark into a generic capability-tier rule.
   It supplies no Codex model, effort, sample size, or replication evidence.
   Keep it as source rationale, not validation of the newly defined Codex tiers.
   New Strong/Top separation needs the same honesty.

## Things to establish after this record

- Read the four pinned source files and distinguish already-solved cases from
  omissions in the source itself.
- Inspect installer/restore, verify, workflow, parity matrix, contributor
  requirements, version carriers, and historical architecture decisions as git
  objects at the target commit.
- Seek official Codex evidence for skill references, sandbox/write roots,
  subagent context, model/effort selection, and completion reporting. Distinguish
  documentation, this runtime's exposed contract, observed execution, and inference.
- Prefer concrete counterexamples and proposed wording to general warnings.

This note is intentionally preserved as the pre-source record. Later conclusions
and corrections belong in `ASTRA-OPINION.md`.
