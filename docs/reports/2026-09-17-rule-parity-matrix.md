# Claude Code to Codex rule parity matrix

**Revised 2026-09-20 for source 0.1.15** — rows 3.1, 3.3, 3.4, 3.5 and 8.1 moved
to that source; every other row stays at the source version recorded in the
original matrix. The matrix now covers 50 numbered rules; rule 3.5 is new.

**Date:** 2026-09-17

**Source:** `michelabboud/claude-code-playbook` at `5db68e3` for every row that
did not move, and source 0.1.15 — `claude-code-playbook` commit
`0daf8b50d6a623dfd2c03f0570aa0a065c7b9179` (the rule text), published under tag
`checkpoint/0.1.15`, which adds only that version's close-out — for rows 3.1, 3.3, 3.4,
3.5 and 8.1.

**The local layer (0.1.6), and its ordering dependency.** Codex Playbook 0.1.6
ports the source's decision that customizations live in a file the playbook
never touches. The source text is `claude-code-playbook` commit
`e5c4f855f54938a2d7b636dc5ae648d17e2bff21` — ADR 0004, *Customizations live in a
local layer the playbook never touches*, with its decision 5 completed before
publication: the Dead-words grammar is read as code spans rather than split on
the separator, the check fails closed, and the 47 conformance vectors of
`tests/fixtures/dead-words-vectors.tsv` are carried by both editions,
byte-identical, and run by each edition's own tests. It supersedes
`267057ae88876d746cba956bda48bf37bd69acb9`, which this matrix cited before the
grammar was completed and which carries the first, narrower version of that
decision. The source's own implementation of the completed grammar is its
commit `1b2ff2780a2d03e7f05e96150c6bb3f7f0dc1976`; **neither commit is
published**, so both are cited as they stood on 2026-09-21 and may still move.
That repository publishes this work as **0.1.16**, and as of this revision
`checkpoint/0.1.16` does not yet exist there — its highest published tag is
`checkpoint/0.1.15` — so this edition's own `checkpoint/0.1.6` is held until it
does, exactly as 0.1.4 was held for `checkpoint/0.1.15`. The local layer adds no
numbered rule and changes no row below: it is a paragraph of `AGENTS.md` and one
pointer line per skill. Three differences from the source are deliberate; the
first two are recorded in ADR 0005. **One** local file rather than two, because
Codex has no path-scoped loading for a second one to preserve. The file is
`playbook-local.md`, never `AGENTS.override.md`, which Codex reads *instead of*
`AGENTS.md`. And this edition alone refuses a local-layer line longer than
**4,096 bytes** — a fail-closed bound on the quadratic parse, raised as
informational finding I2 of the mechanical review of 2026-09-21; the shared
vectors carry no line near it, so the bound cannot change how any of them
behaves, but a hand-written line longer than that would be refused here and
accepted by the source.

**Target architecture:** lean global authority router plus sixteen
progressive-disclosure Codex skills.

The migration preserves every numbered source rule. “Direct” means the rule
wording and behavior carry over without a client-specific semantic change.
“Adapted” means only the named Codex mechanism differs. Rule 11.1 is one logical
rule with three operating-system implementations.

| Rule | Claude source | Codex owner | Treatment |
|---|---|---|---|
| 0.1 | `rules/AUTHORITY.md` | `AGENTS.md` | Direct: the owner decides when work stops. |
| 0.2 | `rules/AUTHORITY.md` | `AGENTS.md` | Direct: no unilateral deferral, skipping, or descoping. |
| 0.3 | `rules/AUTHORITY.md` | `AGENTS.md` | Direct: choose the full production-grade reading unless outcomes materially diverge. |
| 0.4 | `rules/AUTHORITY.md` | `AGENTS.md` | Direct: the owner sets scope; the agent decides implementation. |
| 1.1 | `rules/CODE.md` | `codex-playbook-code` | Direct: no fakes and only complete vertical slices. |
| 1.2 | `rules/CODE.md` | `codex-playbook-code` | Direct: production-grade validation, errors, logging, and failure handling. |
| 1.3 | `rules/CODE.md` | `codex-playbook-code` | Direct: named constants and configuration only where warranted. |
| 1.4 | `rules/CODE.md` | `codex-playbook-code` | Direct: repository patterns and focused diffs. |
| 1.5 | `rules/CODE.md` | `codex-playbook-code` | Adapted: live web vetting remains mandatory; no separate dependency skill. |
| 1.6 | `rules/CODE.md` | `codex-playbook-code` | Direct: preserve vendored provenance and licenses. |
| 2.1 | `rules/TESTING.md` | `codex-playbook-testing` | Direct: happy/failure paths, regression-first fixes, no ceremonial tests. |
| 2.2 | `rules/TESTING.md` | `codex-playbook-testing` | Direct: decisive evidence and base-commit proof for attributed failures. |
| 2.3 | `rules/TESTING.md` | `codex-playbook-testing` | Direct: performance claims require measurements. |
| 3.1 | `rules/REVIEWS.md` | `codex-playbook-reviews` | Adapted: three kinds of review (mechanical, deep, high deep); capability tiers Top/Strong/Standard/Fast in place of source model names. |
| 3.2 | `rules/REVIEWS.md` | `codex-playbook-reviews` | Direct: dependency, diff-size, planner, and risk-based batch boundaries. |
| 3.3 | `rules/REVIEWS.md` | `codex-playbook-reviews` | Direct, with Adapted mechanics: completion is registered and handled; the snapshot is prepared by whoever holds the permission; a reviewer that cannot write returns its notes through its reply; no claim about Codex threads from another client's evidence. |
| 3.4 | `rules/REVIEWS.md` | `codex-playbook-reviews` | Adapted: high deep review on the Top tier with two independent passes. |
| 3.5 | `rules/REVIEWS.md` | `codex-playbook-reviews` | Direct: how far development may run ahead of review — the ceiling as one invariant, the normative table of twenty worked cases, ancestry set, ledger, three waits, gates. |
| 4.1 | `rules/DOCS.md` | `codex-playbook-documentation` | Direct: write reasoning and gotchas for a new contributor. |
| 4.2 | `rules/DOCS.md` | `codex-playbook-documentation` | Direct: qualifying ADRs at decision time, permanent and indexed. |
| 4.3 | `rules/DOCS.md` | `codex-playbook-documentation` | Direct: update changelog, progress, plan, backlog, usage, and architecture. |
| 5.1 | `rules/REPO.md` | `codex-playbook-repository` | Direct: complete required repository record set and defined contents. |
| 5.2 | `rules/REPO.md` | `codex-playbook-repository` | Direct: conditional security, contribution, runbook, and glossary files. |
| 5.3 | `rules/REPO.md` | `codex-playbook-repository` | Direct: full documentation taxonomy and dated names. |
| 6.1 | `rules/WORKFLOW.md` | `codex-playbook-workflow` | Adapted: Codex identity; task checkpoints, team pull requests, allocation, and tag namespaces preserved. |
| 6.2 | `rules/WORKFLOW.md` | `codex-playbook-workflow` | Adapted: model ledger reports actual Codex tiers or models. |
| 6.3 | `rules/WORKFLOW.md` | `codex-playbook-workflow` | Direct: true merge, audit, exact-candidate checks, tag, push, and GitHub release. |
| 6.4 | `rules/WORKFLOW.md` | `codex-playbook-workflow` | Direct: published history never moves. |
| 7.1 | `rules/COLLABORATION.md` | `codex-playbook-collaboration` | Direct: one plan gate authorizes its full chain. |
| 7.2 | `rules/COLLABORATION.md` | `codex-playbook-collaboration` | Adapted: use Codex collaboration tools when available; autonomy and stall test preserved. |
| 7.3 | `rules/COLLABORATION.md` | `codex-playbook-collaboration` | Adapted: prose is preferred unless a higher-level client contract requires a chooser. |
| 7.4 | `rules/COLLABORATION.md` | `codex-playbook-collaboration` | Direct: fix understood local defects; escalate and persist risky or unclear ones. |
| 7.5 | `rules/COLLABORATION.md` | `codex-playbook-collaboration` | Direct: stay focused without silent scope reduction. |
| 7.6 | `rules/COLLABORATION.md` | `codex-playbook-collaboration` | Adapted: use Codex context cleanup only after full completion. |
| 7.7 | `rules/COLLABORATION.md` | `codex-playbook-collaboration` | Direct: dated handoff plus root pointer at every unfinished seam. |
| 8.1 | `rules/SUBAGENTS.md` and `rules/ROSTER.md` | `codex-playbook-subagents` and its `references/roster.md` | Adapted: capability-based, with the boundary stated — the numbered rules own the assignments, the roster reference owns tier selection, which carries no model product identifiers; operator binding outside the managed packages; escalation, load limits, and planner/coordinator split remain. |
| 9.1 | `rules/ENVIRONMENT.md` | `codex-playbook-environment` | Adapted: platform skill supplies commands; owner override uses `~/.config/fleet/ports/`. |
| 9.2 | `rules/ENVIRONMENT.md` | `codex-playbook-environment` | Direct: a Docker prefix is naming, never permission. |
| 9.3 | `rules/ENVIRONMENT.md` | `codex-playbook-environment` | Direct: native datastores require explicit direction. |
| 9.4 | `rules/ENVIRONMENT.md` | `codex-playbook-environment` | Direct: logs are never deleted and active logs are never compressed. |
| 9.5 | `rules/ENVIRONMENT.md` | `codex-playbook-environment` | Direct: secrets stay out of source, logs, transcripts, and collaboration tools. |
| 9.6 | `rules/ENVIRONMENT.md` | `codex-playbook-environment` | Direct: long-running processes are stopped or explicitly reported. |
| 10.1 | `rules/DESTRUCTIVE.md` | `codex-playbook-destructive` | Direct: destructive effect, not command spelling, controls approval. |
| 10.2 | `rules/DESTRUCTIVE.md` | `codex-playbook-destructive` | Adapted: Codex tool calls retain validate-first and destructive-action-alone semantics. |
| 10.3 | `rules/QUARANTINE.md` | `codex-playbook-quarantine` | Direct: complete file, database, notification, manifest, and lifecycle procedure. |
| 11.1 | `rules/platform/*.md` | three `codex-playbook-platform-*` skills | Adapted: all implementations install; only the execution operating system loads. |
| 12.1 | `rules/WRITING.md` | `codex-playbook-writing` | Adapted: Codex-required tool preambles remain the explicit exception. |
| 12.2 | `rules/WRITING.md` | `codex-playbook-writing` | Adapted: Codex progress/task UI may carry state when available. |
| 12.3 | `rules/WRITING.md` | `codex-playbook-writing` | Direct: plain language, expanded acronyms, meaning before labels. |
| 12.4 | `rules/WRITING.md` | `codex-playbook-writing` | Direct: mechanical pre-send check, no arbitrary list cap or invented estimates. |

## Unnumbered source contract

| Source item | Codex destination | Result |
|---|---|---|
| Five partnership principles | `AGENTS.md` | Preserved before all operational rules. |
| Independent/opinionated coda | `AGENTS.md` | Preserved within higher-level system and safety constraints. |
| Request classification | `AGENTS.md` | Preserved as always-loaded authority. |
| Complete approval table | `AGENTS.md` | Preserved as the only approval-gate list. |
| Self-update contract | `codex-playbook-self-update` | Adapted to public Codex source, transactional installer, and Codex paths. |
| Section trigger index | `AGENTS.md` | Adapted from Claude `paths:` loading to mandatory Codex skill routing. |

## Verification

`tests/rulebook_test.sh` rejects a missing, unknown, duplicate, or misplaced
rule heading; validates the declared three-platform exception; verifies every
skill's metadata and router entry; and compares the visual map and this report
to the canonical manifest.
