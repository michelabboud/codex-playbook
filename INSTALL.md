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

`CODEX_HOME` controls Codex configuration and the global `AGENTS.md`. It does
not relocate user-scoped `$HOME/.agents/skills`. It must be an absolute,
normalized path with no `.` or `..` components, and it must not equal or sit
inside any managed skill directory. Install and restore reject either ambiguity
before creating a checkpoint.

A skill package is installed whole, so its nested files travel with it.
`config/managed-resources.txt` names the ones an installation actually depends
on, and source preflight refuses — before any backup or destination write — when
one of them is missing from the checkout or is not a regular file. An incomplete
checkout therefore fails loudly instead of installing a skill that points at
nothing.

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
   own playbook, adapt the checked-out identity before installation.

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
   `VERSION`, the restore command, the global override state, and every managed
   destination.
2. Refuse a different existing global `AGENTS.md` by default.
3. Create a unique, private format-2 checkpoint.
4. Record the exact sixteen active and two retired managed names plus whether
   every destination was present or absent.
5. Copy every present destination into the checkpoint with its file modes and
   verify each copy with `cmp` or `diff`.
6. Write `COMPLETE` only after the entire checkpoint verifies.
7. Stage and verify the new global router and all sixteen skills.
8. Swap managed destinations. Retired skills are removed from the active skill
   directory only after their checkpoint has verified.
9. On any copy, swap, verification, or signal failure, automatically restore the
   verified checkpoint.
10. Compare every live item with source and print the installed version,
    destination paths, skill count, and exact recovery checkpoint.

**No managed destination is replaced before step 6 succeeds.** A failed backup
is a refusal, never a warning.

If another global `AGENTS.md` already exists, merge its tailored rules into this
checkout first. Only after reviewing and accepting wholesale replacement use:

```bash
./scripts/install.sh --replace-agents
```

That flag changes only the differing-`AGENTS.md` refusal. It never bypasses
validation, backup, verification, staging, rollback, or interruption recovery.

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
directory. Before changing a destination it creates and verifies a separate
`codex-playbook-prerestore-*` checkpoint of the current state. It stages the
desired state, applies it transactionally, and reinstates the pre-restore state
if staging, swapping, verification, or interruption fails.

Format-2 checkpoints carry their own managed inventory. Format-1 checkpoints
from Codex Playbook v0.1.0 remain supported: restoring one reinstates its three
historical skills, removes the fifteen new-only skills, and preserves unrelated
skills. The pre-restore format-2 checkpoint can then restore the newer state
exactly.

## Updating

Use `codex-playbook-self-update` or perform the same process manually:

1. Compare the installed version to the public `VERSION`.
2. Read every intervening `CHANGELOG.md` entry.
3. Review local tailoring and the new `AGENTS.md`/skill changes.
4. Obtain approval before wholesale replacement.
5. Run `./scripts/install.sh --replace-agents`.
6. Start a fresh Codex session and verify the installed copy.
7. Keep the printed checkpoint path with the close-out evidence.

Every run creates a new checkpoint. No update reuses, rewrites, or deletes an
older checkpoint.

## Windows

For Codex running inside WSL, run the POSIX scripts inside WSL; the execution
platform is Linux. For native Windows/PowerShell, apply the same transaction
exactly: validate, create a unique private checkpoint, copy and compare every
managed destination, mark it complete, stage, swap, compare live state, and
roll back on failure. Never translate the procedure into unconditional
`Copy-Item -Force` operations.
