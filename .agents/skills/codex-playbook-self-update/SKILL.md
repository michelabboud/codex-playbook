---
name: codex-playbook-self-update
description: Check and safely update an installed Codex Playbook when the owner asks, or when the installed rules look stale, incomplete, inconsistent, or corrupt; never replace tailored files without approval and a verified backup.
---

# Self-update procedure

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

## Replacement gate

An update replaces a global instruction file and managed skills that may have
been tailored. It is therefore a protected wholesale replacement under the
approval table. **Stop and ask before replacement**, naming:

- installed and available versions;
- the important changes;
- active global file and skill destinations;
- whether local files differ from their last known installed source; and
- that the installer will create and verify a unique recovery checkpoint first.

Approval to check is not approval to replace. Do not interpret a general build
request as update approval.

## Approved update

1. Obtain a clean checkout of the exact public version being installed.
2. Run the checkout's repository verification before touching the installation.
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
