# Progress

**Current version:** 0.1.6

**Last updated:** 2026-09-23

**Current hold:** independent review of `43a5580` failed on two path-resolution
gaps and installer rollback compatibility. The current unpublished worktree
repairs them with red-to-green lifecycle tests and preserves deliberate
restore's strict router check. It also carries approved task-continuity,
communication/Herdr, hygiene, and GPT-6 guidance. No tag or push follows from
passing local tests alone; focused review is still required.

The pinned `01c6e9a` re-review found a source-checkout path ambiguity. A
newline-bearing checkout could be mistaken for its sibling by shell command
substitution. Install and restore now validate their own invocation path before
resolving the checkout root. The current local change has red-to-green tests;
the next full run and GPT-6 Sol re-review remain publication gates.

The canonical repository is now `michelabboud/codex-playbook`.
`nice-michel/codex-playbook` is its fork for branches and pull requests, while
the former standalone repository is preserved at
`nice-michel/codex-playbook-archive`.

**0.1.6 (2026-09-21, held until published):** customizations now live in one local
file the playbook never ships and no script writes to —
`${CODEX_HOME:-$HOME/.codex}/playbook-local.md`; install and restore read it
only to check compatibility with the incoming managed text.
`AGENTS.md` gives it its force in a paragraph headed "The local layer" and every
skill's body opens with one pointer line at it, because a skill loads long after
the session began. `scripts/check-local.sh` reads every `**Dead words:**` entry
and searches the named file for each quoted phrase as a fixed string; the
installer runs it in source preflight — before `umask`, before any directory is
created, before any backup — against the text that run would install, and a
stale, unparsable, or escaping entry refuses the installation with no flag to
pass it. Restore also checks the preserved local file against its checkpoint
before changing managed destinations, and refuses a checkpoint whose router
would not load it. Neither script writes the local file. `templates/playbook-local.md`
carries the grammar and a worked example of each kind and is documentation, never
installed — and it ships with **no entry in force**, its examples inert inside a
fenced code block.

**The batch's mechanical review failed it**, with one blocking finding: a
`**Dead words:**` marker that was not at the start of its line was skipped in
silence, so a stale override installed while the check reported that every
override still matched. All five findings were confirmed and all five are
repaired: the parser now scans each line left to right over its code spans and
**fails closed** — the bare marker anywhere but the start of a line is an error,
a fenced code block is ignored, a fence left open is an error, a line is bounded
at 4,096 bytes, and a run that checked nothing says so rather than claiming that
every override matches. The 47 conformance vectors both editions carry,
byte-identical, are now run by the suite and the fixture's SHA-256 is pinned.

**Then the sibling edition's own mechanical review found five more things that
applied here too**, and they were ruled for both editions and fixed before
publication rather than after. An **Override with no Dead-words line** used to
exit 0 having checked nothing, so every way of mistyping the marker was a silent
pass; it is now an error reported at the Override's line, and the ruling caught
three live entry lines in this repository's own template. A **local layer that
could not be read** used to be reported as no local layer at all, because POSIX
`test` cannot tell "not there" from "cannot look"; absence is now proved by
walking the directories above the file. A **glob character in a file name** is now
refused as a rule rather than by the accident of no such file existing, and the
script runs under `set -f`. The claim that the playbook `never opens` the local
file is **replaced everywhere** by what is true — never shipped, never written,
read once to be checked — and a sweep in the suite fails on the old phrasing.
And **five ways the check could fail open each gained an assertion**, every one
written against the mutation that exposed it and proven to die on it. The suites
now run 56 rulebook checks, 217 local-layer assertions, and
403 installer lifecycle assertions. **Unverified:** no fresh Codex session has yet
been observed reading the local file at session start on this client — the
mechanism is a sentence in `AGENTS.md` plus a pointer per skill, not anything the
client enforces; and the scripts were executed under GNU coreutils and `dash`
only, with BusyBox and BSD userlands assessed rather than run.

**Focused diagnostic, 2026-09-23:** the repair at `358ab65` still failed. A
historical checkpoint could leave the local file unread even when its Override
quote and section digest matched; a BOM could hide an entry; CRLF heading
counting and overlapping-quote uniqueness disagreed with ADR 0006. Findings
and evidence are in
`docs/reviews/2026-09-23-local-layer-focused-diagnostic.md`. Local repair and
regressions are built and verified, but a pinned focused deep re-review and the
original review obligations remain owed. No `checkpoint/0.1.6` tag or push has
been made.

**Compatibility repair, 2026-09-23:** the owner approved refusing local-file
symlinks that resolve inside managed destinations, preserving external
dotfile-manager symlinks, and requiring a known complete active router for
restore. Lifecycle regressions were red before repair and pass locally; no
publication follows until focused review and the batch gates pass.

**0.1.5 (2026-09-20):** the rule 3.5 wording contract now requires its positive phrases inside
rule 3.5 itself while retaining the whole-skill sweep for superseded wording. The rulebook suite
now runs 52 checks; rulebook and installer behaviour are unchanged.

**0.1.4 (2026-09-20, published after its review passed):** the non-blocking review pipeline is ported
from source 0.1.15, making rule 3.5 the fiftieth rule. The first candidate of
this change was given a deep review before publication and **failed it** — eight
findings, all confirmed, six blocking — so the source was corrected again and
the port follows it: the ceiling is one invariant (a line carries at most three
unruled batches, the open one included) and rule 3.5 now carries a normative
table of twenty worked cases that wins over its own prose. A re-review
of the repair failed it once more before publication — the admission could be
granted twice on one count, and the installer preflight had three gaps; both are
repaired and recorded in
docs/reviews/2026-09-20-sol-0.1.4-re-review-validation.md. A third review passed
the installer and the tests and failed rule 3.5 on two more omitted states; the
owner chose to restate the ceiling rather than patch it again
(docs/reviews/2026-09-20-sol-0.1.4-third-review-validation.md). A fourth review
failed the restatement on what it had newly created — unplanned work had no
batch, fixes owed no review, an open line could be merged — and the rule now
resolves anything it does not name toward review
(docs/reviews/2026-09-20-sol-0.1.4-fourth-review-validation.md). Rules 3.1,
3.3 and 3.4 moved to the source's wording, rule 8.1's tier selection now has a
single owner in
`.agents/skills/codex-playbook-subagents/references/roster.md` with the
boundary stated — rules own the assignments, the roster owns the selection — and
`config/managed-resources.txt` makes the installer refuse an incomplete source
before any backup or destination write. The installer lifecycle tests cover that
nested file through install, upgrade, rollback, restore, and seven refusals of
an unsafe or incomplete source.
The rulebook contract test covers 50 canonical rule IDs and the installer suite
runs 340 assertions. **Unverified:** whether every Codex client follows a
relative reference from the reviews skill into the subagents skill's directory
(the fresh-session load is still owed); what context isolation real reviewer
launches provide on this client; the Codex behaviour of the "Standard, never
Fast" mechanical-review floor, which was measured on two Claude models; and the
ceiling, which rests on one refactor programme. The repaired candidate's
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
