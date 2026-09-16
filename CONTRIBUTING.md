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

## Required checks

Run:

```bash
./scripts/verify.sh
```

For visual changes, open `docs/index.html` at desktop and mobile widths, verify
keyboard operation, and confirm `prefers-reduced-motion` removes nonessential
animation.

Use focused commits. Pull requests should state the behavior changed, the reason,
verification evidence, and any intentional parity difference from
`claude-code-playbook`.
