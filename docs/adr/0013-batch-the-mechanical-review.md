# 0013 — Batch the mechanical review; deep review per task only on the attack surface

- **Status:** accepted, 2026-10-09 (ports Claude Code Playbook 0.1.27, source ADR 0021; the owner: "we must update the intervals between code reviews, its making dev very slow … we should batch more code at the same time"; "I approve, please do these changes to claude and codex playbooks").
- **Scope:** `codex-playbook-reviews` rules 3.1, 3.2 and worked case 10 (and its fixture); `codex-playbook-dev-modes` rule 14.2's table; README, site and the pipeline guide.

## Context

Development already ran ahead of review, yet sessions were slow. A mechanical review ran after
every task, paying a brief, a detached build, the coordinator's validation and a commit of the
record each time, although the rule itself says mechanical findings are local and cost the same to
fix later. "Risk overrides cadence" sent every concurrency, data-safety and public-API task to its
own deep review, which on stateful code is nearly every task. The batch-size limit was a few
hundred lines, a human-review figure never measured for models.

## Decision

1. Each task is gated by its automated checks: tests, lint, type checks (rule 2.2).
2. The mechanical review runs per batch, side by side with the deep review on the same pinned range.
3. A batch is 5–15 tasks or about 2,000 changed lines, a starting value the close-out numbers move.
4. Deep review per task only for the security floor and unsafe code; concurrency, public-API and
   data-path tasks go early in the batch and are named in its brief.
5. Dev modes follow; sensitive keeps 3–6 tasks or about 1,000 lines.
6. Unchanged: stop-the-line, the three-batch ceiling, milestone and release gates, the floor.

## Alternatives rejected

- Drop mechanical review for automated checks alone: tests miss input handling, ignored return
  values and conformance to the brief.
- Non-blocking milestone reviews in production: a milestone review may revise the plan. Held back
  until the batching is measured.
- Raise the ceiling: bigger batches recover the time with less unreviewed work in flight.

## Consequences

- Up to 15 tasks of local defects wait for one mechanical review; if batch reviews find defects
  later tasks built on, the batch size comes down.
- A concurrency defect can be built on for part of a batch; early placement bounds that, and a
  blocker still stops the line.
