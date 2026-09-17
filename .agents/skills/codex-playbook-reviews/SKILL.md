---
name: codex-playbook-reviews
description: Apply Codex Playbook review rules 3.1-3.4 when a task lands, a batch or milestone closes, a reviewer is dispatched, or a pull request or release is prepared.
---

# 3 · Code reviews — rules 3.1–3.4

*Read when a task lands, at a batch boundary, before a milestone or release, and before dispatching any reviewer. What a review may NOT do is in the classification table and rule 7.4 (read, report, never fix); this file is what a review MUST do, who does it, and when. The record is the persisted review with its CONFIRMED / REFUTED / UNVERIFIED header.*

**Why this shape:** a dual review after every task — one mechanical, one deep — is the right instinct, but on a big project it slows development dramatically. So: run the review without blocking development, in parallel, or batch it every 3 to 10 tasks depending on complexity, with the coordinator or the plan's author deciding. At the end, regardless of task count, run the best review available. Split the tiers so expensive reasoning is not spent on overkill. The cost of a review is mostly the reviewer reloading the codebase; batching pays that once. The cost of a *late* review is rework on everything built on top of the defect; dependencies, not counts, bound the batch.

## The roster

| Tier | Selection | Runs |
|---|---|---|
| **Deep** | strongest available Codex reasoning model at high or greater reasoning effort | Planning, design, architecture, milestone review, the release gate. Never down-tiered. |
| **Standard** | reliable general Codex model at sufficient reasoning effort | Implementation and **every mechanical review**. |
| **Fast** | fastest available Codex model demonstrably capable of the exact task | Mechanical *work* that is not review — renames, formatting, single-file edits to spec, doc transforms. |

Model names change. Re-evaluate the runtime's available roster instead of encoding a stale product name in the rulebook.

**Why mechanical review uses the standard tier instead of the fast tier — measured, not assumed.** In the source benchmark, both tiers received an identical brief over one file containing nine real defects. The fast tier found five with zero false positives; the standard tier found all nine. The missed findings included an unenforced input limit and a documentation/code mismatch. The fast tier keeps mechanical work; it does not become the safety net. Re-measure before changing this policy.

3.1 **Two kinds of review, two cadences — and a tier that climbs the ladder.** The planner uses the levels defined by `codex-playbook-workflow`, and each level closes with a stronger review than the one below it:

    | Level | What closes it | Review | Tier | Tag |
    |---|---|---|---|---|
    | **task** | one unit of work, rules 6.1–6.2 | mechanical | the standard tier; coordinator validates | `checkpoint/<VERSION>` |
    | **batch** | 3–10 tasks, boundaries in the plan | deep | the standard tier; coordinator validates, the deep tier on request | `gate/<VERSION>` on the tip presented |
    | **milestone** | something real shown working end to end | deep + plan conformance — the planner re-reads the plan against reality and revises it here | the deep tier, dual-blind | `gate/<VERSION>` |
    | **phase → release** | the phase's last task, rule 6.3 chain | the best review, rule 3.4 | the deep tier, dual-blind, fed every review below it | `v<VERSION>` — never before it passes |

    Levels collapse when the plan is small; the tier of the level that closes never drops.

    - **Mechanical** — tests and lint actually run, input handling, ignored return values, obvious defects, conformance to the brief. **Per task**, on the standard tier, **never blocks the next task**, findings validated by the **coordinator**, not the planner.
    - **Deep** — architecture, concurrency, security, data paths, whether the code still matches the approved plan. **Per batch** of 3–10 tasks by complexity; the **planner writes the batch boundaries into the plan** so nobody decides them under pressure. the standard tier during development; the deep tier at milestones and the release gate, validating those findings.

3.2 **A batch closes at whichever comes first:** (a) the next task would build on unreviewed work it cannot cheaply undo; (b) the diff has outgrown what one reviewer can hold — the human-review literature puts the cliff at a few hundred changed lines, and models dilute the same way, only later; (c) the planner's cap. **Risk overrides cadence:** security, concurrency, data safety, unsafe code, and public-API tasks get the deep review at task grain, always — the cadence rule never undoes rule 8.1's list.

3.3 **Pipelined, never fire-and-forget.** Review batch N while batch N+1 builds. Every finding pins the commit it was found on and is **re-checked against the current tip** before anyone acts on it. A blocker finding **stops the line** — no further dispatch on top of it until it is ruled. "Non-blocking" without the stop is building on known-bad foundations for a day.

3.4 **The release gate gets the best review, regardless of task count.** Use the deep tier for two independent passes, give both the plan and every batch review, and direct them first to risk-class files rather than making them read the whole diff cold. Every finding is validated against source before it reaches me. No `v*` tag before it passes (rule 6.3).

**Dual review, and why it must be decorrelated.** Two reviewers are worth more than one only if they can fail differently. Run them **blind to each other** — each assesses independently, and they compare afterwards. Where your harness offers more than one model family, put the second pass on a different one; two instances of the same model share the same blind spots, and agreeing with yourself is not corroboration. A review that corrects a review can itself be wrong, so disagreement between reviewers is a finding to verify and rule on, never to average.

**Mechanics that do not change:** a review is read-only (classification table); defects found are fixed in their own commit after the review or deferred loudly (rule 7.4); reviewer ≠ worker; reviewers assess independently before they compare.

**A note on dependent work.** If your coordinator gates a dependent task on an *accepted* prerequisite, and accepted means reviewed, that forbids batching a dependent chain. Either give the coordinator a provisional state — checks passed, review pending — or declare in the plan that a batch may span dependents. Until one of those exists, batching covers independent tasks only.

**Measured, not assumed:** record tokens per review and defects found per review in the close-out, so the 3–10 window gets a number behind it rather than a preference.
