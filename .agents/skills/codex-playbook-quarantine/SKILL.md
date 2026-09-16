---
name: codex-playbook-quarantine
description: Set aside a file or local asset safely when deletion or overwrite is uncertain, preserving bytes, provenance, restoration instructions, and owner visibility.
---

# Quarantine

Quarantine converts an uncertain destructive decision into a recoverable one.
Use it when an item is in the way but ownership, purpose, or recoverability is
not proven. This skill explains how to proceed without inventing a new approval
gate.

## Rules

- Validate first in a read-only tool call. Record the exact path, size,
  modification time, ownership, active use, Git status, and SHA-256 hash.
- Move the item in a separate action. Use one explicit literal path: no glob,
  unresolved variable, command substitution, pipeline, or chained command.
- Keep quarantine outside repositories, synced folders, and temporary locations.
  The root must be accessible only to the current user.
- Preserve secret-bearing files without printing their contents. Never quarantine
  active logs, session transcripts, or live databases.
- Report every quarantined item in the task close-out. Quarantine never expires
  automatically.

## Layout

```text
~/.quarantine/
├── INDEX.md
├── inbox/
├── held/
└── closed/
```

Create one directory per act:
`YYYY-MM-DD_<project>_<task>_<sequence>/`, containing `payload/` and
`MANIFEST.md`.

## Manifest

```markdown
# Quarantine manifest
- when: <UTC timestamp>
- by: <agent/session identity>
- original path: <absolute path>
- sha256: <hash>
- size: <bytes>
- modified: <original timestamp>
- reason: <the unresolved doubt>
- restore: <exact command>
- outcome: inbox
```

## Exit

At review, restore the payload, retain it under `held/`, or delete it only after
the approval required by `AGENTS.md`. Move the empty manifest directory to
`closed/` after restoration or authorized deletion so the audit record remains.
