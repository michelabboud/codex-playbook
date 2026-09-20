# Progress

**Current version:** 0.1.4

**Last updated:** 2026-09-20

The canonical repository is now `michelabboud/codex-playbook`.
`nice-michel/codex-playbook` is its fork for branches and pull requests, while
the former standalone repository is preserved at
`nice-michel/codex-playbook-archive`.

**0.1.4 (2026-09-20, in review):** the non-blocking review pipeline is ported
from source 0.1.15, making rule 3.5 the fiftieth rule. The first candidate of
this change was given a deep review before publication and **failed it** — eight
findings, all confirmed, six blocking — so the source was corrected again and
the port follows it: the ceiling is an admission rule (a new batch starts only
while at most two closed batches are unruled) and rule 3.5 now carries a
normative table of sixteen worked cases that wins over its own prose. A re-review
of the repair failed it once more before publication — the admission could be
granted twice on one count, and the installer preflight had three gaps; both are
repaired and recorded in
docs/reviews/2026-09-20-sol-0.1.4-re-review-validation.md. Rules 3.1,
3.3 and 3.4 moved to the source's wording, rule 8.1's tier selection now has a
single owner in
`.agents/skills/codex-playbook-subagents/references/roster.md` with the
boundary stated — rules own the assignments, the roster owns the selection — and
`config/managed-resources.txt` makes the installer refuse an incomplete source
before any backup or destination write. The installer lifecycle tests cover that
nested file through install, upgrade, rollback, restore, and the two refusals.
The rulebook contract test covers 50 canonical rule IDs and the installer suite
runs 333 assertions. **Unverified:** whether every Codex client follows a
relative reference from the reviews skill into the subagents skill's directory
(the fresh-session load is still owed); what context isolation real reviewer
launches provide on this client; the Codex behaviour of the "Standard, never
Fast" mechanical-review floor, which was measured on two Claude models; and the
ceiling of two, which rests on one refactor programme. The repaired candidate's
own review has not yet run and the checkpoint tag is not yet pushed.

Phase 2 rebuilt the first public version as a faithful Codex adaptation of all
49 Claude Code Playbook rules. A lean global router now loads sixteen subject
skills on demand, while manifests keep rule ownership, installation,
restoration, documentation, and the visual playbook synchronized. Pull request
[`#2`](https://github.com/michelabboud/codex-playbook/pull/2) merged that work
into the canonical repository.

**Completed:** a follow-up corrects the visual omission of the five partnership
principles and protects them with a 44th rulebook contract check. The complete
suite still covers 269 isolated installer and restore lifecycle assertions.
Desktop and mobile browser verification covers the mantra layout, navigation,
overflow, reduced motion, and console output.
