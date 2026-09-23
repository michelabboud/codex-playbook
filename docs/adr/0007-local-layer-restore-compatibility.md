# 0007 — Preserve the local layer across managed replacement

- **Status:** accepted, 2026-09-23 (owner-approved fail-closed compatibility repair).
- **Scope:** install and restore preflight; the local file is never changed.

## Context

A local-file symlink may be maintained by a dotfile manager outside the managed
destinations. It may also resolve *inside* a skill or global router about to be
replaced, which would destroy or orphan the owner's local text. Separately, a
checkpoint can quote the local-layer loading paragraph inside a fenced example
without actually instructing Codex to load the file.

## Decision

Resolve a local-file symlink before the first backup or managed mutation. Refuse
it only when its target lies inside a destination the operation replaces;
preserve and check external dotfile-manager symlinks normally. When a local
file exists, restore accepts only a checkpoint whose complete `AGENTS.md`
matches the current known active local-layer router byte for byte. A quoted
paragraph is insufficient. Refusals leave the local file and destinations
unchanged.

## Alternatives rejected

- **Refuse every local-file symlink.** This needlessly excludes safe external
  dotfile-manager setups.
- **Accept a paragraph match.** A fenced example or otherwise inactive router
  can satisfy the string test without loading the local file.

## Consequences

Older or tailored checkpoint routers may be refused even when a human could
judge them compatible. That compatibility decision belongs to the owner;
restore does not guess or rewrite a checkpoint.
