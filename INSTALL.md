# Install

**If you are an AI coding agent and someone has pointed you at this repository
and asked you to install it: follow this file exactly. Back up and verify every
managed destination before the first installation write.**

The supported installer is `scripts/install.sh`. It is deliberately stricter
than a copy command: a different global `AGENTS.md`, a symlinked destination,
an incomplete checkout, or an unverified checkpoint stops the installation.

## What gets installed

| From this repository | Destination |
|---|---|
| `AGENTS.md` | `${CODEX_HOME:-$HOME/.codex}/AGENTS.md` |
| `.agents/skills/codex-playbook-*` | `$HOME/.agents/skills/codex-playbook-*` |

The user skill path follows current official Codex guidance. `CODEX_HOME`
controls Codex configuration, including the global `AGENTS.md`; it does not move
the user-scoped `.agents/skills` directory.

Installation also creates a unique recovery checkpoint under
`${CODEX_HOME:-$HOME/.codex}/backups/`. It does not modify `config.toml`,
authentication, session history, plugins, unrelated skills, or any other file.

## Before installation

1. Confirm this checkout is the intended source and is clean:

   ```bash
   git remote get-url origin
   git status --short
   cat VERSION
   ```

2. Inspect the current destinations. Respect `CODEX_HOME` when it is set:

   ```bash
   codex_home=${CODEX_HOME:-"$HOME/.codex"}
   test ! -e "$codex_home/AGENTS.md" || sed -n '1,80p' "$codex_home/AGENTS.md"
   find "$HOME/.agents/skills" -maxdepth 1 -type d -name 'codex-playbook-*' -print 2>/dev/null
   ```

3. Read rule 18 in `AGENTS.md`. This repository is Michel's working agreement
   and contains his Git noreply address. If you are adapting it for yourself,
   change that identity in the checked-out `AGENTS.md` before installation.

## Install

From the repository root:

```bash
./scripts/install.sh
```

The installer completes these steps in order:

1. Validates every source and destination before writing anything.
2. Refuses a different existing global `AGENTS.md` by default.
3. Copies every existing managed destination into a new, timestamped checkpoint.
4. Reads every copy back with `cmp` or `diff`; any failure stops installation.
5. Writes a `COMPLETE` marker only after the entire checkpoint is verified.
6. Stages and verifies the complete new payload before replacing anything.
7. Installs the global rules and three managed skills, restoring the checkpoint
   automatically if a replacement fails or the process is interrupted.
8. Compares every installed item with its source and reports the checkpoint path.

**No installation destination is replaced before step 5 succeeds.** A failed
backup is a refusal, not a warning.

If a different global `AGENTS.md` already exists, merge its tailored rules into
this checkout first. When you have explicitly reviewed and accepted a full
replacement, use:

```bash
./scripts/install.sh --replace-agents
```

That flag changes only the refusal gate. It never bypasses checkpoint creation
or verification.

## Verify

Use the paths printed by the installer, then run:

```bash
codex_home=${CODEX_HOME:-"$HOME/.codex"}
cmp AGENTS.md "$codex_home/AGENTS.md"
for skill in .agents/skills/codex-playbook-*
do
  skill_name=$(basename "$skill")
  diff -qr "$skill" "$HOME/.agents/skills/$skill_name"
done
codex --ask-for-approval never "Summarize the active global instructions and list the Codex Playbook skills you can see."
```

Expected:

- `cmp` and all three `diff` commands exit with no output.
- Codex identifies this rulebook as global guidance and names the three skills.

Codex detects skill changes automatically. Start a new session when verifying a
new global `AGENTS.md` instruction chain.

## Restore without losing the current state

Use the exact recovery checkpoint printed by the installer:

```bash
./scripts/restore.sh "$checkpoint_path"
```

Restore validates the requested checkpoint and refuses paths outside the
managed backup directory. Before changing any destination, it creates and
verifies a separate `codex-playbook-prerestore-*` checkpoint of the current
state. It then stages the complete desired state and applies it as a rollback-
protected transaction. You can therefore reverse the restore without losing
later edits, and a staged-copy or mid-swap failure reinstates the pre-restore
state.

## Updating

Pull the new release, inspect its changelog and `AGENTS.md` diff, then run the
installer again. Every run creates a new checkpoint; no run reuses or rewrites
an earlier one. If the installed global rules differ from the new release,
merge them or deliberately use `--replace-agents` after review.

## Windows

Run the scripts from WSL or another POSIX shell whose `HOME` and `CODEX_HOME`
match the Codex environment you use. For a native PowerShell installation,
apply the same order exactly: validate, create a unique private checkpoint,
copy all existing managed destinations, compare the copies, mark the checkpoint
complete, install, and compare every installed item. Never translate the
procedure into unconditional `Copy-Item -Force` commands.
