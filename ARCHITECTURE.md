# Architecture

This repository is an installable documentation product. Its architecture is
the boundary between guidance Codex must always see and procedures it should
load only when relevant.

```text
AGENTS.md                         always-loaded working agreement
  └── ~/.codex/AGENTS.md         installed global copy

.agents/skills/                   progressive-disclosure procedures
  ├── codex-playbook-dependency-review/
  ├── codex-playbook-quarantine/
  └── codex-playbook-release/
      └── $HOME/.agents/skills/  installed personal copies

scripts/install.sh               checkpoint-first installation
scripts/restore.sh               reversible restoration
tests/install_test.sh            isolated lifecycle verification

docs/index.html                   dependency-free visual map
docs/reports/2026-09-16-source-parity.md
                                  semantic bridge to claude-code-playbook
```

## Why the rulebook is one `AGENTS.md`

Codex reads global `AGENTS.md` before work begins and layers project guidance
after it. The complete rulebook is 13 KB, below Codex's default 32 KiB combined
instruction limit, so splitting the governing rules would make discovery less
reliable without buying meaningful context savings.

The three procedural skills are different. Their full instructions matter only
when a dependency is added, uncertain data must be set aside, or a task/release
closes. Codex exposes skills by name and description, then loads `SKILL.md` only
when selected. That is the correct place for detail that should not occupy every
session.

## The load-bearing property

Skills carry procedure, never new authority. `AGENTS.md` owns precedence,
approval, and scope. A skill may explain how to execute an approved action; it
may not invent a new reason to stop or ask.

## Why this is a separate repository

The origin and working philosophy are shared with `claude-code-playbook`, but
the delivery mechanism is executable client configuration and the current Codex
agreement has deliberate doctrinal differences. Claude Code and Codex discover
instructions, skills, overrides, and configuration differently. Separate
repositories keep installation unambiguous while the parity report makes every
known divergence explicit.
