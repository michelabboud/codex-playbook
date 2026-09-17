# 0002 — Progressive-disclosure rulebook with full source parity

## Context

Codex Playbook v0.1.0 replaced the Claude Code Playbook's modular 49-rule
agreement with a different 42-rule monolith plus three skills. The product was
usable, but it did not satisfy the intended conversion: preserve the same rules,
adapt only client mechanics, and avoid loading unrelated subject detail into
every session.

Codex always loads applicable `AGENTS.md` files. Codex skills expose compact
metadata during discovery and load their full instructions only when selected.
These mechanisms create a natural boundary between authority that must exist
before any action and procedures needed only for particular work.

## Decision

Keep partnership principles, precedence, request classification, the complete
approval table, critical rules 0.1–0.4, and a mandatory trigger router in a lean
global `AGENTS.md`. Put the remaining rule bodies and self-update procedure in
sixteen personal skills listed by `config/managed-skills.txt`.

Preserve every Claude source rule identifier. `config/rule-manifest.tsv` maps
the canonical 49 IDs to their owners. Rule 11.1 is the single declared
multi-file exception: Linux/WSL, macOS, and native Windows each require their
own implementation.

Install all platform skills for portability, but require the router and skill
descriptions to select only the execution environment's implementation. Use a
format-2 checkpoint containing the exact managed inventory, while retaining
format-1 restore compatibility for v0.1.0.

## Alternatives rejected and why

- **Keep one complete `AGENTS.md`:** reliable discovery does not justify paying
  the full subject-rule context cost in every session, and it contradicts the
  requested modular design.
- **Use nested `AGENTS.md` files:** nested files are directory-scoped, not
  topic-triggered global modules.
- **Install only one platform skill:** it saves little discovery metadata while
  complicating portable checkouts, checkpoint inventories, and restoration.
- **Keep separate dependency and release skills:** those procedures belong to
  the complete code and workflow sections; retaining both copies risks drift.
- **Distribute only as a plugin:** the product also owns one global authority
  file and needs one transactional backup/restore boundary. Direct personal
  skills remain a supported Codex discovery path and fit that installation.

## Consequences

The always-loaded global file is approximately 8 KB; the roughly 84 KB complete
corpus loads by subject. Rule changes must keep the owning skill, rule manifest,
parity matrix, visual map, and tests synchronized. The installer manages sixteen
active skills, safely retires two v0.1.0 skills, and restores both checkpoint
formats. ADR 0001 remains the historical decision for the first release but its
acceptance of doctrinal differences is superseded.

## Status

Accepted — 2026-09-17. Supersedes the rule-delivery and parity portions of ADR
0001; the separate-repository decision remains accepted.
