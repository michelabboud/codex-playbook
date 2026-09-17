# Codex Playbook Initial Release Design

> **Historical v0.1.0 plan — superseded by the approved modular parity design
> dated 2026-09-17.** This file records what the first release intentionally
> built; it is not the current architecture.

## Goal

Create a polished public Codex edition of the existing Claude Code rulebook,
preserving Michel's language and working philosophy while adapting the package
to Codex's native instruction and skill systems.

## Product shape

The repository is both an installable configuration bundle and a public guide.
`AGENTS.md` is the complete always-loaded agreement. Three skills carry detailed
procedures for dependency review, quarantine, and release work. Documentation
explains installation, architecture, provenance, and the exact semantic mapping
from the Claude edition.

## Visual thesis

Matte ivory, deep ink, cobalt, and one brass accent create an editorial workshop
rather than a generic developer dashboard. The hero shows a large body of work
completed and exactly one decision escalated. Typography and spacing carry the
interface; rules appear as a navigable field rather than a card grid.

## Content plan

1. Hero: the name, promise, installation action, and editorial illustration.
2. Authority: what the agent decides and what still requires the owner's word.
3. Rule map: all 42 rules, grouped by the same subjects as `AGENTS.md`.
4. Native architecture: global instructions, project overrides, and skills.
5. Installation: one clear path to the repository and full guide.

## Interaction thesis

The page uses a restrained entrance sequence, a sticky section index with a
clear active state, and direct rule filtering. Motion is short, meaningful, and
disabled under `prefers-reduced-motion`.

## Verification

Automated checks validate the required repository files, the semantic version,
the `AGENTS.md` size ceiling, skill metadata, all 42 rule identifiers in the
visual map, and the absence of placeholders. The page is rendered at desktop
and mobile sizes for visual inspection.
