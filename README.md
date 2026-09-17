# Codex Playbook

![A cobalt-and-ivory robot stands beside a tall, squared stack of completed work and presents one small brass decision card to a calm human collaborator in a sunlit workshop.](docs/assets/codex-playbook-hero.png)

*A mountain of work delivered. One decision escalated. The rulebook is built
around that ratio.*

**Do the right thing, not the lazy or easy thing.**

Codex Playbook is Michel's Claude Code Playbook, faithfully adapted to Codex.
It preserves the same 49 rules, partnership model, approval boundaries, review
ladder, verification standard, workflow, safety procedures, and writing rules.
The adaptation changes client mechanics—not doctrine.

The rulebook is written in the first person on purpose. Once installed, “I”
means you. These are not abstract best practices; they are the terms of the
collaboration.

## See the whole system

**[Open the visual playbook →](https://michelabboud.github.io/codex-playbook/)**

The dependency-free visual map presents all 49 rules, the complete approval
matrix, the thirteen rule sections, and the split between the always-loaded
authority router and sixteen on-demand skills. It uses no framework, build
step, cookies, or analytics.

## Why it is modular

Codex loads the applicable `AGENTS.md` chain into every session. It discovers
skills by name and description, then loads the full `SKILL.md` only when a task
matches or the skill is explicitly selected.

Codex Playbook uses that progressive-disclosure model:

- `AGENTS.md` stays small and always available. It carries the five partnership
  principles, precedence, request classification, the complete approval table,
  critical rules 0.1–0.4, and the mandatory skill router.
- Sixteen skills carry the full subject rules and procedures for code, testing,
  reviews, documentation, repository structure, workflow, collaboration,
  subagents, operations, destructive actions, quarantine, platform commands,
  writing, and self-update.
- All three platform skills install for portability. The router selects only the
  execution environment's skill: Linux or WSL, macOS, or native Windows.

The global router is about 8 KB instead of loading the roughly 84 KB complete
rule corpus into every session.

## Install

Give the repository URL to Codex and say:

> Install this playbook. Follow `INSTALL.md`, preserve my existing Codex
> configuration and skills, and show the backup and verification evidence.

Or run:

```bash
git clone https://github.com/michelabboud/codex-playbook.git
cd codex-playbook
./scripts/install.sh
```

The installer validates the source and every destination, refuses a shadowing
global `AGENTS.override.md`, creates and verifies a unique recovery checkpoint,
stages the complete payload, and only then changes the global router or managed
skills. A failed copy, swap, or interruption restores the checkpoint.

A different existing global `AGENTS.md` is never overwritten by default.
`--replace-agents` is accepted only after review. The full installation,
upgrade, restore, and Windows guidance is in [`INSTALL.md`](INSTALL.md).

## What gets installed

| Layer | Destination | Purpose |
|---|---|---|
| Global authority router | `${CODEX_HOME:-$HOME/.codex}/AGENTS.md` | Always-loaded partnership, authority, classification, approval, and trigger routing |
| Sixteen personal skills | `$HOME/.agents/skills/codex-playbook-*/` | Full subject procedures loaded through progressive disclosure |
| Recovery checkpoint | `${CODEX_HOME:-$HOME/.codex}/backups/` | Verified pre-install state for exact restoration |

The installer does not modify `config.toml`, authentication, sessions, plugins,
unrelated skills, or any other Codex state. An upgrade from v0.1.x creates a
checkpoint and retires the obsolete dependency-review and release skills only
after their contents are safely captured; their rules now live in the code and
workflow skills.

## Source parity

The source is
[`michelabboud/claude-code-playbook`](https://github.com/michelabboud/claude-code-playbook).
Every source rule ID remains present. Codex-specific changes are limited to
instruction discovery, skill loading, model capability names, platform paths,
and the update source.

- [49-rule parity matrix](docs/reports/2026-09-17-rule-parity-matrix.md)
- [Architecture decision](docs/adr/0002-progressive-disclosure-rulebook.md)
- [Historical v0.1.0 adaptation report](docs/reports/2026-09-16-source-parity.md)

## Repository map

```text
AGENTS.md                 lean global authority and trigger router
.agents/skills/           sixteen complete on-demand rule sections
config/managed-skills.txt authoritative installed-skill inventory
config/rule-manifest.tsv  authoritative 49-rule ownership map
INSTALL.md                backup-first install and recovery procedure
scripts/install.sh        format-2 transactional installer
scripts/restore.sh        format-1/format-2 transactional restoration
tests/rulebook_test.sh    exact rule, owner, metadata, and visual parity checks
tests/install_test.sh     isolated install, upgrade, rollback, and restore tests
docs/index.html           visual playbook served by GitHub Pages
docs/adr/                 architectural decisions
docs/reports/             parity and verification evidence
docs/plans/               approved designs and implementation plans
```

## Version

Current: **v0.1.2**. `VERSION` is the source of truth; release detail lives in
[`CHANGELOG.md`](CHANGELOG.md).

## License

MIT — use it whole, take the parts that fit, and rewrite the rest until the
working agreement is genuinely yours.
