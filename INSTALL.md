# Install

**If you are an AI coding agent installing this repository: follow this file
exactly. No managed destination changes until a complete backup exists and every
copy has been read back successfully.**

The supported installer is `scripts/install.sh`. It is deliberately stricter
than a copy command: a different global `AGENTS.md`, a shadowing
`AGENTS.override.md`, unsafe destination, invalid inventory, incomplete
checkout, or unverified checkpoint stops installation before managed state is
replaced.

## Installed destinations

| Repository source | Destination |
|---|---|
| `AGENTS.md` | `${CODEX_HOME:-$HOME/.codex}/AGENTS.md` |
| Sixteen names from `config/managed-skills.txt` | `$HOME/.agents/skills/<name>/` |
| Every nested file listed in `config/managed-resources.txt` | inside its skill's destination directory |
| Recovery checkpoint | `${CODEX_HOME:-$HOME/.codex}/backups/codex-playbook-preinstall-*` |

One path in that directory is **not** a destination:
`${CODEX_HOME:-$HOME/.codex}/playbook-local.md`, the local layer, belongs to
you. The playbook never ships it, and neither `scripts/install.sh` nor
`scripts/restore.sh` creates, writes to, copies over, moves, or deletes it.
Installation and restoration read it only during their compatibility preflight,
to check it against the managed text they would activate.

`CODEX_HOME` controls Codex configuration and the global `AGENTS.md`. It does
not relocate user-scoped `$HOME/.agents/skills`. It must be an absolute,
normalized path with no `.` or `..` components, and it must not equal or sit
inside any managed skill directory. Install and restore reject either ambiguity
before creating a checkpoint.

A skill package is installed whole, so its nested files travel with it.
`config/managed-resources.txt` names the ones an installation actually depends
on, and source preflight refuses — before any backup or destination write — when
one of them is missing from the checkout or is not a regular file, when a
symbolic link exists anywhere inside an active skill's source directory, when
`.agents` or `.agents/skills` in the source is itself a symbolic link, and
when a listed resource belongs to a skill that is not active. An incomplete
checkout therefore fails loudly instead of installing a skill that points at
nothing, outside its own package, or at a file the installation never copies.

The installer never modifies `config.toml`, authentication, session history,
plugins, unrelated skills, or another file. It recognizes the two obsolete
v0.1.0 skills from `config/retired-skills.txt` only so an upgrade can checkpoint
and retire them without losing their previous contents.

## Before installation

1. Confirm this is the intended checkout and inspect its state:

   ```bash
   git remote get-url origin
   git status --short
   cat VERSION
   ./scripts/verify.sh
   ```

2. Inspect the destinations without printing secret contents:

   ```bash
   codex_home=${CODEX_HOME:-"$HOME/.codex"}
   test ! -e "$codex_home/AGENTS.override.md" ||
     sed -n '1,40p' "$codex_home/AGENTS.override.md"
   test ! -e "$codex_home/AGENTS.md" ||
     sed -n '1,80p' "$codex_home/AGENTS.md"
   find "$HOME/.agents/skills" -maxdepth 1 -type d      -name 'codex-playbook-*' -print 2>/dev/null
   ```

3. Review Michel's Git identity in the workflow skill. If this is becoming your
   own playbook, do not edit it into the installed skill — the next update
   replaces that file whole. Write it as a **Fill** in your local layer, which
   the installer never writes to. See "Make it yours: the local layer" below.

A non-empty global `AGENTS.override.md` takes precedence over `AGENTS.md` in
Codex's discovery chain. The installer refuses that shadowed state rather than
claiming inactive rules were installed successfully.

## Install

From the repository root:

```bash
./scripts/install.sh
```

The installer executes this order:

1. Validate both inventories, all sixteen source skills, `AGENTS.md`,
   `VERSION`, and the restore and local-layer-check commands.
2. Run `scripts/check-local.sh` against the local layer and **the text this run
   would install** — before `umask`, before any directory is created, before any
   backup. A stale override, an unparsable Anchor, Rule digest, or `**Dead words:**` line, a bare marker
   that is not at the start of its line, an `**Override**` with no valid
   Dead-words line, a named file that is missing, carries a glob character, or
   escapes its root, or a local file that exists and cannot be read refuses the
   installation, naming the entry's `file:line` and the words. There is no flag
   to install past it: the fix is to re-read the rule and rewrite the entry.
3. Refuse an unsafe or shadowing global `AGENTS.override.md`, a different
   existing global `AGENTS.md` unless `--replace-agents` was given, and any
   managed destination that is not a plain directory.
4. Create a unique, private format-2 checkpoint.
5. Record the exact sixteen active and two retired managed names plus whether
   every destination was present or absent.
6. Copy every present destination into the checkpoint with its file modes and
   verify each copy with `cmp` or `diff`.
7. Write `COMPLETE` only after the entire checkpoint verifies.
8. Stage and verify the new global router and all sixteen skills.
9. Swap managed destinations. Retired skills are removed from the active skill
   directory only after their checkpoint has verified.
10. On any copy, swap, verification, or signal failure, automatically restore the
    verified checkpoint.
11. Compare every live item with source and print the installed version,
    destination paths, skill count, and exact recovery checkpoint.

Steps 1 to 3 are all read-only: every refusal above happens before `umask`,
before the first directory, and before the first backup.
**No managed destination is replaced before step 7 succeeds.** A failed backup
is a refusal, never a warning.

If another global `AGENTS.md` already exists, merge its tailored rules into this
checkout first. Only after reviewing and accepting wholesale replacement use:

```bash
./scripts/install.sh --replace-agents
```

That flag changes only the differing-`AGENTS.md` refusal. It never bypasses
validation, the local-layer check, backup, verification, staging, rollback, or
interruption recovery.

**Before you reach for it, ask where the tailoring belongs.** Anything you would
edit into `AGENTS.md` or into a skill is lost at the next update, because the
installer replaces `AGENTS.md` whole and swaps each skill folder whole. Put it
in the local layer instead — see the next section — and then a plain
`--replace-agents` update keeps it.

## Make it yours: the local layer

Your customizations live in one file the playbook never ships and no script
writes to: `${CODEX_HOME:-$HOME/.codex}/playbook-local.md`. Installation reads
it, once, during source preflight, to check your Overrides against the text it is
about to install — that is the only contact either script has with it, and it
never creates, writes to, copies over, moves, or deletes it. `AGENTS.md` gives
it its limited force: it may fill an open value, add non-authorizing guidance,
or tighten a constraint. It may never expand authority, remove approval, relax
protection, change precedence, or override the local-layer boundary. An absent
file means nothing is customized.

Start from the template, which is documentation and is never installed by the
script:

```bash
codex_home=${CODEX_HOME:-"$HOME/.codex"}
if [ -e "$codex_home/playbook-local.md" ] ||
   [ -L "$codex_home/playbook-local.md" ]; then
  printf 'A local layer already exists; leaving it alone.\n'
else
  cp templates/playbook-local.md "$codex_home/playbook-local.md"
fi
```

That guard is not decoration. The template is documentation and the local file
is yours: **no command in this guide ever copies over an existing local layer**,
and the one `cp` here is the only copy toward that path in the whole procedure.
If a local layer is already there, keep it and take what you want out of the
template by hand.

The template ships with **no entry in force**: every worked example in it sits
inside a fenced code block, which the checker ignores, so the copy you have
just made binds you to nothing and checks nothing. Write your own entries into
the empty sections at its foot, using the examples as a shape.

An entry is a **Fill** (a value a rule leaves open), an **Add** (a rule the
playbook lacks, in your own `L1`, `L2` sections), or an **Override** (a named
rule changed, binding it to one literal Markdown section heading, its normalized
SHA-256 digest, and a unique quote of at least 16 non-whitespace bytes from that
section). `templates/playbook-local.md` carries the full grammar and a worked
example of each kind.

The check fails closed. The marker is only ever the first thing on its line: a
line that carries it anywhere else is refused rather than skipped, so an entry
can never be passed over in silence. Prose that needs to name the marker puts
it inside a code span, and lines inside a fenced code block are ignored
entirely.

Check it at any time against a checkout, without installing anything:

```bash
./scripts/check-local.sh "${CODEX_HOME:-$HOME/.codex}/playbook-local.md" \
  . .agents/skills
```

Exit 0 is fresh, 1 is stale with every finding reported as `file:line`, and 2 is
a usage error, an unparsable line, a bare marker that is not at the start of its
line, an **Override** with no valid Anchor, Rule digest, and `**Dead words:**`
line before the next entry or heading, a line longer than 4,096 bytes, an unclosed fenced code block, a
named file that carries a glob character (`*`, `?`, `[`) or is missing or escapes
its root, or a local file that exists and cannot be read as a regular file —
including one inside a directory nobody may search, which is never reported as an
absent file.

## Verify the installed copy

Use the paths printed by the installer:

```bash
codex_home=${CODEX_HOME:-"$HOME/.codex"}
cmp AGENTS.md "$codex_home/AGENTS.md"
while IFS= read -r skill_name
do
  diff -qr ".agents/skills/$skill_name"     "$HOME/.agents/skills/$skill_name"
done < config/managed-skills.txt
while IFS= read -r skill_name
do
  test ! -e "$HOME/.agents/skills/$skill_name"
done < config/retired-skills.txt
```

Expected: all commands exit zero with no output. Then start a fresh Codex
session—global instruction discovery occurs at session start—and ask it to
summarize the active global authority and list the visible Codex Playbook
skills.

## Restore without losing current state

Use the exact recovery checkpoint printed by the installer:

```bash
checkpoint_path=/absolute/path/printed/by/the/installer
./scripts/restore.sh "$checkpoint_path"
```

Restore accepts only a complete checkpoint directly under the managed backup
directory. Before creating a pre-restore checkpoint or changing a destination,
it checks the local layer against the checkpoint text. A stale or unusable local
entry refuses restore; the Override is suspended and the stricter constraint
remains in force. If the local file exists, even if it contains only Fill or Add
entries, restore also requires the checkpoint's `AGENTS.md` to retain the
current local-layer loading and authority paragraph. An older checkpoint that
does not load that file is refused before any destination changes; matching
quoted words alone would not keep a local entry active. It then creates and
verifies a separate
`codex-playbook-prerestore-*` checkpoint of the current state, stages the
desired state, applies it transactionally, and reinstates the pre-restore state
if staging, swapping, verification, or interruption fails.

**Restore does not touch your local layer either.** A checkpoint never contains
`playbook-local.md`, so there is nothing for a restore to put back over it: it
stays exactly as you left it, whatever state the managed files are rolled to.
There is no uninstall command in this playbook; removing it means deleting the
managed destinations yourself, and the local file is not one of them.

Format-2 checkpoints carry their own managed inventory. Format-1 checkpoints
from Codex Playbook v0.1.0 remain supported when no local layer exists:
restoring one reinstates its three historical skills, removes the fifteen
new-only skills, and preserves unrelated skills. With a local layer present,
restore refuses that older, local-layer-unaware router. The pre-restore
format-2 checkpoint can restore the newer state exactly after a permitted
restore.

## Updating

Use `codex-playbook-self-update` or perform the same process manually:

1. Compare the installed version to the public `VERSION`.
2. Read every intervening `CHANGELOG.md` entry.
3. **Run the local-layer check against the new checkout before installing
   anything** — the command in the previous section. It is the same check the
   installer runs, and running it first turns a refused install into a
   two-minute edit:

   ```bash
   ./scripts/check-local.sh "${CODEX_HOME:-$HOME/.codex}/playbook-local.md" \
     . .agents/skills
   ```

   Exit 1 names each stale entry as `file:line` with the words that are gone.
   Re-read that rule in the new text and rewrite the entry; do not delete the
   quoted words to silence it.
4. **Cross-check the changelog against your Overrides.** The check catches a
   *rewritten* sentence, not a *changed meaning* elsewhere in the same rule. For
   every rule an intervening entry says was touched, and that you override,
   re-read the new rule in full.
5. Review anything still tailored inside `AGENTS.md` or a skill, and migrate it
   — see the next section.
6. Obtain approval before wholesale replacement.
7. Run `./scripts/install.sh --replace-agents`.
8. Start a fresh Codex session and verify the installed copy.
9. Keep the printed checkpoint path with the close-out evidence.

Every run creates a new checkpoint. No update reuses, rewrites, or deletes an
older checkpoint.

## Migrating tailoring that lives inside a managed file

An installation tailored before the local layer existed carries its changes
inside `AGENTS.md` or inside a skill, where the next update overwrites them.
Migrate once, before that update:

1. Find the differences. Compare each installed file against **the version that
   installation actually records** — the `This rulebook is version` line in the
   installed `AGENTS.md` says which one. Diffing against the current checkout
   instead mixes two things together: what the owner tailored, and everything the
   playbook itself changed since. Check that version out beside this one, into a
   scratch worktree that leaves your own checkout alone:

   ```bash
   codex_home=${CODEX_HOME:-"$HOME/.codex"}
   installed_version=$(sed -n 's/^\*\*This rulebook is version \([^*]*\)\*\*.*/\1/p' \
     "$codex_home/AGENTS.md")
   was=$(mktemp -d)
   git worktree add --detach "$was" "v$installed_version"
   diff -u "$was/AGENTS.md" "$codex_home/AGENTS.md" || true
   while IFS= read -r skill_name
   do
     diff -ur "$was/.agents/skills/$skill_name" \
       "$HOME/.agents/skills/$skill_name" || true
   done < "$was/config/managed-skills.txt"
   git worktree remove --force "$was"
   ```

   If that version was never released there is no `v` tag for it; use its
   `checkpoint/<VERSION>` tag instead. Everything the diff shows is then the
   owner's own work, and only the owner's.

2. Turn each difference into an entry in `playbook-local.md`. Most are a
   **Fill** — a path, an address, a name bound to what you actually have — or an
   **Add**. Only a difference that contradicts a rule is an **Override**, and it
   quotes the playbook's words on a `**Dead words:**` line of its own — the
   marker never sits in the middle of a line, where the check would refuse it.
3. A difference that would be a better rule for everyone is not a local entry:
   send it upstream, and leave it out of the file.
4. Run the check. Exit 0 means every Override still bites on the text you wrote
   it against.
5. Install with `--replace-agents`. The managed files go back to the published
   text; your entries stay in the local file, which the installer read once to
   check them and never wrote to.

## Windows

For Codex running inside WSL, run the POSIX scripts inside WSL; the execution
platform is Linux. For native Windows/PowerShell, apply the same transaction
exactly: validate, create a unique private checkpoint, copy and compare every
managed destination, mark it complete, stage, swap, compare live state, and
roll back on failure. Never translate the procedure into unconditional
`Copy-Item -Force` operations.
