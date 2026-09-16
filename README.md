# Codex Playbook

![A cobalt-and-ivory robot stands beside a tall, squared stack of completed work and presents one small brass decision card to a calm human collaborator in a sunlit workshop.](docs/assets/codex-playbook-hero.png)

*A mountain of work delivered. One decision escalated. The rulebook is built
around that ratio.*

**Do the right thing, not the lazy or easy thing.**

Codex Playbook is an opinionated, installable working agreement for Codex. It
defines what the agent should decide, what still needs your approval, how work
is verified, and what “done” means when the repository matters.

It is written in the first person on purpose. Once installed, “I” means you.
These are not abstract best practices; they are the terms of the collaboration.

## See the whole system

**[Open the visual rule map →](https://nice-michel.github.io/codex-playbook/)**

The map presents all 42 rules, the two normal approval gates, the close-out
chain, and the Codex-native split between global instructions and skills. It is
a single static file with no framework, build step, cookies, or analytics.

## Install

Give the repository URL to Codex and say:

> Install this playbook. Follow `INSTALL.md`, preserve my existing Codex
> configuration, and show the verification evidence.

The supported path is intentionally small and backup-first:

```bash
git clone https://github.com/nice-michel/codex-playbook.git
cd codex-playbook
./scripts/install.sh
```

The installer creates and verifies a unique recovery checkpoint before its
first destination write. It refuses to overwrite a different global
`AGENTS.md` unless you explicitly pass `--replace-agents` after review. The full
install, update, restore, and Windows guidance is in
[`INSTALL.md`](INSTALL.md).

## What gets installed

- `AGENTS.md` — the always-loaded working agreement: 42 rules covering quality,
  verification, documentation, Git, autonomy, collaboration, and safety.
- `codex-playbook-dependency-review` — current-source dependency vetting.
- `codex-playbook-quarantine` — a recoverable alternative to uncertain deletion.
- `codex-playbook-release` — the task checkpoint and phase release chain.

Global rules install under `${CODEX_HOME:-$HOME/.codex}`. Personal skills install
under `$HOME/.agents/skills`, the current Codex user-skill location.

Codex reads global and repository `AGENTS.md` files in a defined precedence
chain. It sees skill names and descriptions up front, then loads full skill
instructions only when relevant. That makes the governing rules reliable and
the detailed procedures available without paying for them in every session.

## Same doctrine, native delivery

This project is the Codex sibling of
[`claude-code-playbook`](https://github.com/michelabboud/claude-code-playbook).
The motto, first-person voice, quality bar, and decision philosophy are shared.
The Codex edition is governed by Michel's current 42-rule agreement rather than
being a line-for-line copy of the Claude bundle. Client mechanics and deliberate
doctrinal differences are recorded instead of hidden.

The exact mapping is recorded in
[`docs/reports/2026-09-16-source-parity.md`](docs/reports/2026-09-16-source-parity.md).

## Repository map

```text
AGENTS.md                 installable global rules
.agents/skills/           Codex-native procedural skills
INSTALL.md                backup-first installation and verification
scripts/install.sh        guarded, checkpoint-first installer
scripts/restore.sh        guarded restoration with a pre-restore checkpoint
tests/install_test.sh     isolated install, upgrade, and restore tests
docs/index.html           visual map, served by GitHub Pages
docs/adr/                 architectural decisions
docs/guides/              contributor and operating guidance
docs/reports/             parity and verification evidence
docs/plans/               approved designs and implementation plans
```

## Version

Current: **v0.1.0**. `VERSION` is the source of truth; release detail lives in
[`CHANGELOG.md`](CHANGELOG.md).

## License

MIT — use it whole, take the parts that fit, and rewrite the rest until the
working agreement is genuinely yours.
