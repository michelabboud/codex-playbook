# Handoff

**Published source, 2026-09-23:** remote `main` and the peeled annotated
`checkpoint/0.1.6` tag both resolve to `a5d41bc46e9ef7f9fba58d041ebc10623306dfac`.
The exact tagged tree passed 56 rulebook checks, 217 local-layer assertions,
and 673 installer lifecycle assertions with direct exit 0. Managed and
executable text remained unchanged from reviewed `267dfb5`. This is source
publication only: no live installation, private-rule sync, native macOS
acceptance, evidence cleanup, or other-repository change was performed. See
`docs/reports/2026-09-23-local-layer-publication-receipt.md`. The remaining
text is historical review and pre-publication handoff material.

---

**Publication gate, 2026-09-23:** the current candidate is committed and clean.
The GPT-6 Sol mechanical review passed at `fd2443f`, and its deep review's
symlink-chain blocker was repaired and passed a focused GPT-6 Sol re-review at
`267dfb5`. The later `2dcfd5a` commit changed only status documents and the
review record. Claude's `checkpoint/0.1.16` is now published at `97938d0`;
its remote `main` and peeled tag were checked directly. Run this edition's
full verification on the final administrative candidate, compare executable
and managed text with `267dfb5`, then tag and push `checkpoint/0.1.6` and
verify its remote refs. No live installation or native macOS acceptance is
claimed. The text below is historical seam tape, not the current hold.

---

**Held: 0.1.6, the local layer, is built, reviewed twice over, repaired, and not
published.** The five tasks of `docs/plans/2026-09-21-local-layer-plan.md` are
complete. Two rounds of repair sit uncommitted in this lane's worktree.

The first round answered this edition's own mechanical review, which failed the
batch on one blocking finding: a `**Dead words:**` marker that was not at the
start of its line was skipped in silence, so a stale override could install.

The second round answers **the sibling edition's** mechanical review, whose
findings applied here too and were ruled for both editions before publication.
Five rulings, all implemented and tested in this worktree:

1. An **Override with no valid Dead-words line** before the next entry line, the
   next heading, or the end of the file is now exit 2 at the Override's own line
   — so a mistyped marker is a refusal, not a silent pass. The same ruling found
   three live entry lines in `templates/playbook-local.md`, which described the
   three kinds *in the shape of* an entry; the template is reworded and its test
   now refuses any unfenced entry line, not only an unfenced Dead-words line.
2. The claim that the playbook `never opens` the local file is **replaced
   everywhere** with what is true — never shipped, never written, read once only
   to check it — in `AGENTS.md`, `README.md`, `ARCHITECTURE.md`, `INSTALL.md`,
   `CONTRIBUTING.md`, `PROGRESS.md`, `CHANGELOG.md`, the template,
   `codex-playbook-self-update`, and the landing page. A sweep in
   `tests/rulebook_test.sh` fails on the old phrasing anywhere the public reads,
   and distinguishes a claim from a citation in a code span.
3. The 4,096-byte line bound already met the shared ruling; this edition applies
   it to every line, which is stricter, and it was already tested at the bound
   and one byte over.
4. A **local file that exists and cannot be read** is exit 2. The unreadable
   file, the directory and the dangling symlink were already refused; the hole
   was a local layer behind a directory nobody may search, which passed as
   "nothing is customized". Absence is now proved by walking the directories
   above the file.
5. A **glob character in a named file** is exit 2 in its own right, and the
   script runs under `set -f`. Before, such a name was refused only because no
   file of that literal name happened to exist.

The reviewer's five fail-open mutants were rebuilt against this script; all five
die, and three more mutants of this round's own code die too. Evidence, mutant by
mutant with the assertion that kills each: `LANE-B3-REPORT.md`.

`./scripts/verify.sh` exits 0. The suites run **56** rulebook checks, **193**
local-layer assertions and **383** installer lifecycle assertions.

Three things are owed before anything is pushed: a focused mechanical re-check of
this second repair, the deep reviews the plan requires (tasks 2 and 3 at task
grain, then the batch), and the Claude edition's `checkpoint/0.1.16`, which must
exist first — its highest published tag today is `checkpoint/0.1.15`, and the
source commits the parity matrix cites are themselves unpublished.

Nothing is left running. Nothing is committed: git was read-only for this lane.
Current state and verification evidence are in `PROGRESS.md`,
`LANE-B2-REPORT.md` and `LANE-B3-REPORT.md`; the review and its validation are
`docs/reviews/2026-09-21-local-layer-mechanical-review.md` and
`…-validation.md`.
