# The roster — definitions for rules 3.1–3.5 and 8.1

*One owner. `codex-playbook-subagents` reads this file from its own `references/` directory;
`codex-playbook-reviews` reads it by relative path from its own directory. It holds definitions
only — never a numbered rule, never authority, never procedure. **No product names live here:**
model names change several times a year, so the law names responsibilities, and the operator
binds them to what the runtime actually offers (see "The binding", below).*

## Tiers — what a configuration is trusted with

A tier is a **responsibility**, filled by a *configuration*: a model **and** a reasoning effort.
Codex treats the two as separate settings, so the binding records both.

| Tier | Selection | Trusted with |
|---|---|---|
| **Top** | the strongest available reasoning configuration | Planning, design, architecture, hard reasoning, and **high deep** review. Never down-tiered. |
| **Strong** | a strong reasoning configuration, genuinely above Standard | **Deep** review. The escalation step between Standard and Top. |
| **Standard** | a reliable general configuration at sufficient reasoning effort | Multi-file implementation, integration work, and **every mechanical review**. |
| **Fast** | the fastest configuration demonstrably capable of the exact task | Mechanical, fully-specified work that is *not* review: renames, formatting, single-file edits to spec, doc transforms. |

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

## Kinds of review — what each one closes, and who runs it

| Kind | Closes | Runs on | While it runs, development… |
|---|---|---|---|
| **Mechanical** | a task | Standard — never Fast (see the measurement) | never waits |
| **Deep** | a batch; or a single task in a risk class (rule 3.2) | Strong | keeps going, up to the ceiling (rule 3.5) |
| **High deep** | a milestone; a release | Top, two independent passes | waits (rule 3.5) |

A kind of review is defined by **what it closes**, never by the configuration that runs it today.

## The binding — yours, dated, and outside the managed packages

The tiers are law; a dispatch needs a name. Keep a dated binding of each role to a model
identifier and an effort — with the settings the runtime reports back, if it exposes them, and
one line of rationale — **outside the managed skill packages**, so an installer upgrade cannot
erase it: your personal global `AGENTS.md` notes or a file beside them. Review headers and
close-out ledgers quote the binding that was actually used. Re-examine it whenever the runtime's
model list changes; a binding older than a few months is a claim, not a fact.

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
