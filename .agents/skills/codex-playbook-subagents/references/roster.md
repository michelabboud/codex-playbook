# The roster — definitions for rules 3.1–3.5 and 8.1

*One owner. `codex-playbook-subagents` reads this file from its own `references/` directory;
`codex-playbook-reviews` reads it by relative path from its own directory. It holds definitions
only — never a numbered rule, never authority, never procedure.*

***The boundary.** Numbered rules own the **assignments**: which tier does which work (rule 8.1)
and which review runs on which tier (rule 3.1). This file owns the **selection** — what makes a
configuration a Top, a Strong, a Standard or a Fast one — the optional second family, the
operator's binding, and the evidence. It does not restate who does what.*

***No model product identifiers in the tier assignments.** Model names change several times a
year, so the tiers are defined by capability and the operator binds them to what the runtime
actually offers ("The binding", below). Clients and model families are named here only where
that is the fact being recorded — Codex's settings, and the provenance of a measurement.*

## Tiers — how a configuration is selected

A tier is a **responsibility**, filled by a *configuration*: a model **and** a reasoning effort.
Codex treats the two as separate settings, so the binding records both.

| Tier | Selection |
|---|---|
| **Top** | the strongest available reasoning configuration |
| **Strong** | a strong reasoning configuration, genuinely above Standard |
| **Standard** | a reliable general configuration at sufficient reasoning effort |
| **Fast** | the fastest configuration demonstrably capable of the exact task |

What each tier is trusted with is rule 8.1; which review each tier runs is rule 3.1.

**Escalation ladder:** Fast → Standard → Strong → Top, one tier at a time (rule 8.1) — always to
the next *genuinely stronger* configuration. Strong and Top may be two models, or one model at
two efforts, or — when the roster is small — the same strongest configuration filling both
roles. Never invent a weaker assignment to populate a row, and never relabel an identical rerun
as an escalation: when nothing stronger exists, report that the ceiling has been reached.

**Optional second family.** Where a model of *another family* at the matching tier is genuinely
reachable — through another coding CLI or a dispatcher — it is the second reviewer of a
dual-blind pair, because two instances of one model share the same blind spots. It is optional.
Where none is reachable, the pair is two **fresh same-family sessions**, and the review header
records that limitation; where even that is unavailable, report the missing gate rather than
silently substituting.

## Economy mode — code review only (rule 3.1)

When the owner switches economy mode on, each **Top-tier review seat** is filled by the **economy configuration**: the Strong tier's model at the highest reasoning effort the runtime offers — one per model family, so a dual-blind pair stays cross-family where a second family is reachable. The planning seat is not affected. A configuration is a model **and** an effort: the Strong model at its default effort is not the economy configuration. The economy reviewers are fresh sessions, never the deep reviewers of the same batch. Your binding (below) names the economy configuration beside the tiers.

## The binding — yours, dated, and outside the managed packages

The tiers are law; a dispatch needs a name. Keep a dated binding of each role to a model
identifier and an effort — with the settings the runtime reports back, if it exposes them, and
one line of rationale — **outside the managed skill packages**, so an installer upgrade cannot
erase it: your personal global `AGENTS.md` notes or a file beside them. Review headers and
close-out ledgers quote the binding that was actually used. The binding also names the economy configuration, one per family, when economy mode is available. Re-examine it whenever the runtime's
model list changes; a binding older than a few months is a claim, not a fact.

## The mechanical review seat — which configurations qualify (rule 3.1)

The Standard tier always qualifies. A **Fast** configuration qualifies only when the owner admits
it to the seat **and** a comparison on that exact configuration is recorded below, with its date
and its limits; the binding then names it beside the Standard tier. Until a broader comparison is
recorded, a mechanical review run on an admitted Fast configuration says so in its header. Being
admitted to the seat does not move a configuration up a tier.

## The measurement behind the mechanical-review floor — and what it does not show

In the source rulebook's benchmark (September 2026), two **Claude** models — its Fast and its
Standard tier — received an identical mechanical-review brief over one file containing nine
real defects. The Fast-tier model found five, with zero false positives; the Standard-tier
model found all nine, a strict superset. The misses were not exotic: an unenforced input limit,
and a documentation/code mismatch — both inside the classes the brief named.

**That measurement belongs to the models it was taken on. It validates no Codex
configuration.** "Mechanical review runs on Standard, never Fast" is carried here as a
conservative policy floor, pending a comparative measurement on the configurations you
actually bind. Reasoning effort alone is not evidence of greater accuracy or of independent
failure modes. When you take that measurement, record it here with its date and the exact
configurations.

**Claude Haiku 5.5, admitted by the owner on 2026-10-10.** A first comparison the same day, at
effort `high` against GPT-6 Luna at `high`: on a 175-line file with ten seeded defects and three
decoys, Haiku 5.5 found all ten in both runs and reported no decoy; on a real 446-line file it
found the one known subtle defect in both runs, plus eight or nine further real defects per run
against two or three for Luna. Limits: two runs, one hard file, not blind — its author wrote the
fixtures and judged the answers — and Luna ran at `high`, not `max`. Earlier Haiku models remain
unqualified, and so does GPT-6 Luna until it passes the nine-defect comparison.
