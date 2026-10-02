# 0011 — Dev modes, and an owner-only command skill

- **Status:** accepted, 2026-10-02 (ports Claude Code Playbook 0.1.23, source ADR 0015; the owner: "you have my go for both playbooks").
- **Scope:** new skills `codex-playbook-dev-modes` (rules 14.1–14.8) and `codex-playbook-dev-mode` (the owner command); reviews 3.1–3.5; collaboration 7.1 and 7.4; router; inventories.

## Context

The source edition added section 14: a project's dev mode sets how much review
runs and which security findings stop the line, with a floor in every mode, a
security backlog, and hardening phases. Its `/dev-mode` command is a Claude Code
skill with `disable-model-invocation: true`, so only the owner can start it.

## Decision

1. The rules travel as one subject skill, `codex-playbook-dev-modes`, loaded by
   the router before a plan, a reviewer dispatch, a security finding or a mode
   change. The mode line lives in the project's `AGENTS.md`.
2. The command is a second skill, `codex-playbook-dev-mode`, with
   `agents/openai.yaml` setting `policy.allow_implicit_invocation: false`.
   Verified against codex-cli 0.159.1: its bundled skill-creator documentation
   says such a skill "is not injected into the model context by default, but can
   still be invoked explicitly via `$skill`", and the shipped system skill
   `review-agent` uses the same setting. The owner runs
   `$codex-playbook-dev-mode <mode>`.
3. Codex 0.1.8 made plans gate-free, so where the source says the owner's move
   is "the go" for a hardening plan, this edition calls it the instruction.
   No approval row is added; the mode is the owner's word, like economy mode.

## Alternatives rejected

- **One skill for rules and command.** The rules must load implicitly before a
  plan or review; the command must never load implicitly. One file cannot be both.
- **A shorter command name such as `codex-playbook-mode`.** It would lose the
  word the owner uses. The router test now matches whole skill names instead,
  because `codex-playbook-dev-mode` is a prefix of `codex-playbook-dev-modes`.

## Consequences

- Nineteen managed skills; `config/managed-resources.txt` lists the policy file
  beside the roster reference; 64 rule IDs.
- If a future Codex drops `allow_implicit_invocation`, the command still states
  that it runs only when the owner names it; the rule text is the backstop.
