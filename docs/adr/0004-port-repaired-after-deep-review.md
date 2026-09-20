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

## Completed before publication — after the re-review (2026-09-20)

This record was never published in its first form. A re-review of the repair failed it again
(`docs/reviews/2026-09-20-sol-0.1.4-re-review-validation.md`), and the decision is completed
here rather than in a fifth record for the same change:

- **Rule 3.5, following the source:** one batch is open per line at a time; a batch starts at
  the first dispatch of a task the plan allocates to it; admission is checked again when it
  closes. At three, the line accepts only the fixes that rule a batch. The table has sixteen
  rows, not twelve.
- **The preflight refuses any symlink inside an active skill's source directory**, not only a
  symlinked leaf: `cp -pR` preserves links, git stores them, and an installed skill must not
  resolve a rulebook file outside its package. Every listed resource's owning skill must be an
  active skill. The inventory is iterated the way the script iterates its other inventories,
  so an unterminated last line is read.
- **The worked-cases test compares the table row for row against a canonical copy under
  `tests/`.** One phrase per row passed a row that also said the opposite. Rejected: generating
  the rule and its carriers from one dataset — a build step for a rulebook whose contract is
  that the Markdown *is* the source.

**Restated, still before publication, after the third review and at the owner's choice.** The
ceiling is one invariant, enforced at admission: *a line carries at most three unruled batches,
the open one included.* A batch is unruled from its first dispatch; closing pins the review
target, freezes membership and changes the batch's state, never the count; only a ruling brings
the count down; nothing lands on a line outside a batch. Every defect since the first review had
sat between closed batches, which the rule counted, and open work, which admission, branching
and merging act on. Rejected: rows 17–18 for the two newest states; a short ceiling that ends in
"ask the coordinator". The installer also refuses a symbolic link at `.agents` or
`.agents/skills`. Records: `docs/reviews/2026-09-20-sol-0.1.4-third-review-validation.md`.

## Consequences

- One more inventory file, validated by the rulebook tests and consumed by the installer.
- A fresh-session load of the installed roster is still owed; it needs a real Codex home and
  the owner's word, and is logged in `BACKLOG.md`.

## Status

Accepted — 2026-09-20. Amends ADR 0003 (its ceiling wording, its "direct port of 0.1.14", its
"no install contract changes", its "no product names") without editing it.
