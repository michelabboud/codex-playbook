# Source adaptation — Claude Code to Codex

**Date:** 2026-09-16

**Source reviewed:** `michelabboud/claude-code-playbook` at `d7b8148`

**Target:** `michelabboud/codex-playbook` v0.1.0

This repository is a deliberate Codex edition, not a line-for-line migration.
It preserves Michel's motto, first-person voice, production standard, evidence
discipline, autonomy model, and safety boundaries. Its governing contract is
Michel's current 42-rule Codex `AGENTS.md`, supplied for this project, rather
than the Claude repository's 49-rule modular bundle.

## Preserved doctrine

| Subject | Codex treatment |
|---|---|
| Motto and first-person ownership | Preserved at the top of `AGENTS.md`. |
| Authority and precedence | Conversation → project `AGENTS.md` → legacy project guidance → global rules, within system and safety constraints. |
| Code quality | Production-grade behavior, boundary validation, no fakes, focused diffs, dependency discipline. |
| Testing and evidence | Tests match risk; claims require fresh output; performance requires measurement. |
| Documentation and ADRs | The same decision-record and contributor-documentation standard. |
| Repository structure | Mandatory root documents and an organized `docs/` tree remain explicit. |
| Planning and autonomy | One plan gate, decide by default, preserve scope, and write handoffs. |
| Environment safety | Port, Docker, datastore, log, secret, process, and destructive-action safeguards remain explicit. |

## Codex-native delivery

- Global governing instructions live in `AGENTS.md`, which Codex discovers in a
  defined precedence chain.
- The complete global file remains below Codex's default 32 KiB combined
  instruction limit.
- Repository skills live in `.agents/skills/*/SKILL.md`; the installer places
  personal copies in `$HOME/.agents/skills`, the current official user location.
- Detailed dependency, quarantine, and release procedures use skills so they are
  loaded only when relevant.
- Installation honors `CODEX_HOME` for global configuration and never changes
  `config.toml`.

## Deliberate doctrinal differences

These differences are explicit. They are not described as equivalent behavior.

| Claude edition behavior | Codex v0.1.0 decision | Consequence |
|---|---|---|
| Request classification table and expanded approval matrix | The 42-rule Codex agreement keeps the plan gate and destructive-action gate directly in `AGENTS.md`. | Fewer categories are named; the two approval boundaries remain enforceable. |
| Model-specific review ladder and roster | Capability-based model selection and escalation replace Claude model names; no persistent review ladder is installed in v0.1.0. | Review behavior comes from an invoked Codex review capability or repository-specific instructions, not from this global playbook. |
| Dedicated reply-style rules | Codex communication requirements are split between the current agreement and the client's active response contract. | The repository does not claim full parity with the Claude writing module. |
| Self-update procedure | No autonomous playbook self-update workflow is shipped in v0.1.0. | Updating requires a normal reviewed repository change. |
| Platform command modules for Linux, macOS, and Windows | Cross-platform safety outcomes remain in `AGENTS.md`; installation documents POSIX and Windows execution boundaries. | The Codex edition does not ship the Claude platform command catalog. |
| Namespaced task and phase tags | Tags derive directly from the bare `VERSION` value. | Releases use conventional `v<version>` tags rather than Claude's task namespace scheme. |
| Modular always-loaded rule files | One 13 KB `AGENTS.md` carries the complete current agreement. | Discovery is simpler; infrequent procedure moves to skills instead. |

## Not carried over

- Claude-specific `paths:` frontmatter and automatic rule-file loading.
- Claude model names, session commands, and Claude-only tool terminology.
- `~/.claude/` paths and the Claude platform-file selection mechanism.
- Any claim that all 49 Claude rules have a one-to-one Codex counterpart.

Future releases may intentionally adopt useful source behaviors, but each one
must be evaluated against the current Codex agreement rather than added under a
false claim of parity.
