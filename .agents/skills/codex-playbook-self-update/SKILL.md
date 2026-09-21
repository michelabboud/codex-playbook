---
name: codex-playbook-self-update
description: Check and safely update an installed Codex Playbook when the owner asks, or when the installed rules look stale, incomplete, inconsistent, or corrupt; never replace tailored files without approval and a verified backup.
---

# Self-update procedure

*Local layer: if `playbook-local.md` exists in the Codex home, its entries apply only within the non-authorizing, never-weaken boundary in (`AGENTS.md`, "The local layer").*

Use this procedure only when the owner asks for an update check or when the
installed playbook looks wrong, missing, internally inconsistent, or older than
the public source. A routine task does not perform a network check merely
because this skill exists.

## Establish the installed and available versions

1. Read the installed version from the `This rulebook is version` line in the
   active global `AGENTS.md`. If that line is missing or malformed, report the
   copy as unverifiable rather than inventing a version.
2. Fetch the public source of truth without authentication:

   ```sh
   curl -fsSL https://raw.githubusercontent.com/michelabboud/codex-playbook/main/VERSION
   ```

3. Validate that the response is one bare semantic version. A failed fetch,
   redirect to an unexpected host, HTML response, or malformed value is a
   failed check; report it instead of guessing from tags or memory.
4. Compare semantic-version components numerically. Equal means current; a
   lower installed version means an update is available; a higher installed
   version means the local copy may be ahead or tailored and must not be
   replaced automatically.
5. When an update is available, read the public `CHANGELOG.md` for every version
   after the installed one and summarize the behavioral difference in plain
   language.

## Check the local layer against the new text

The owner's customizations live in `${CODEX_HOME:-$HOME/.codex}/playbook-local.md`,
which the playbook never ships and no script creates, writes to, copies over,
moves, or deletes. The check below does read it — that is the one contact any
part of this playbook has with it. An absent file means nothing is customized;
there is nothing to check and nothing to migrate.

When it exists, run the new checkout's own check against it **before proposing
the replacement**, so the owner learns about a stale entry while it is still a
one-line edit rather than as a refused install:

```sh
./scripts/check-local.sh "${CODEX_HOME:-$HOME/.codex}/playbook-local.md" \
  . .agents/skills
```

Exit 0 is fresh. Exit 1 names each stale override as `file:line` with the words
that are gone: report them and let the owner rewrite the entry against the new
rule. Never delete or edit quoted words to silence the check — that is the
override losing its meaning silently, which is the failure this check exists to
prevent. Exit 2 is an unparsable line, a `**Dead words:**` marker that is not at
the start of its line, an `**Override**` entry with no valid Dead-words line
before the next entry or heading, a line longer than 4,096 bytes, an unclosed
fenced code block, a named file that carries a glob character or is missing or
escapes its root, or a local file that exists and cannot be read as a regular
file — including one behind a directory nobody may search; report it the same
way. The check fails closed on purpose: it refuses rather than skipping, so no
entry is ever passed over in silence.

The installer runs the same check in source preflight and refuses on a non-zero
result, before any directory is created and before any backup. There is no flag
that installs past it.

**Then cross-check the changelog.** The check catches a rewritten sentence, not
a changed meaning elsewhere in the same rule. For every rule an intervening
changelog entry says was touched, and that the local layer overrides, read the
new rule in full and say so in the replacement proposal.

## Replacement gate

An update replaces the global instruction file and every managed skill whole. It
is therefore a protected wholesale replacement under the approval table. **Stop
and ask before replacement**, naming:

- installed and available versions;
- the important changes;
- active global file and skill destinations;
- the local layer's result: fresh, or each stale entry with its `file:line`,
  plus every overridden rule an intervening changelog entry touched;
- whether any managed file still differs from its last known installed source,
  which means tailoring that belongs in the local layer and will otherwise be
  lost; and
- that the installer will create and verify a unique recovery checkpoint first,
  and will not touch the local layer at all.

Approval to check is not approval to replace. Do not interpret a general build
request as update approval.

## Approved update

1. Obtain a clean checkout of the exact public version being installed.
2. Run the checkout's repository verification before touching the installation,
   and its local-layer check if that has not already been run.
3. Run its backup-first installer with the explicit replacement option:

   ```sh
   ./scripts/install.sh --replace-agents
   ```

4. Confirm the installer reports its verified checkpoint, global rules target,
   skill root, and installed version.
5. Start a fresh Codex session; instruction discovery occurs at session start.
6. Run the installed-copy verification documented by that release.
7. Report the recovery command using the exact checkpoint path. Never print
   credentials, tokens, or the contents of tailored secret-bearing files while
   comparing installations.

If installation or verification fails, leave the previous installation in
place or restore the verified checkpoint. Never continue with a partial mix of
versions.

## Tailoring found inside a managed file

Tailoring written into `AGENTS.md` or into a skill is lost at the next update:
the installer replaces `AGENTS.md` whole and swaps each skill folder whole, and
the previous contents survive only inside the recovery checkpoint. When the
comparison above finds any, do not carry it forward by hand and do not install
over it silently. Report it, and migrate it into the local layer first — a
value a rule leaves open becomes a **Fill**, a rule the playbook lacks becomes
an **Add** under an `L` section, and a rule contradicted becomes an **Override**
quoting the playbook's exact words after `**Dead words:**`. `INSTALL.md` carries
the procedure; `templates/playbook-local.md` carries the grammar.
