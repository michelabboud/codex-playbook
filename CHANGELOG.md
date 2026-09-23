# Changelog

## Unreleased

- Coordinate approved plans with scoped subagents when available, record task
  ownership/communication and continue automatically to the next admitted task.
  Document native Codex, OpenAI API, and conditional Herdr communication modes.
- Clarify the GPT-6 family map: Astra is flagship, Sol is the strong value
  workhorse, Luna is light, and no GPT-6 Terra exists. Label short-context
  prices and long-context caveats without lowering review requirements.
- Repair review-found install safety gaps: reject ambiguous HOME and symlink
  target path encodings, and recover interrupted installation from exact
  originals without weakening deliberate restore's router check.
- Reject newline-bearing checkout source paths before resolving the installer
  or restore script's repository root; prevent sibling-checkout confusion.
- Reject local-file symlink chains that traverse a managed destination being
  replaced, even when their final content target is external.
- Run a safe hygiene checkpoint after tasks, phases, and plans: measure disk and
  resources, verify worktree/feature-branch and generated-debug provenance
  before cleanup, and preserve logs, reports, and documents. Rotate and
  compress only inactive logs; deletion requires explicit consent. Logs are
  gitignored by default, while reports, documents, and guides are committed.
- Add dated, non-installed GPT-6 Astra/Sol/Luna operator guidance with current API
  token prices and explicit quality-measurement caveats. Managed tier selection
  remains capability-based, and the Standard review floor is unchanged.
- Install and restore refuse a local-file symlink into a managed destination
  before mutation while preserving external dotfile-manager symlinks. Restore
  accepts only a checkpoint with the complete known active router, not a
  paragraph matching inside a fenced example.
- Harden local Overrides: every live Override now binds to one unique Markdown
  section, its normalized SHA-256 digest, and a unique quote of at least 16
  non-whitespace bytes. Ambiguous or incomplete evidence refuses installation.
- Restore now refuses a checkpoint whose global router would leave a preserved
  local file unread, including a Fill-only file with no quoted Override. The
  checker refuses a UTF-8 BOM, counts overlapping quotes as ambiguous, and
  normalizes CRLF before counting anchored headings.
- Restore refuses a global `AGENTS.override.md` that would shadow the router
  and deactivate the preserved local layer, before creating a pre-restore
  checkpoint or changing any destination.
- The local-layer checker rejects split-bold and Unicode-lookalike entry
  markers instead of silently treating them as ordinary prose.

All notable changes are recorded here. Dates are absolute.

## 0.1.6 — 2026-09-21

### Added

- **The local layer: customizations live in one file the playbook never ships
  and no script writes to** — `${CODEX_HOME:-$HOME/.codex}/playbook-local.md`.
  `scripts/install.sh` and `scripts/restore.sh` never create, write to, copy
  over, move, or delete it. Installation does **read** it, once, in source
  preflight, to check it, and has no other contact with it at all. Decision:
  `docs/adr/0005-the-local-layer.md`; source, `claude-code-playbook` ADR 0004.
- **`AGENTS.md` gives it its force**, in a paragraph headed "The local layer":
  read the file at the start of a session when it exists, and where an entry
  there changes a rule, the entry wins over the playbook's wording. An entry is
  a **Fill**, an **Add** under its own `L1`, `L2` sections, or an **Override**
  quoting after `**Dead words:**` the playbook's exact words that no longer
  apply, each with the file they are in. An absent file means nothing is
  customized. The local layer cannot expand authority, remove an approval, or
  weaken the security and destructive-action boundary.
- **One pointer line opens the body of every managed skill**, because a skill
  loads long after the session began and cannot rely on the session-start read.
- **`scripts/check-local.sh`** — POSIX `sh`, no new dependency. It scans every
  `**Dead words:**` line left to right over its code spans, never splitting on
  the separator, and searches each named file for each quoted phrase as a fixed
  string. Exit 0 fresh, or no local file; exit 1 stale, each finding reported as
  `file:line` with the words and where they were sought; exit 2 for a usage
  error, an unparsable line, a bare marker that is not at the start of its line,
  an **Override** entry with no valid Dead-words line before the next entry line,
  the next heading, or the end of the file, a line longer than 4,096 bytes, a
  fenced code block left open at the end of the file, a named file that carries a
  glob character, does not exist, is not a regular file, or escapes its two roots
  through an absolute path, a `..` component, or a symbolic link, or a local file
  that exists and cannot be read as a regular file — including one behind a
  directory nobody may search, which is never reported as an absent file.
- **The installer runs that check in source preflight** — before `umask`, before
  any directory is created, before any backup — against the text the run would
  install, not the text already installed. Non-zero refuses the installation and
  there is no flag to pass it. Neither installer nor restore writes the local
  file; restore reads it to check compatibility with its checkpoint.
- **`templates/playbook-local.md`** — the grammar of a Dead-words line and a
  worked example of each kind. It is documentation: no inventory names it and
  the installer never copies it. **It ships with no entry in force:** every
  example sits inside a fenced code block, which the check ignores, so the
  reader who copies the file whole is bound by nothing. `tests/rulebook_test.sh`
  requires the template to check zero items as shipped and to carry **no entry
  line at all** outside a fence — not merely no Dead-words line: a line that
  begins, after any indentation and an optional bullet, with `**Fill`, `**Add` or
  `**Override` is an entry, so the template writes *about* the three kinds in
  another shape.
- **`tests/check_local_test.sh`** — 215 assertions covering fresh, stale, one
  file of two gone, unparsable lines, a missing named file, each path escape,
  words beginning with a dash, regex metacharacters searched literally, a quoted
  phrase containing the item separator, a backslash inside the quoted words, CRLF
  line endings, an unterminated last line, the usage errors, the bare marker in
  every shape a person writes it — including after the last code span of a line —
  an Override without its Dead-words line in each of six shapes, a glob character
  in a named file, a named file that cannot be searched, a local file that cannot
  be read, fenced code blocks including a tilde fence, a longer fence and one
  left open, the line-length bound, BOM refusal, CRLF section headings,
  overlapping quotes, and all 47 shared conformance vectors.
- **`tests/fixtures/dead-words-vectors.tsv`** — 47 conformance vectors for the
  Dead-words grammar, carried byte-identical by both editions and run by both.
  The test pins the file's SHA-256, so an edit on either side is a failing test
  rather than a quiet divergence.

### Changed

- The self-update sentence of `AGENTS.md` no longer speaks of replacing tailored
  rules. Tailoring belongs in the local layer; an update replaces every managed
  file wholesale.
- `codex-playbook-self-update` runs the check before proposing a replacement,
  reports each stale entry by `file:line` rather than silencing it, cross-checks
  the changelog for overridden rules whose meaning moved without their quoted
  sentence moving, and carries the migration for tailoring still living inside a
  managed file.
- `INSTALL.md`'s migration step now diffs the installed files against **the
  version the installation records**, checked out beside this one in a scratch
  worktree, instead of against the current checkout — which mixed the owner's
  tailoring together with everything the playbook itself changed since. Its
  template copy is guarded explicitly and says in so many words that no command
  in the guide ever copies over an existing local layer, and the restore section
  now states that a checkpoint never contains the local file, so nothing can be
  rolled back over it.
- `INSTALL.md` gains "Make it yours: the local layer", a rewritten update
  procedure that checks before it installs, and a migration section. `README.md`
  gains "Make it yours"; `ARCHITECTURE.md` gains the local-layer boundary and
  the limit of the check; `CONTRIBUTING.md` records that rewording a rule can
  invalidate an installed user's Override, which is the check working.

### Fixed

The five entries below come from the mechanical review of the sibling edition's
local layer, whose findings applied here too. They were ruled for both editions
before publication, so 0.1.6 ships with them rather than fixing them later.

- **An Override with no Dead-words line exited 0, having checked nothing** — so
  every way of mistyping the marker (`**dead words:**` in lower case,
  `**Dead words**:` with the colon outside the bold, a bare `Dead words:`) read as
  ordinary prose and the override installed unchecked. An Override entry with no
  valid Dead-words line before the next entry line, the next heading, or the end
  of the file is now exit 2, reported at the Override's own `file:line`. An entry
  line is one that begins, after any indentation and an optional `- ` or `* `
  bullet, with `**Fill`, `**Add` or `**Override`; a Fill and an Add owe no such
  line, a Dead-words line that stands alone is still parsed and searched, and an
  Override inside a fenced code block owes nothing because it is not an entry.
  The same ruling found three live entry lines in this repository's own template,
  which described the three kinds *in the shape of* an entry; they are reworded
  and the template test now refuses any unfenced entry line.
- **A local layer that could not be read was reported as no local layer at all.**
  POSIX `test` cannot tell "the file is not there" from "I cannot look": `[ ! -e
  FILE ]` is false for both. A local file inside a directory nobody may search
  therefore passed as "nothing is customized", exit 0, with the user's overrides
  entirely unchecked. Absence is now **proved** rather than assumed — every
  directory above the file is walked from the top, and one that exists and cannot
  be searched is exit 2, as is an ancestor that is not a directory. An unreadable
  regular file and a dangling symbolic link were already refused; a symbolic link
  to a readable regular file is still read, for the dotfile managers.
- **A file name may not contain a glob character.** `*`, `?` and `[` in a named
  file are now exit 2 in their own right. Before, such a name was refused only
  because no file of that literal name happened to exist — an accident of the
  filesystem rather than a rule, and a file whose real name carried a star was
  reachable through the grammar. The script also runs under `set -f`, so no future
  edit can expand a name against the current directory whatever quoting it
  forgets.
- **The claim that the playbook `never opens` the local file was untrue, and it
  was written into law.** `scripts/check-local.sh` reads it; reading it is the entire point of the
  check. `AGENTS.md`, `README.md`, `ARCHITECTURE.md`, `INSTALL.md`,
  `CONTRIBUTING.md`, `PROGRESS.md`, the template, `codex-playbook-self-update` and
  the landing page now say what is true: the playbook never *ships* it, and
  installation and restore never create, write to, copy over, move or delete it —
  installation reads it once, to check it, and that is the only way it touches it.
  A sweep in `tests/rulebook_test.sh` fails on the untrue phrasing anywhere the
  public reads, and the `AGENTS.md` wording test pins the true sentences.
- **Five ways the check could fail open now each have an assertion**, written
  against the mutation that exposed it and proven to die on it: an unterminated
  last line that is never read; quoted words truncated at the first ` · ` and
  found as a prefix; a bare marker hidden after the last code span of a line;
  `read` without `-r` eating a backslash inside the quoted words; and a search
  that could not run (`grep` exiting 2 or more) reported as a match.

- **A `**Dead words:**` marker that was not at the start of its line was
  skipped in silence** — so an entry written in the natural Markdown shape, on
  the same line as the Override it belongs to or after a list bullet, was never
  parsed, and the check reported "0 items checked; every override still
  matches" and let the installation proceed with a stale override in place. The
  blocking finding of the mechanical review of 2026-09-21
  (`docs/reviews/2026-09-21-local-layer-mechanical-review.md`, finding 1). The
  bare marker anywhere other than the start of a line is now exit 2; prose that
  names the marker puts it inside a code span; and a run that checked nothing
  says so instead of claiming that every override matches.
- **The grammar now matches the Claude edition's, and every shared vector runs.**
  Quoted words are read verbatim between their backticks, so they may contain
  ` · `, parentheses and the word "in"; a tab may follow the marker; one closing
  `.` and trailing blanks are allowed; lines inside a fenced code block are
  ignored and a fence left open at the end of the file is an error. Five of the
  44 shared vectors failed before this (finding 2).
- **The template's examples were live entries** that bound anyone who copied the
  file as shipped (finding 5). They are now inert inside a fenced code block, a
  ruling that goes to both editions.
- **`ARCHITECTURE.md` said the router is "approximately 8 KB"** (finding 4). It
  is 9,526 bytes; the line now says 9 KB and gives the measured figure.
- **Three guarded behaviours had no test** (finding 3): that neither script ever
  *creates* the local file, that the `AGENTS.md` paragraph states what makes an
  Override stale and numbers local sections `L1`, `L2`, and that the preflight
  reads the *source* `AGENTS.md` rather than the installed one. All three are
  now asserted, and each of the review's surviving mutations is killed by the
  assertion written for it.
- **`INSTALL.md`'s installer-order list** was numbered `1. 1. 2. 3.` and claimed
  the override state and the destinations were validated before the local check,
  which runs first (informational finding I1). The list is now numbered once
  through, in the order the code runs.
- **A local-layer line is bounded at 4,096 bytes** (informational finding I2):
  the scanner's cost grows with the square of a line's length and had no bound.
  Measured here: 113 items at 3,742 bytes parse in 11 ms; unbounded, the review
  measured 7.5 s for 3,000 items and 57 s for 12,000. The source later
  adopted the same local-layer line bound; the parity matrix records that
  sequence.

### Publication

- Claude published `checkpoint/0.1.16` before this edition's
  `checkpoint/0.1.6`, preserving the ordering used for 0.1.4. The parity matrix
  names the final published source commit and tag, as well as the historical
  grammar and shared-vector development commits.
- The batch's mechanical review returned FAIL with one blocking finding; all
  five findings were confirmed by the coordinator
  (`docs/reviews/2026-09-21-local-layer-mechanical-review-validation.md`) and
  every one is fixed above. The batch stays held for a focused mechanical
  re-check and then the deep review.

## 0.1.5 — 2026-09-20

### Fixed

- **The rule 3.5 wording contract checked its required phrases across the whole reviews skill.**
  It now requires every phrase within the extracted rule 3.5 and separately sweeps the whole
  skill for forbidden superseded wording. The fifth independent review found the gap
  (`docs/reviews/2026-09-20-sol-0.1.4-fifth-review.md`, finding 2). Before publication, the task's
  mechanical review (`docs/reviews/2026-09-20-0.1.5-mechanical-review.md`; re-checked in
  `…-0.1.5-mechanical-recheck.md`) found that the contract needed to name each
  sentence at fault, pin `opens an **ad-hoc batch**` in the prose rather than through the table,
  and identify its forbidden-wording sweep as covering rules 3.1, 3.3 and 3.5. This changes
  neither rulebook nor installer behaviour.

## 0.1.4 — 2026-09-20

### Added

- Rule 3.5, the fiftieth rule — how far development may run ahead of review.
  Mechanical review never holds development. Deep review's ceiling is one
  invariant: a line carries at most three unruled batches, the open one
  included; closing a batch never changes the count, only a ruling brings it
  down, and every landing belongs to the line's open batch, planned or ad-hoc,
  except a reviewed fix for a recorded finding — worst case three batch ranges
  per line. Counted by git ancestry as a set (a merge is a union) against a
  ledger the coordinator keeps; three waits at any depth; high deep reviews are
  gates and every lower review, mechanical included, is settled first; the
  planner owns the stall. The rule carries a normative table of twenty worked
  cases, and the table wins over the prose. Direct port of source 0.1.15.
- One owner for tier selection:
  `.agents/skills/codex-playbook-subagents/references/roster.md`. Four capability
  tiers — Top, Strong, Standard, Fast — each filled by a model and a reasoning
  effort; an optional second family by capability; a dated operator binding kept
  outside the managed packages; no model product identifiers in the tier
  assignments. The boundary is explicit: numbered rules own who does what, the
  roster owns what each tier is.
- `config/managed-resources.txt` — the inventory of nested files an installation
  depends on. The installer refuses, before any backup or destination write, when
  a listed file is missing from the source or is not a regular file; install,
  upgrade, rollback and restore tests cover the nested roster.
- A Strong tier: deep review had been assigned to the same tier as
  implementation and mechanical review.
- `docs/guides/non-blocking-review-pipeline.md`, ADR 0003 and ADR 0004.

### Changed

- Rule 3.1: two kinds of review became three — mechanical, deep, high deep —
  defined by what they close. High deep is a gate. A pending mechanical review
  never delays the next reversible task; a returned blocking finding stops the
  line, whatever kind of review found it.
- Rule 3.3 gained its mechanics, adapted for Codex where it differs: completion
  is registered and handled; an isolated snapshot is prepared by whoever holds
  the permission; a reviewer that cannot write returns its notes through its
  reply and its permissions are never widened to fit the rule; reviewer
  isolation is scoped to what the reviewer can reach; nothing observed on
  another client is asserted of Codex threads.
- The "Deep" tier is renamed "Top". The roster table left the reviews and
  subagents skills for the single reference.
- The mechanical-review measurement carries its provenance: taken on two Claude
  models, it validates no Codex configuration; "Standard, never Fast" is a
  conservative floor pending a Codex measurement.
- The rule count is fifty in the tests, manifest, parity matrix, page and public
  docs. ADR 0002's "49" stands as written.

### Fixed

- **Found by a re-review of this repair, before anything was published.** The admission rule
  could be granted twice on one count: one batch is now open per line at a time, a batch starts
  at the first dispatch of a task the plan allocates to it, and at three the line accepts only
  the fixes that rule a batch. Rows 13–16 of the worked cases. Follows source 0.1.15.
- **The installer's nested-resource preflight had three gaps.** It now refuses any symlink
  inside an active skill's source directory (not only a symlinked leaf), refuses a listed
  resource whose owning skill is not an active skill, and reads an inventory whose last line
  has no newline. Each refusal happens before any backup or destination write.
- **The worked-cases test compared one phrase per row**, which passes a row that also says the
  opposite. It now compares the rule's table row for row against a canonical copy under `tests/`.
- **The ceiling was restated as one invariant rather than patched a fifth time.** A third review
  of this port, still before publication, passed the installer and the tests and failed rule 3.5
  on two more omitted states — a batch closed early with a task still running, and a branch cut
  from an open batch — and said not to patch again. The owner chose the restatement; the source
  was corrected first. Rows 7 and 13–16 reworded.
- **The restatement was reviewed too, and failed on what it had newly created.** "Nothing lands
  outside a batch" made an authorized hotfix with no plan unlandable and contradicted the
  gate-time docs row; fixes attached to a closed batch owed no review; merging a line whose
  batch was still open let a fourth unruled range in. Now every landing belongs to the line's
  open batch — the plan's, or an ad-hoc batch the coordinator names, never a new approval —
  except the fix for a recorded finding, which gets a focused review before its batch is ruled;
  only closed work merges between lines; a task's own worktree is not a line. And the rule
  closes itself: what it does not name is resolved toward review. Twenty worked cases. Follows
  source 0.1.15.
- The installer also refuses a symbolic link at `.agents` or `.agents/skills` in the source.

### Process

- Reviewed six times by the other model family before anything was published, each time as a
  separate process against pinned commits with a cold-read note first: the plan (eleven
  findings), the first candidate (eight, **failed**), its repair (ten, **failed**), and the
  second repair (six, **failed** on rule 3.5 alone), the restated rule (six, **failed** on
  rule 3.5 alone), and the completed rule (two, **passed**). Forty-two of forty-three findings
  were confirmed, and the one dismissal was
  overturned by the next review. The source rule was corrected first each time. No candidate
  was pushed. Records under `docs/reviews/2026-09-20-*`.

## 0.1.3 — 2026-09-17

### Added

- The five partnership principles as a dedicated, linked section in the visual
  playbook.
- A regression contract that requires the visual playbook to retain every
  mantra heading and its navigation target.

### Fixed

- Restored the partnership mantra that was present in `AGENTS.md` but omitted
  from the public visual playbook.

## 0.1.2 — 2026-09-17

### Added

- Sixteen on-demand Codex skills that preserve the complete 49-rule source
  corpus while keeping the always-loaded global router concise.
- A machine-readable rule ownership manifest and managed-skill inventories.
- A human-readable rule parity matrix, progressive-disclosure architecture
  decision, GitHub Pages runbook, and environment-variable reference.
- Rulebook verification covering exact rule ownership, skill inventory,
  metadata limits, router size, visual-site parity, and platform exclusivity.

### Changed

- Rebuilt the installer around a validated manifest and format-2 checkpoints
  that record every active and retired managed skill.
- Rebuilt restoration to support both format-2 checkpoints and the original
  format-1 three-skill backups without losing unrelated user data.
- Replaced the abbreviated public rule map with all 49 source rules, the full
  approval model, and the sixteen-skill Codex architecture.
- Expanded contributor, installation, architecture, plan, and source-parity
  documentation to describe the faithful modular migration.

### Fixed

- Refused installation when a non-empty `AGENTS.override.md` would silently
  shadow the installed global rules.
- Rejected malformed checkpoint completion markers before restoration can
  change any managed destination.
- Rejected malformed manifest state entries, ambiguous `CODEX_HOME` paths, and
  managed-skill overlap before checkpoint or restore writes begin.
- Preserved original global-rule and skill file modes across checkpoints and
  restoration.
- Made upgrade retirement, interrupted swaps, failed rollback storage, and
  legacy restoration explicit, recoverable, and regression-tested.
- Made numeric rule-ID searches exact so `0.1` no longer also matches `10.1`.

## 0.1.1 — 2026-09-17

### Changed

- Established `michelabboud/codex-playbook` as the canonical upstream and
  `nice-michel/codex-playbook` as its contribution fork.
- Updated clone, installation, visual-site, and provenance links to the
  canonical repository.

## 0.1.0 — 2026-09-16

### Added

- A 42-rule, first-person global `AGENTS.md` covering production quality,
  verification, documentation, Git, autonomy, collaboration, and safety.
- Codex-native skills for dependency review, quarantine, and task/release
  close-out.
- Backup-first installation and restoration guidance that leaves existing Codex
  configuration, authentication, and unrelated skills untouched.
- A guarded installer and restore command with verified, unique checkpoints,
  custom `CODEX_HOME` support, explicit replacement consent, transactional
  rollback, interruption recovery, and isolated lifecycle tests.
- A source-parity report documenting every deliberate adaptation from
  `claude-code-playbook`.
- A dependency-free visual rule map and an original editorial hero illustration.
- Public contributor, security, architecture, plan, progress, and decision
  records.

### Fixed

- Corrected the user skill destination to `$HOME/.agents/skills`.
- Replaced unsafe unconditional copy instructions with a checkpoint-first flow
  that refuses different global rules by default.
- Made the Claude-to-Codex adaptation report explicit about doctrinal
  differences instead of overstating one-to-one parity.
