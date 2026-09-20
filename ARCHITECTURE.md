# Architecture

Codex Playbook is an installable documentation product with one strict boundary:
authority stays always loaded; subject detail loads only when its trigger fires.

## Installed layers

```text
${CODEX_HOME:-$HOME/.codex}/AGENTS.md
  partnership · precedence · request classification · approval table
  critical rules 0.1–0.4 · mandatory trigger router

$HOME/.agents/skills/
  codex-playbook-code/              rules 1.1–1.6
  codex-playbook-testing/           rules 2.1–2.3
  codex-playbook-reviews/           rules 3.1–3.5
  codex-playbook-documentation/     rules 4.1–4.3
  codex-playbook-repository/        rules 5.1–5.3
  codex-playbook-workflow/          rules 6.1–6.4
  codex-playbook-collaboration/     rules 7.1–7.7
  codex-playbook-subagents/         rule 8.1
  codex-playbook-environment/       rules 9.1–9.6
  codex-playbook-destructive/       rules 10.1–10.2
  codex-playbook-quarantine/        rule 10.3
  codex-playbook-platform-linux/    Linux/WSL implementation of 11.1
  codex-playbook-platform-macos/    macOS implementation of 11.1
  codex-playbook-platform-windows/  native Windows implementation of 11.1
  codex-playbook-writing/           rules 12.1–12.4
  codex-playbook-self-update/       guarded update procedure
```

The tier roster has one owner, the reference file bundled inside the subagents
skill (`references/roster.md`), and the installer copies whole skill directories,
so that file installs, upgrades, rolls back and restores with its skill.

Codex discovers the skill names and descriptions in its initial context. The
full `SKILL.md` body enters context only when explicitly selected or matched by
the task. The global router makes those triggers mandatory rather than relying
on a model to guess whether a rule section exists.

## Why authority remains global

Classification and approval determine whether an action is authorized at all.
Loading them after the action would be too late. `AGENTS.md` therefore retains:

- the five partnership principles and production motto;
- the owner/agent relationship and precedence;
- the review-versus-implementation classification;
- the complete approval table;
- critical rules 0.1–0.4; and
- the skill trigger index.

At approximately 8 KB, this leaves substantially more of Codex's combined
global/project instruction budget available to each repository than the old
13 KB monolith. The full rule corpus is approximately 100 KB but is never loaded
as a unit.

Skills carry procedure and detail, never new authority. A skill may explain how
to execute an approved action; it cannot add a reason to stop or ask.

## Source-fidelity contract

Three files are authoritative:

- `config/managed-skills.txt` lists the exact sixteen active skill packages.
  Install, restore, tests, and verification read this file rather than
  duplicating shell lists.
- `config/managed-resources.txt` lists the repository-relative path of every
  nested file inside those packages that an installation depends on — today,
  the roster reference the reviews and subagents skills both read. The installer
  consumes it during source preflight and refuses, before any backup or
  destination write, when a listed file is missing or is not a regular file;
  `tests/rulebook_test.sh` holds it to a sorted, unique set of real files under
  a managed skill. Whole-directory copying makes a bundled file free to install
  and copies its absence just as faithfully, which is the defect this inventory
  closes.
- `config/rule-manifest.tsv` maps the canonical 50 rule IDs to their owners.
  Rule 11.1 is the declared exception with three platform implementations.

`tests/rulebook_test.sh` compares the manifest to the canonical ID set, scans
all rule headings for missing, unknown, duplicate, and off-owner entries,
validates skill metadata/router coverage, and checks the parity report and
visual map against the same IDs.

The Claude Code `paths:` mechanism is not copied because Codex does not use it
for topic modules. Codex's progressive-disclosure skills implement the same
outcome using native discovery.

## Platform selection

All three platform skills install so one checkout and checkpoint remains
portable. The global router and mutually exclusive descriptions require exactly
one execution-environment skill:

- Linux distributions and Windows Subsystem for Linux use Linux;
- Darwin uses macOS; and
- native PowerShell/Windows uses Windows.

The platform body supplies commands only. It does not change the underlying
rule or approval boundary.

## Transactional installation

`scripts/install.sh` operates in four stages:

1. validate source inventories, source files, destinations, and the absence of a
   non-empty global `AGENTS.override.md` that would shadow the installation;
2. create a private format-2 checkpoint containing `AGENTS.md`, the exact
   active-plus-retired managed inventory, every state marker, and verified
   copies of every present item;
3. stage and verify the complete new payload; then swap the global router and
   all sixteen active skills while retiring the two v0.1.0 procedural skills;
4. compare every installed item to source and remove redundant transaction
   copies only after success.

A copy, swap, signal, or verification failure restores the verified checkpoint.

`scripts/restore.sh` creates another verified pre-restore checkpoint before it
changes anything. It supports:

- format 2, whose checkpoint owns its exact inventory; and
- historical format 1, whose inventory is the original dependency-review,
  quarantine, and release skills.

Restoration transitions over the union of checkpoint and current inventories.
That removes new-only skills when restoring an old state, restores retired
skills when they existed, and never touches unrelated skills or Codex
configuration.

## Repository delivery

This remains a separate repository from `claude-code-playbook` because the two
clients discover and install instructions differently. The doctrine is now
one-to-one; the delivery mechanism is client-native. ADR 0002 supersedes ADR
0001's v0.1.0 decision to accept deliberate rule differences.
