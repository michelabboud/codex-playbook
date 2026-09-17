# Modular Rule Parity Design

**Status:** Approved 2026-09-17

## Context

The first Codex Playbook release replaced the Claude Code Playbook's modular,
49-rule working agreement with a separate 42-rule agreement in one global
`AGENTS.md` plus three procedural skills. That was not the requested migration.
The intended product is the Claude Code Playbook's rules, adapted only where
Codex requires different mechanics, with detailed sections loaded on demand.

Codex always loads the applicable `AGENTS.md` chain. Personal and repository
skills use progressive disclosure: Codex sees their metadata at discovery time
and loads the full `SKILL.md` only when the task matches or the user invokes the
skill. The correct architecture therefore keeps authority and routing global
while placing subject detail in skills.

## Decision

### Always-loaded core

`AGENTS.md` contains only the material required before any action:

- the five partnership principles and production-quality motto;
- source/version self-identification and the self-update trigger;
- precedence;
- request classification;
- the complete approval table;
- critical rules 0.1–0.4; and
- a mandatory section router naming every skill, its trigger, and its rule IDs.

The router requires the relevant skill to be loaded before the triggering
action. Skills carry procedure and detail but cannot add approval gates.

### On-demand subjects

The repository carries sixteen skills:

1. code;
2. testing and verification;
3. reviews;
4. documentation and ADRs;
5. repository structure;
6. task and phase workflow;
7. planning, autonomy, and handoffs;
8. subagents and model tiering;
9. environment and operations;
10. destructive actions;
11. quarantine;
12. writing to the owner;
13. self-update;
14. Linux platform commands;
15. macOS platform commands; and
16. Windows platform commands.

All platform skills install. Their descriptions restrict activation to the
matching operating system. This keeps one portable checkout and one reversible
installer while loading only the relevant platform body.

### Source fidelity

Rules retain the Claude source identifiers `0.1` through `12.4`. Wording is
preserved unless the platform requires an adaptation. Adaptations are limited
to:

- Claude paths becoming Codex skill names and `$HOME/.agents/skills` paths;
- Claude model names becoming capability tiers with currently available Codex
  examples, without deleting the review or escalation behavior;
- Claude Code `paths:` auto-loading becoming an explicit router plus skill
  metadata; and
- the self-update source becoming `michelabboud/codex-playbook`.

A machine-readable manifest maps every rule ID to its installed owner. Rule
11.1 is the sole multi-owner exception because it has one implementation per
supported operating system. Verification fails on a missing, duplicate,
unknown, or misplaced rule outside that declared exception.

### Installation and recovery

The installer continues to create and verify a complete checkpoint before it
changes `AGENTS.md` or any managed skill. The managed skill inventory comes
from the repository manifest instead of duplicated shell lists. Installation,
rollback, and restore remain transactional across all sixteen skills.

Old format-1 checkpoints remain restorable. New checkpoints use format 2 and
record the exact managed skill inventory so future versions can restore a
checkpoint even after the repository's skill set changes.

### Public experience

The README, installation guide, architecture, source-parity report, progress,
changelog, and visual playbook describe the same 49-rule modular product. The
visual playbook reads its rule map from an explicit dataset generated from the
same rule inventory contract rather than presenting the retired 42-rule model.

## Alternatives Rejected

### Keep the 42-rule monolith and add missing prose

Rejected because it preserves the original misunderstanding and continues to
load unrelated detail into every session.

### Use nested `AGENTS.md` files for subject modules

Rejected because nested instructions are directory-scoped. They are useful for
project-local overrides, not topic-triggered global procedures.

### Install only the current operating-system skill

Rejected because cross-platform detection complicates backup and restoration,
and because installed skill metadata is small while full skill bodies remain
progressively disclosed.

## Consequences

- `AGENTS.md` becomes substantially smaller and more stable.
- The installed skill count grows from three to sixteen.
- Installer tests cover a larger transactional set and checkpoint format
  compatibility.
- Rule changes must update the rule manifest, the owning skill, public docs,
  and the visual map in one change.
- The previous architecture ADR remains historical and is superseded by a new
  ADR rather than rewritten.
