# Changelog

All notable changes are recorded here. Dates are absolute.

## 0.1.2 — 2026-09-17

### Added

- Sixteen on-demand Codex skills that preserve the complete 49-rule source
  corpus while keeping the always-loaded global router concise.
- A machine-readable rule ownership manifest and managed-skill inventories.
- A human-readable rule parity matrix, progressive-disclosure architecture
  decision, GitHub Pages runbook, and environment-variable reference.
- Rulebook verification covering exact rule ownership, skill inventory,
  metadata limits, router size, visual-site parity, and platform exclusivity.

### Changed

- Rebuilt the installer around a validated manifest and format-2 checkpoints
  that record every active and retired managed skill.
- Rebuilt restoration to support both format-2 checkpoints and the original
  format-1 three-skill backups without losing unrelated user data.
- Replaced the abbreviated public rule map with all 49 source rules, the full
  approval model, and the sixteen-skill Codex architecture.
- Expanded contributor, installation, architecture, plan, and source-parity
  documentation to describe the faithful modular migration.

### Fixed

- Refused installation when a non-empty `AGENTS.override.md` would silently
  shadow the installed global rules.
- Rejected malformed checkpoint completion markers before restoration can
  change any managed destination.
- Rejected malformed manifest state entries, ambiguous `CODEX_HOME` paths, and
  managed-skill overlap before checkpoint or restore writes begin.
- Preserved original global-rule and skill file modes across checkpoints and
  restoration.
- Made upgrade retirement, interrupted swaps, failed rollback storage, and
  legacy restoration explicit, recoverable, and regression-tested.
- Made numeric rule-ID searches exact so `0.1` no longer also matches `10.1`.

## 0.1.1 — 2026-09-17

### Changed

- Established `michelabboud/codex-playbook` as the canonical upstream and
  `nice-michel/codex-playbook` as its contribution fork.
- Updated clone, installation, visual-site, and provenance links to the
  canonical repository.

## 0.1.0 — 2026-09-16

### Added

- A 42-rule, first-person global `AGENTS.md` covering production quality,
  verification, documentation, Git, autonomy, collaboration, and safety.
- Codex-native skills for dependency review, quarantine, and task/release
  close-out.
- Backup-first installation and restoration guidance that leaves existing Codex
  configuration, authentication, and unrelated skills untouched.
- A guarded installer and restore command with verified, unique checkpoints,
  custom `CODEX_HOME` support, explicit replacement consent, transactional
  rollback, interruption recovery, and isolated lifecycle tests.
- A source-parity report documenting every deliberate adaptation from
  `claude-code-playbook`.
- A dependency-free visual rule map and an original editorial hero illustration.
- Public contributor, security, architecture, plan, progress, and decision
  records.

### Fixed

- Corrected the user skill destination to `$HOME/.agents/skills`.
- Replaced unsafe unconditional copy instructions with a checkpoint-first flow
  that refuses different global rules by default.
- Made the Claude-to-Codex adaptation report explicit about doctrinal
  differences instead of overstating one-to-one parity.
