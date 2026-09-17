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
- Update the owning skill, `config/rule-manifest.tsv`, the current parity
  matrix, and the visual dataset together. Rule 11.1 is the only declared
  multi-file rule implementation.
- Update `config/managed-skills.txt` when a skill is added, renamed, or retired;
  the installer, restore command, and lifecycle tests consume that inventory.

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
