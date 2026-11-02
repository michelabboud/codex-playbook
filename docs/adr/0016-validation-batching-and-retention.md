# ADR 0016 — Batch validation and separate retained evidence

## Status

Accepted for implementation, 2026-11-02. Publication and verification are recorded
in the task close-out. Existing deletion authority is unchanged.

## Context

Genie's validation directory reached approximately 90 GiB through retained test
fixtures, repeated source copies, build output and environments. Existing hygiene
rules already required cleanup, but did not make evidence/scratch separation or
retained-byte accounting explicit. Repeating broad checks per task and again in
both review seats also wastes work. Workflow vocabulary said 3–10 tasks while the
review policy already specified 5–15.

## Decision

Keep focused affected-behavior checks per task and one broad integrated check run
per coherent batch, with one validation owner and independently reviewed receipts.
Preserve required independent execution, risk/dependency gates, exact-candidate
acceptance, and the existing 5–15-task ceiling. Separate evidence from disposable
working data at creation; avoid redundant immutable source copies while preserving
mutation and build isolation. Record advisory storage budgets and measured retention
in the existing close-out. Unique reproduction inputs, raw logs and protected data
retain their safeguards. No new service, cleaner, age expiry or approval gate.

## Alternatives rejected

- Full suites after every small change and in both review seats: duplicated expense
  without a stated uncertainty or gate to resolve.
- Delete whole old run directories or expire by age/size: loses evidence and can
  destroy locked worktrees or protected state.
- Keep every fixture indefinitely: unbounded storage without improving every claim.
- Share mutable source or compiler outputs across lanes: contaminates evidence.

## Consequences

Task receipts state their narrower scope and pending broad gates. Reviewers can use
verified execution evidence without claiming they reran it. Retention becomes visible
and classified, not automatically authorized. Historical artifacts require their own
inspection and authority. No existing Genie data or installed policy is changed by
this source task. Changed rules: 2.2, 3.1, 6.1, 6.2, 9.4, 13.1, 13.4 and 13.5; users
with local Overrides must check them against the new text before installation.
