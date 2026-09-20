# 0004 — The port repaired after its deep review: admission rule, worked cases, an installer preflight

## Context

ADR 0003 recorded the port of the non-blocking review pipeline. The first candidate
(`2cee956`) was given a deep review before publication — another model family, a separate
process, pinned base and target, a cold-read note first
(`docs/reviews/2026-09-20-sol-0.1.4-deep-review*.md`). Verdict: FAIL. Six blocking findings and
two minor, all confirmed. Four blockers were in the source rule and had been ported faithfully;
two were this port's own. The candidate was never pushed.

## Decision

1. **The source was corrected first again, and the port follows it (source 0.1.15).** The
   ceiling is an admission rule — a new batch starts only while at most two closed batches are
   unruled — and rule 3.5 carries a normative table of twelve worked cases that wins over the
   prose. A pending mechanical review never delays the next reversible task; a returned blocker
   stops the line. Reviewer isolation is scoped to what the reviewer can reach. This amends
   ADR 0003's description of the ceiling.
2. **The installer gains a preflight for nested files — reversing ADR 0003's "no install
   contract changes".** `config/managed-resources.txt` lists the nested files an installation
   depends on; the installer refuses, before any backup or destination write, when one is missing
   or is not a regular file. ADR 0003 reasoned that whole-directory copying made the bundled
   roster free. It made *copying* free; it also copied an absence faithfully, producing an
   installed skill that points at nothing.
3. **The accounting contract is the worked-cases table, asserted row by row** — not keywords.
   The keyword assertions passed while the ceiling was wrong at its boundary; that is the proof
   they were inadequate. Independent semantic review remains, because no fixture proves how an
   agent will read prose.
4. **The ownership boundary is stated:** numbered rules own assignments (which tier does which
   work, which review runs where); the roster reference owns selection (what each tier is), the
   optional second family, the binding and the evidence. The roster's "trusted with" column and
   its kinds-of-review table are removed, and the test is named for the structural property it
   actually checks.
5. **"No product names" is narrowed to what is true:** no model product identifiers in the tier
   assignments. The roster names Codex and Claude where that is the fact being recorded — a
   client's settings, a measurement's provenance.

## Alternatives rejected

- **"Batch N+2 may be built but may not close"** — the reviewer's repair of the ceiling. It
  keeps the words "two closed" by redefining "closed"; the code is unreviewed either way.
- **Hard-coding the roster path in the installer.** An inventory matches how this repository
  already manages skills, and the next nested file costs one line.
- **Keeping keyword assertions and adding more keywords.** Same failure, more words.

## Consequences

- One more inventory file, validated by the rulebook tests and consumed by the installer.
- A fresh-session load of the installed roster is still owed; it needs a real Codex home and
  the owner's word, and is logged in `BACKLOG.md`.

## Status

Accepted — 2026-09-20. Amends ADR 0003 (its ceiling wording, its "direct port of 0.1.14", its
"no install contract changes", its "no product names") without editing it.
