# ADR 0017 — Bounded execution and visible progress

## Status

Accepted for implementation, 2026-11-03. Supersedes unconditional top-tier planning
and CPU-derived agent counts in earlier execution guidance. Existing review and
destructive-action safeguards remain.

## Context

The owner reports multi-day stalls, repeated checks, poor task visibility, large
leftovers and worktrees silently placed on `/mnt/d`. Source review found no
explicit stalled-progress deadline, unconditional top-tier planning, and cloud
agent counts derived from local CPU count. Security classification treats missing
attack evidence as realistic indefinitely. Cleanup already permits verified idle
output, but lacks a bounded disposition for each artifact. The current dashboard
ages sessions only, so another task's update can hide an abandoned task.

## Decision

Make retry and progress obligations explicit without accepting failed gates.
Use focused checks and one integrated validation owner. Distinguish a suspected
security issue from a confirmed reachable defect; unresolved material uncertainty
still blocks the affected acceptance. Size delegation by independent deliverables
and review capacity, with separate host admission for local heavy commands.
Routine planning stays with the capable coordinator; hard design receives a
stronger planning consultation. Preserve role-specific review floors and explicit
owner model bindings. Default new worktrees to the established project layout;
another mount requires an explicit owner destination instruction.

Add task-age warnings and remaining-work counts to the existing local dashboard,
without a daemon or schema migration. Records remain producer-reported snapshots,
not process liveness. Document native inspection and a future external watchdog
as separate capabilities, not functionality the rulebook already implements.

## Alternatives rejected

- More high-effort agents by default: no evidence this fixes coordination failures.
- Remove security/review gates: hides failures rather than improving throughput.
- Repeated waits or fresh timestamps as proof of progress: conceals stuck tasks.
- Age-based worktree deletion or permissive cleanup: can destroy unique work.
- Mandatory new monitoring service: unnecessary operational cost for this change.

## Consequences

The coordinator must name the next evidence-producing step and intervene after
bounded unsuccessful attempts. Unknown/dead/stale states stay distinct. Rules
cannot guarantee notifications after the coordinator itself stops; an external
observer is needed for unattended alarms. Model recommendations are hypotheses
until measured on accepted work. Existing local Overrides can become stale and
must be reported before installed replacement; this source change does not edit
the owner's local layer or existing sessions.
