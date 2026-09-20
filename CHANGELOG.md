# Changelog

All notable changes are recorded here. Dates are absolute.

## 0.1.4 — 2026-09-20

### Added

- Rule 3.5, the fiftieth rule — how far development may run ahead of review.
  Mechanical review never holds development. Deep review's ceiling is an
  admission rule: a new batch starts only while at most two closed batches are
  unruled; when a third closes, all three reviews run and nothing new starts
  until one is ruled — worst case three batch ranges. Counted by git ancestry as
  a set (a merge is a union) against a ledger the coordinator keeps; three waits
  at any depth; high deep reviews are gates and every lower review, mechanical
  included, is settled first; the planner owns the stall. The rule carries a
  normative table of sixteen worked cases, and the table wins over the prose.
  Direct port of source 0.1.15.
- One owner for tier selection:
  `.agents/skills/codex-playbook-subagents/references/roster.md`. Four capability
  tiers — Top, Strong, Standard, Fast — each filled by a model and a reasoning
  effort; an optional second family by capability; a dated operator binding kept
  outside the managed packages; no model product identifiers in the tier
  assignments. The boundary is explicit: numbered rules own who does what, the
  roster owns what each tier is.
- `config/managed-resources.txt` — the inventory of nested files an installation
  depends on. The installer refuses, before any backup or destination write, when
  a listed file is missing from the source or is not a regular file; install,
  upgrade, rollback and restore tests cover the nested roster.
- A Strong tier: deep review had been assigned to the same tier as
  implementation and mechanical review.
- `docs/guides/non-blocking-review-pipeline.md`, ADR 0003 and ADR 0004.

### Changed

- Rule 3.1: two kinds of review became three — mechanical, deep, high deep —
  defined by what they close. High deep is a gate. A pending mechanical review
  never delays the next reversible task; a returned blocking finding stops the
  line, whatever kind of review found it.
- Rule 3.3 gained its mechanics, adapted for Codex where it differs: completion
  is registered and handled; an isolated snapshot is prepared by whoever holds
  the permission; a reviewer that cannot write returns its notes through its
  reply and its permissions are never widened to fit the rule; reviewer
  isolation is scoped to what the reviewer can reach; nothing observed on
  another client is asserted of Codex threads.
- The "Deep" tier is renamed "Top". The roster table left the reviews and
  subagents skills for the single reference.
- The mechanical-review measurement carries its provenance: taken on two Claude
  models, it validates no Codex configuration; "Standard, never Fast" is a
  conservative floor pending a Codex measurement.
- The rule count is fifty in the tests, manifest, parity matrix, page and public
  docs. ADR 0002's "49" stands as written.

### Fixed

- **Found by a re-review of this repair, before anything was published.** The admission rule
  could be granted twice on one count: one batch is now open per line at a time, a batch starts
  at the first dispatch of a task the plan allocates to it, and at three the line accepts only
  the fixes that rule a batch. Rows 13–16 of the worked cases. Follows source 0.1.15.
- **The installer's nested-resource preflight had three gaps.** It now refuses any symlink
  inside an active skill's source directory (not only a symlinked leaf), refuses a listed
  resource whose owning skill is not an active skill, and reads an inventory whose last line
  has no newline. Each refusal happens before any backup or destination write.
- **The worked-cases test compared one phrase per row**, which passes a row that also says the
  opposite. It now compares the rule's table row for row against a canonical copy under `tests/`.

### Process

- Reviewed twice by the other model family before anything was published, each
  time as a separate process against pinned commits with a cold-read note first.
  The plan review returned eleven findings and the deep review of the first
  candidate returned eight and **failed it**; all nineteen were confirmed, nine
  of them defects in the source rule, which was corrected first each time
  (source 0.1.14, then 0.1.15). The first candidate was never pushed. Records
  under `docs/reviews/2026-09-20-*`.

## 0.1.3 — 2026-09-17

### Added

- The five partnership principles as a dedicated, linked section in the visual
  playbook.
- A regression contract that requires the visual playbook to retain every
  mantra heading and its navigation target.

### Fixed

- Restored the partnership mantra that was present in `AGENTS.md` but omitted
  from the public visual playbook.

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
