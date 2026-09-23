# 0008 — Guard the full local-file path and roll back this install transaction

- **Status:** accepted, 2026-09-23 (independent review repairs).
- **Scope:** install and restore preflight; install interruption recovery.
- **Extends:** ADR 0007's local-symlink decision.

## Context

The final target of `playbook-local.md` can be external while an intermediate
file or directory symlink lives inside a managed skill. Replacing that skill
removes the intermediate link and makes the owner's local file unreadable.
Checking only the final target therefore does not preserve the local layer.
Separately, deliberate restore rightly rejects an old router, but using that
public restore operation as an installer's automatic rollback could leave a
partially replaced installation after an interrupted upgrade.

## Decision

Install and restore inspect every component of the local file's resolution
chain before following it. Any dependency on a managed destination that the
operation replaces refuses before mutation, including a regular local file
whose parent directory depends on such a link. Independent external
dotfile-manager chains remain allowed. Ambiguous path encodings and checkout
source paths refuse rather than silently selecting another path.

Installation keeps exact pre-replacement originals for its own transaction
and uses them for automatic rollback after a failure or signal. It verifies
the restored state and retains originals plus checkpoint if rollback is
incomplete. This private recovery does not weaken public restore's strict
known-active-router requirement.

## Trade-off

Component-by-component resolution is more code than a final `readlink` check,
and uncertain chains refuse. That cost is justified because retaining the
local file's bytes is not enough if the path that loads them disappears.
