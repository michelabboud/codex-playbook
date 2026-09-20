# Contributing

This is a personal rulebook shared publicly. Contributions are welcome when they
make the rules clearer, safer, more portable, or more faithful to real Codex
behavior.

## Before changing a rule

- Explain the failure or repeated friction the rule addresses.
- Check `docs/adr/` for decisions that constrain the change.
- Preserve the first-person voice. The installed owner is the “I”.
- Keep authority in `AGENTS.md`; skills may add procedure, never new approval
  gates.
- Cite current official Codex documentation for client behavior.
- Update the owning skill, `config/rule-manifest.tsv`, `config/managed-resources.txt`,
  `tests/fixtures/rule-3-5-worked-cases.md`, the current parity matrix, and the
  visual dataset together. Rule 11.1 is the only declared multi-file rule
  implementation.
- Update `config/managed-skills.txt` when a skill is added, renamed, or retired;
  the installer, restore command, and lifecycle tests consume that inventory.
- Update `config/managed-resources.txt` when a skill gains, loses, or renames a
  nested file an installation depends on — a reference a rule tells the reader
  to open. The installer reads it during source preflight and refuses, before
  any backup or destination write, when a listed file is missing or is not a
  regular file, when a symbolic link exists anywhere inside an active skill's
  source directory, when `.agents` or `.agents/skills` in the source is itself
  a symbolic link, and when a listed resource belongs to a skill that is not
  in `config/managed-skills.txt`.

## Required checks

Run:

```bash
./tests/rulebook_test.sh
./tests/install_test.sh
./scripts/verify.sh
```

For visual changes, open `docs/index.html` at desktop and mobile widths, verify
keyboard operation, and confirm `prefers-reduced-motion` removes nonessential
animation.

Use focused commits. Pull requests should state the behavior changed, the reason,
verification evidence, and any intentional parity difference from
`claude-code-playbook`.
