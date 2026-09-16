# Install

This procedure installs the global rulebook and its three personal Codex skills.
It is written to be executed by a human or an agent. It never modifies
`~/.codex/config.toml`, authentication, session history, plugins, or unrelated
skills.

## Preconditions

1. Confirm this checkout is the intended source:

   ```bash
   git remote get-url origin
   git status --short
   cat VERSION
   ```

2. Confirm Codex's home. If `CODEX_HOME` is unset, use `~/.codex`. If it is set,
   install there instead.
3. Inspect the destination before changing it:

   ```bash
   ls -la ~/.codex
   test -f ~/.codex/AGENTS.md && sed -n '1,40p' ~/.codex/AGENTS.md
   ```

If an existing `AGENTS.md` contains tailored rules, installation is a merge, not
an overwrite. Preserve those rules or stop and ask the owner which document
should govern.

## Back up first

Create a private backup directory and copy every destination that will be
replaced:

```bash
install -d -m 700 ~/.codex/backups/codex-playbook-preinstall
cp -p ~/.codex/AGENTS.md ~/.codex/backups/codex-playbook-preinstall/AGENTS.md
cp -R ~/.codex/skills/codex-playbook-dependency-review ~/.codex/backups/codex-playbook-preinstall/ 2>/dev/null || true
cp -R ~/.codex/skills/codex-playbook-quarantine ~/.codex/backups/codex-playbook-preinstall/ 2>/dev/null || true
cp -R ~/.codex/skills/codex-playbook-release ~/.codex/backups/codex-playbook-preinstall/ 2>/dev/null || true
```

Skip only a copy whose source does not exist. Read the backup directory before
continuing; a failed backup is a refusal, not a warning.

On Windows PowerShell, use `$env:CODEX_HOME` when set, otherwise
`$HOME\.codex`; create a `backups\codex-playbook-preinstall` directory and use
`Copy-Item -Force` for the file and `Copy-Item -Recurse -Force` for skill
directories.

## Install

```bash
install -d -m 700 ~/.codex
install -d -m 700 ~/.codex/skills
install -m 600 AGENTS.md ~/.codex/AGENTS.md
cp -R .agents/skills/codex-playbook-dependency-review ~/.codex/skills/
cp -R .agents/skills/codex-playbook-quarantine ~/.codex/skills/
cp -R .agents/skills/codex-playbook-release ~/.codex/skills/
```

On Windows PowerShell, use `New-Item -ItemType Directory -Force` for the two
directories, `Copy-Item -Force` for `AGENTS.md`, and
`Copy-Item -Recurse -Force` for each skill directory.

## Verify

Verify bytes, skill metadata, and instruction discovery:

```bash
cmp AGENTS.md ~/.codex/AGENTS.md
find ~/.codex/skills/codex-playbook-* -name SKILL.md -maxdepth 2 -print
codex --ask-for-approval never "Summarize the active global instructions and list the Codex Playbook skills you can see."
```

Expected:

- `cmp` exits with no output.
- Three `SKILL.md` files are listed.
- Codex identifies this rulebook as global guidance and names the three skills.

Start a new Codex session after installation. Codex rebuilds its instruction
chain at session start.

## Restore

Restoration replaces only the files installed above. Inspect the backup first,
then copy the saved `AGENTS.md` and skill directories back to their original
locations. If no prior file existed, removal of an installed file is destructive
and still follows the owner's current rules.
