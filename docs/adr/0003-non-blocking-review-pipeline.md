# 0003 — The non-blocking review pipeline, ported with a capability-based roster

## Context

The source rulebook (`claude-code-playbook`) changed its review section on 2026-09-20 —
0.1.13, corrected the same day as 0.1.14 after an independent review of *this* repository's
port plan (`docs/reviews/2026-09-20-astra-pipeline-port-plan-*.md`). Reviews no longer stall
development: there are three kinds of review, the mechanics of reviewing a commit rather than
a working tree, and a new rule 3.5 bounding how far development may run ahead. The source now
has fifty rules; this repository's contract — manifest, headings, visual map and parity matrix
— pins forty-nine.

The source also moved every model name into one file, `rules/ROSTER.md`. This repository had
already gone further: its roster names capabilities and no products at all. But it kept that
roster in two copies, one in the reviews skill and one in the subagents skill, and it assigned
deep review to the same tier as implementation and mechanical review.

## Decision

1. **Rule 3.5 becomes canonical ID number fifty.** The manifest, the rule headings, the visual
   dataset and the parity matrix move together, test first. ADR 0002's "49" stays as written.
2. **Rules 3.1, 3.3 and 3.5 are ported from source 0.1.14.** Rule 3.5 is a direct port. Rule
   3.3 is adapted where Codex differs, and only there: completion is *registered and handled*
   rather than assumed to be notified; a worktree is prepared by *whoever holds the
   permission*, because command subprocesses inherit the sandbox; a reviewer that cannot write
   returns its notes through its reply and its permissions are never widened to fit the rule;
   nothing observed on another client is asserted of Codex threads.
3. **The roster stays capability-based — no product names — and gains a Strong tier.** Four
   tiers, **Top · Strong · Standard · Fast**, each a responsibility filled by a model *and* a
   reasoning effort. "Deep" is renamed "Top" so that "the Deep tier" and "a deep review" do not
   name different things. An optional second family is described by capability.
4. **The roster has one owner:** `.agents/skills/codex-playbook-subagents/references/roster.md`
   — unnumbered definitions only. The reviews skill reads it by relative path from its own
   directory, and falls back to invoking the subagents skill, never to a second copy.
5. **The operator's binding of roles to real models lives outside the managed packages**, dated,
   so an installer upgrade cannot erase it. The canonical roster names none.
6. **The mechanical-review measurement keeps its provenance.** It was taken on two Claude
   models and validates no Codex configuration; "Standard, never Fast" is carried as a
   conservative floor pending a Codex measurement.
7. **The port is one task, closing once as 0.1.4**, straight to `main` — the repository is solo;
   both GitHub accounts in its history are the owner's.

## Alternatives rejected

- **A named roster** (Codex models by product name, another family as the optional second).
  It would reverse this repository's recorded stance for nothing the capability wording plus
  a local binding does not already give. The independent reviewer reached the same view:
  names belong in the operator's binding and in evidence, not in canonical policy.
- **A seventeenth skill for the roster.** "Sixteen skills" is pinned in about seventeen places,
  including an ADR that cannot be edited. The installer already copies whole skill
  directories, so a bundled reference file changes no install, restore or inventory contract.
- **Leaving the roster duplicated** and adding a row to each copy. Two copies drift.
- **Porting 0.1.13 as it stood.** Its rule 3.5 double-counted merges and did not say what its
  ceiling counted. The source was corrected first so this port is direct, not a private fork.
- **Two review slots including the batch being built** — the independent reviewer's preference.
  The owner chose the source's reading (two closed batches plus the one being built, worst case
  three ranges) because a stricter ceiling turns any slow review into a halted line.

## Consequences

- The reviews skill roughly doubles in length. It loads on demand, when a reviewer is being
  dispatched. If that proves too heavy, the mechanics move to a bundled reference the same way
  the roster did.
- A cross-skill relative reference is new in this repository. Install, upgrade, rollback and
  restore tests cover the nested file; one fresh-session load from an unrelated directory is
  part of acceptance; whether every Codex client follows such a reference stays unverified
  beyond that check.
- Parity is now against source 0.1.14 for section 3 and the roster wording of rule 8.1, and
  against the earlier source for everything else; the parity matrix says which rows moved.
- The ceiling of two rests on one friendly programme in the source's evidence. Close-outs
  record how often a line reached it.

## Status

Accepted — 2026-09-20. Amends the count in ADR 0002 (49 → 50 rules) without editing it.
