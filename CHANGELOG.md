# Changelog

All notable changes are recorded here. Dates are absolute.

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
