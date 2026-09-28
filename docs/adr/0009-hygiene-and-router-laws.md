# 0009 — Hygiene as a seventeenth skill; two destructive laws move into the router

- **Status:** Accepted — 2026-09-28 (the owner: "please update codex rules as well").
- **Source:** Claude Code Playbook 0.1.20–0.1.21, `checkpoint/0.1.21` at
  `570e7ddfd3ca55f6b9b7d07d23824c95f154cd5d` (its ADR 0014), and 0.1.19's
  economy mode (its ADR 0013).

## Context

Two sessions on 2026-09-27, both in Codex, hit a refused cleanup and routed
around it: `rm -r --` for a refused `rm -rf`, and `find -delete` for a refused
removal of the agent's own temporary files. The source answered with a rule
that a refusal is a stop (0.1.20) and a Hygiene section that turns cleanup into
a classification (0.1.21), both through two deep reviews. This edition still
had the old one-paragraph hygiene checkpoint and no refusal rule.

In this edition every subject rule lives in a skill, and a skill loads only when
the model selects it. On the source side a skill was measured to load 5/5 when
the task named its subject and 2/5 when the need was only implied (source
report `2026-09-26-loading-measurements.md`, Claude models). "Free some space"
names no deletion, so the destructive and hygiene skills can miss exactly the
case they exist for. This edition's own loading has not been measured.

## Decision

1. **Hygiene is a seventeenth skill, `codex-playbook-hygiene`, rules 13.1–13.6**,
   ported from the reviewed source text. Codex adaptations: platform commands
   come from the matching platform skill; the disk floor is set in
   `playbook-local.md`; a sandbox or approval-policy refusal counts as a
   refusal.
2. **Two laws also go in the always-loaded router** (`AGENTS.md`, after the
   approval table): a refused destructive command is never re-issued in another
   form, and worktrees are removed only with `git worktree remove`, without
   `--force`. The procedure stays in the skills; the laws hold even when no
   skill loads. The router stays within its 12,288-byte budget (10,805 bytes).
3. **Rule 10.1 gains the refusal rule** and rule 10.2 sends every cleanup to
   section 13; rule 6.2's checkpoint runs the section-13 procedure.
4. **Economy mode is defined by capability**, as every tier here is: the Strong
   tier's model at the highest effort, one per family. The operator's binding
   names the models.

## Alternatives rejected

- **Fold hygiene into the destructive skill.** Keeps the skill count at
  sixteen, which is pinned in many places, but makes one skill carry two
  triggers, and a cleanup request would load the whole destructive procedure.
- **Laws only in skills.** Matches the source's structure, but ignores the one
  measured difference between the editions: the source's destructive rules load
  every session; this edition's do not.
- **Put the whole hygiene section in the router.** It would exceed the router
  budget, and the procedure is only needed when cleanup happens.

## Consequences

- 56 rules, seventeen skills; the manifest, map, parity matrix, installer
  checkpoint (19 managed names) and tests move with them.
- A behaviour measurement of Codex skill loading is still owed; until then the
  router laws are the backstop.
