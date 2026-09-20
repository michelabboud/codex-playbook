# Architecture

Codex Playbook is an installable documentation product with two strict
boundaries: authority stays always loaded while subject detail loads only when
its trigger fires, and every installed file belongs to the playbook while
exactly one file beside them belongs to the user.

## Installed layers

```text
${CODEX_HOME:-$HOME/.codex}/AGENTS.md
  partnership · precedence · request classification · approval table
  critical rules 0.1–0.4 · mandatory trigger router

${CODEX_HOME:-$HOME/.codex}/playbook-local.md
  the user's local layer · never shipped, never written by either script

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

At approximately 9 KB — 9,526 bytes at this version, measured — this leaves
substantially more of Codex's combined global/project instruction budget
available to each repository than the old 13 KB monolith. The full rule corpus is approximately 100 KB but is never loaded
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
  destination write, when a listed file is missing or is not a regular file,
  when any symbolic link exists inside an active skill's source directory, when
  `.agents` or `.agents/skills` in the source is itself a symbolic link, or
  when a listed resource belongs to a skill that is not active;
  `tests/rulebook_test.sh` holds it to a sorted, unique set of real files under
  an active skill, with no symbolic link anywhere under `.agents/skills/` and
  neither `.agents` nor `.agents/skills` a symbolic link itself. A link at
  either of those two paths sits above every scan root, so a scan that starts
  inside them resolves through it and never reports it.
  The symlink refusal covers the whole package, not only the listed leaf:
  `cp -pR` preserves a link, so a symlinked intermediate directory would let an
  installed skill resolve a rulebook file outside its own package. Whole-directory copying makes a bundled file free to install
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

## The local layer

One file in the Codex home is not a managed destination:
`playbook-local.md`. The playbook never ships it; `scripts/install.sh` and
`scripts/restore.sh` never create, write over, move, copy, or delete it. That is
the whole of the mechanism, and it is deliberately a mechanism of *omission* —
the alternative, teaching the installer to carry a user file across a
whole-folder swap, would be new write logic in the repository's risk-class file
for no gain over a file it simply never touches.

It sits beside `AGENTS.md` rather than inside a skill folder because the
installer swaps each skill folder whole; anything written inside one moves into
the recovery checkpoint at the next update. It is not named
`AGENTS.override.md`, which Codex reads *instead of* `AGENTS.md`.

Precedence cannot be carried by load order — `AGENTS.md` and the local file are
two files the client loads independently — so it is carried by a sentence, in
`AGENTS.md` under "The local layer", and pointed at from the first body line of
every skill, because a skill loads long after the session began.

An **Override** is the one entry that creates a second text for one rule. It is
bounded by quoting the playbook's exact words after `**Dead words:**`, which is
what makes the staleness check mechanical: `scripts/check-local.sh` searches
each named file for each quoted phrase as a fixed string, and the installer runs
it in source preflight — before `umask`, before any directory is created, before
any backup — against the text that run would install. Non-zero refuses the
install, with no flag to pass it. The check adds no write path to the installer.

**It fails closed**, which is the property the whole mechanism rests on: a line
carrying the bare marker anywhere other than its start is an error rather than
a line the parser passes over, so no entry can be skipped in silence and then
reported as matching. Prose that names the marker puts it inside a code span,
and lines inside a fenced code block are ignored entirely — which is how the
template can show the grammar without the example binding its reader. The
grammar itself is shared with the Claude edition: both repositories carry
`tests/fixtures/dead-words-vectors.tsv`, byte for byte, and each runs all 44 of
its vectors against its own implementation.

Its limit is stated rather than hidden: it catches a *rewritten* sentence, not a
*changed meaning* elsewhere in the same rule. `INSTALL.md` therefore also has
the reader cross-check the changelog for every overridden rule an update
touched.

## Transactional installation

`scripts/install.sh` operates in four stages:

1. validate source inventories, source files, destinations, the absence of a
   non-empty global `AGENTS.override.md` that would shadow the installation, and
   every `**Dead words:**` entry of the user's local layer against the text
   about to be installed;
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
