# 0014 — A qualified Fast configuration may fill the mechanical review seat

- **Status:** accepted, 2026-10-10 (ports Claude Code Playbook 0.1.28, source ADR 0022; the owner: "add haiku5.5 as valid mechanical model for code-review").
- **Scope:** `codex-playbook-reviews` rule 3.1; `codex-playbook-subagents` rule 8.1; the roster reference (a new mechanical review seat section and the Haiku 5.5 measurement).

## Context

Mechanical review was held to the Standard tier as a conservative floor, carried from a Claude
measurement on an earlier Haiku. Claude Haiku 5.5 arrived on 2026-10-10; a first, not-blind
comparison against GPT-6 Luna found all ten seeded defects twice and, on one real file, the known
subtle defect twice plus more further real defects than Luna. The owner admitted it to the seat.
This edition names no model products in its tier rules: the operator's binding names them.

## Decision

1. Rules 3.1 and 8.1: mechanical review runs on the Standard tier or on a configuration the
   roster qualifies for the seat, never on an **unqualified** Fast one.
2. The roster states the qualification test: the owner's admission **and** a recorded comparison
   on that exact configuration, with its limits. Admission does not move a configuration up a tier.
3. The roster's measurement section records the Haiku 5.5 comparison and its limits. The owner's
   binding names Haiku 5.5 beside Sonnet 5.5 for the seat.

## Alternatives rejected

- **Name Haiku 5.5 in the rules.** This edition binds models outside the managed packages; the
  rules stay model-neutral.
- **Admission on the owner's word alone, with no recorded comparison.** A seat that is a safety net
  needs its evidence written where the next reader will look.

## Consequences

- An operator can admit a cheaper configuration to mechanical review without a rule change, but
  only with a recorded comparison.
- Haiku 5.5's evidence is one hard file and not blind; reviews it runs say so in their header.
