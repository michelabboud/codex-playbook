# Source parity — Claude Code to Codex

**Date:** 2026-09-16

**Source:** `michelabboud/claude-code-playbook` at `d7b8148`

**Target:** `nice-michel/codex-playbook` v0.1.0

This is a semantic port, not a rename. The working philosophy and language stay
recognizably the same; client mechanics change where Codex behaves differently.

| Subject | Status | Codex treatment |
|---|---|---|
| Motto and partnership | Equivalent | Preserved in first person at the top of `AGENTS.md`. |
| Authority and precedence | Codex-adapted | Conversation → project `AGENTS.md` → legacy project guidance → global rules, within system and safety constraints. |
| Code quality | Equivalent | Production-grade behavior, boundary validation, no fakes, focused diffs, dependency discipline. |
| Testing and evidence | Equivalent | Tests match risk; claims require fresh output; performance requires measurement. |
| Reviews | Codex-adapted | Uses Codex review and subagent capabilities without hardcoding Claude model names. |
| Documentation and ADRs | Equivalent | Same decision and contributor-documentation standard. |
| Repository structure | Equivalent | Same mandatory root files and organized `docs/` tree. |
| Task workflow | Codex-adapted | Same commit/tag/release chain, expressed through a Codex skill and PR-aware flow. |
| Planning and autonomy | Equivalent | One plan gate, decide by default, preserve scope, write handoffs. |
| Subagents and models | Codex-adapted | Capability tiers replace Claude-specific model names; delegation follows the active Codex harness. |
| Environment operations | Equivalent | Same port, Docker, datastore, log, secret, and process safeguards. |
| Destructive actions | Codex-adapted | The short governing rule stays always loaded; the recoverable procedure is a skill. |
| Writing style | Integrated | Direct outcome-first communication is expressed throughout the global rules rather than a Claude-only rule file. |

## Native Codex decisions

- The governing document is `AGENTS.md`, because Codex loads global and project
  instruction chains from that filename.
- The complete global file remains below the default 32 KiB combined instruction
  limit.
- Detailed procedures use `.agents/skills/*/SKILL.md`, matching Codex's
  progressive-disclosure system.
- Installation copies personal skills to `~/.codex/skills/` and does not alter
  `config.toml`.

## Deliberate omissions

- Claude-specific `paths:` frontmatter and automatic rule-file loading.
- Claude model names and reviewer tiers.
- `~/.claude/` paths, Claude session commands, and Claude-only tool terminology.

Nothing was omitted merely to reduce work. Every omission is a client-specific
mechanism replaced by a Codex-native one.
