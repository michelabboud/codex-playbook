# Codex Playbook

![A cobalt-and-ivory robot stands beside a tall, squared stack of completed work and presents one small brass decision card to a calm human collaborator in a sunlit workshop.](docs/assets/codex-playbook-hero.png)

*A mountain of work delivered. One decision escalated. The rulebook is built
around that ratio.*

**Do the right thing, not the lazy or easy thing.**

Codex Playbook is Michel's Claude Code Playbook, faithfully adapted to Codex.
It preserves the same 50 rules, partnership model, approval boundaries, review
ladder, verification standard, workflow, safety procedures, and writing rules.
The adaptation changes client mechanics—not doctrine.

The rulebook is written in the first person on purpose. Once installed, “I”
means you. These are not abstract best practices; they are the terms of the
collaboration.

## See the whole system

**[Open the visual playbook →](https://michelabboud.github.io/codex-playbook/)**

The dependency-free visual map presents the five partnership principles, all
50 rules, the complete approval matrix, the thirteen rule sections, and the
split between the always-loaded authority router and sixteen on-demand skills.
It uses no framework, build step, cookies, or analytics.

## Review without stalling development

Reviews are slow, and the deep ones are expensive too. A review that development
sits waiting for is a stall, so the rulebook pipelines them:

| Kind | Closes | While it runs, development… |
|---|---|---|
| **Mechanical** | every task | never waits |
| **Deep** | every batch of 3–10 tasks | keeps going — a line carries at most **three unruled** batches, the one being built included (*unruled*: started, and not yet settled — a review that has returned with open findings still counts); every landing belongs to the open batch — an ad-hoc one for unplanned work — except a reviewed fix for a recorded finding, so at three with none open only fixes land; counted by git ancestry as a set, against a ledger the coordinator keeps; twenty worked cases are part of the rule |
| **High deep** | a milestone or a release | waits — it may revise the plan, every lower review is settled first, and the wait works the queue of minor findings |

What makes that safe is mechanics, not optimism: **a review's input is a commit,
never a working tree**; the reviewer reads git objects only; the brief defines
what counts as blocking; a blocker stops the line, whichever kind of review found
it. The rules are 3.3 and 3.5 in the `codex-playbook-reviews` skill; the reasoning
and the evidence are in `docs/guides/non-blocking-review-pipeline.md`; the decisions
are ADR 0003 and ADR 0004.

The roster of tiers — Top · Strong · Standard · Fast — defines each tier by capability and
carries no model product identifiers; it has one owner:
`.agents/skills/codex-playbook-subagents/references/roster.md`. The rules own who does what;
the roster owns what each tier is.

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

The global router is about 9 KB instead of loading the roughly 100 KB complete
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
| **Never shipped, never written** | `${CODEX_HOME:-$HOME/.codex}/playbook-local.md` | Your local layer: the one file the scripts only ever read, and only to check it |

The installer does not modify `config.toml`, authentication, sessions, plugins,
unrelated skills, or any other Codex state. An upgrade from v0.1.x creates a
checkpoint and retires the obsolete dependency-review and release skills only
after their contents are safely captured; their rules now live in the code and
workflow skills.

## Make it yours

"Make it your own" used to mean editing the installed files, which made every
update a merge. It no longer does. Your customizations live in one file the
playbook never ships and neither script ever creates, writes over, moves, or
deletes: `${CODEX_HOME:-$HOME/.codex}/playbook-local.md`. `AGENTS.md` gives it
its force in a paragraph headed "The local layer" — read it at the start of a
session when it exists, and **where an entry there changes a rule, the entry
wins over the playbook's wording.** An absent file means nothing is customized.

An entry is a **Fill** (a value a rule leaves open, or a generic term bound to
what you actually have), an **Add** (a rule the playbook lacks, under your own
`L1`, `L2` sections), or an **Override** (a named rule changed, quoting after
`**Dead words:**` the playbook's exact words that no longer apply, each with the
file they are in). Start from
[`templates/playbook-local.md`](templates/playbook-local.md), which carries the
grammar and a worked example of each kind — inside a fenced code block, so the
copy you make binds you to nothing until you write an entry of your own.

`scripts/check-local.sh` searches each named file for each quoted phrase as a
fixed string. Found: the override still bites on the text it was written
against. Not found: the playbook rewrote that rule, the override is stale, and
the installer refuses the update — naming the entry's `file:line` and the words
— until you re-read the rule and rewrite the entry. The check runs in source
preflight, before any directory is created and before any backup, against the
text the run would install. There is no flag to install past it.

It fails closed. A `**Dead words:**` marker that is not the first thing on its
line is an error, never an entry quietly passed over, so no override can be
skipped and then reported as matching; prose about the marker puts it inside a
code span, and a fenced code block is ignored entirely.

## Source parity

The source is
[`michelabboud/claude-code-playbook`](https://github.com/michelabboud/claude-code-playbook).
Every source rule ID remains present. Codex-specific changes are limited to
instruction discovery, skill loading, model capability names, platform paths,
and the update source.

- [50-rule parity matrix](docs/reports/2026-09-17-rule-parity-matrix.md)
- [Architecture decision](docs/adr/0002-progressive-disclosure-rulebook.md)
- [Historical v0.1.0 adaptation report](docs/reports/2026-09-16-source-parity.md)

## Repository map

```text
AGENTS.md                 lean global authority and trigger router
.agents/skills/           sixteen complete on-demand rule sections
config/managed-skills.txt authoritative installed-skill inventory
config/managed-resources.txt  nested files an installation depends on
config/rule-manifest.tsv  authoritative 50-rule ownership map
INSTALL.md                backup-first install and recovery procedure
templates/playbook-local.md  local-layer template; documentation, never installed
scripts/install.sh        format-2 transactional installer
scripts/restore.sh        format-1/format-2 transactional restoration
scripts/check-local.sh    local-layer staleness check, run in source preflight
tests/rulebook_test.sh    exact rule, owner, metadata, and visual parity checks
tests/install_test.sh     isolated install, upgrade, rollback, and restore tests
tests/check_local_test.sh local-layer grammar, staleness, and path-escape tests
docs/index.html           visual playbook served by GitHub Pages
docs/adr/                 architectural decisions
docs/reports/             parity and verification evidence
docs/plans/               approved designs and implementation plans
```

## Version

Current: **v0.1.6**. `VERSION` is the source of truth; release detail lives in
[`CHANGELOG.md`](CHANGELOG.md).

## License

MIT — use it whole, take the parts that fit, and rewrite the rest until the
working agreement is genuinely yours.
