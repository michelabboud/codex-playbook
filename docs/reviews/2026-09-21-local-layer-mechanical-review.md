# Mechanical review B — codex-playbook, the local layer (0.1.6, held)

- **Target:** `5c90bb62e7d962cb7e7cfb10672f95fc7ecd514a` · **Base:** `0a09cfb` · reviewer: Sonnet 5 lane, read-only, worktree at the target commit (clean).
- **Read first:** `docs/adr/0005-the-local-layer.md`, `docs/plans/2026-09-21-local-layer-plan.md`.
- Everything mutated was mutated in copies under `/tmp/mrb/` (a `git archive` of the target). No tracked file was edited, staged, committed or tagged. `install.sh` was only ever run with `HOME` and `CODEX_HOME` pointing into `/tmp/mrb/`.

## Verdict: **FAIL** — one blocking finding, narrow and cheap to fix; everything else is minor or informational

The blocking finding is in the one thing the feature exists to do: a stale override can be installed past the check. Tasks 1, 3, 4 and 5 otherwise meet their "done when"; task 2 meets it except for the "grammar identical to the Claude edition, byte for byte" clause, which is not true today (finding 2).

---

## Findings, most severe first

### 1. BLOCKING — a `**Dead words:**` marker that is not at the start of a line is silently skipped; the stale override installs and the tool says "every override still matches"

- `scripts/check-local.sh:265-268` (the `case … '**Dead words:**'*) ;; *) continue ;;` — anything not starting with the marker is dropped), success message at `:298-299`. `tests/check_local_test.sh:377-391` (`run_ignored_lines_test`) asserts this behaviour as correct, so the suite locks the hole in.
- **What is wrong.** Only a line that *begins* (after blanks) with the marker is parsed. The natural Markdown shape — marker on the same line as the entry, or after a list bullet — is not parsed, not reported, and counted as zero items. With zero items checked the script still prints "every override still matches the playbook text" and exits 0, so the installer proceeds. The review brief defines "a stale, malformed or escaping entry passes" as blocking; this is a malformed entry that passes.
- **Reproduction** (temp dirs only; run from the worktree):

  ```
  mkdir -p /tmp/mrb/e2e/home /tmp/mrb/e2e/codex
  cat > /tmp/mrb/e2e/codex/playbook-local.md <<'EOF'
  - **Override — mechanical review runs elsewhere.** It runs on whatever lane has allowance. **Dead words:** `a sentence the playbook no longer carries` (in `codex-playbook-reviews/SKILL.md`)
  EOF
  HOME=/tmp/mrb/e2e/home CODEX_HOME=/tmp/mrb/e2e/codex ./scripts/install.sh
  ```

  Output: `…/playbook-local.md: 0 dead-words item(s) checked; every override still matches the playbook text.` then `Installed Codex Playbook 0.1.6.` — **exit 0**, `backups/` created, stale override installed.
  The same phrase on its own indented line (the documented form) gives `…playbook-local.md:2: stale: … is no longer in …/codex-playbook-reviews/SKILL.md` and **exit 1**, nothing written.
  Other shapes that also exit 0 with 0 items: `- **Dead words:** …` (bullet-led), `> **Dead words:** …`, `**Dead words**: …`, `**dead words:** …`, `Dead words: …`. (The last three are arguably "not the marker"; the first two and the mid-line form are what a person writes.)
- **This is already known upstream.** `claude-code-playbook` commit `e5c4f85` (2026-09-21 00:52, five minutes *after* the target commit's 00:47) amends its ADR 0004 decision 5: *"The check fails closed: the bare marker anywhere but the start of a line is an error, never a skipped entry — prose names the marker inside a code span"*, and adds `tests/fixtures/dead-words-vectors.tsv` (44 vectors) that "both editions carry … byte-identical … and each edition's tests run every vector". Against those 44 vectors, this script fails TSV lines 49 and 50 (the two "bare marker mid-line → error" cases; results in finding 2).
- **What I would do.** Make a bare `**Dead words:**` anywhere but the start of a line a parse error (exit 2), name the marker inside a code span in prose, and change `run_ignored_lines_test` to assert the error. That requires rewording `templates/playbook-local.md:25` and `:28`, which name the marker bare in prose: `tests/rulebook_test.sh` runs the checker over the template, so under the stricter rule the template would fail its own check until those two mentions are put in code spans. Separately, print a different message when 0 items were checked and the file is non-empty. Consider (not required by the plan) warning when a file contains an `**Override` line and no Dead-words item at all.

### 2. MINOR — "the same grammar, byte for byte" is not true against the Claude edition's current text; five of its 44 shared vectors fail

- Claims: `templates/playbook-local.md:47`, `docs/adr/0005-the-local-layer.md:14` (decision 3), plan task 2 ("Same grammar as the Claude edition, byte for byte"). Pin: `docs/reports/2026-09-17-rule-parity-matrix.md:18` cites `267057ae…`, which is real (`docs: ADR 0004 and the plan for the local layer`) but is no longer the tip of the source; `tests/fixtures/` at the target carries no `dead-words-vectors.tsv`.
- **Reproduction.** I ran the 44 vectors of `~/projects/claude-code-playbook/tests/fixtures/dead-words-vectors.tsv` (`@F1@`→`AGENTS.md`, `@F2@`→`codex-playbook-reviews/SKILL.md`, expectations as the file defines them) against `scripts/check-local.sh` with `/tmp/mrb/vec.py`:

  ```
  MISMATCH line 11: want 'ok 1' got exit=2  | '**Dead words:**<TAB>`tab after the marker` (in `AGENTS.md`)'
  MISMATCH line 12: want 'ok 1' got exit=2  | '**Dead words:** `a trailing period is allowed` (in `AGENTS.md`).'
  MISMATCH line 13: want 'ok 1' got exit=2  | '**Dead words:** `trailing spaces are allowed` (in `AGENTS.md`)   '
  MISMATCH line 49: want 'error' got exit=0 | 'Prose that mentions **Dead words:** bare in the middle of a line …'
  MISMATCH line 50: want 'error' got exit=0 | '- **Override — rule 9.1.** **Dead words:** `marker not at the start of the line` (in `AGENTS.md`)'
  44 vectors, 5 mismatches
  ```

  Lines 49-50 are finding 1. Lines 11-13 are the opposite direction — stricter, fail-closed: a trailing period or trailing blanks after the last item, or a tab after the marker, exit 2 with the unhelpful "does not parse: expected `words` (in `file`), items separated by ' · '" (no column). A **fenced code block** is also not skipped here (upstream ignores lines inside one; probed: a fenced stale line → exit 1, a fenced malformed line → exit 2), so a user who quotes the grammar in a fence is refused.
- **Practical effect.** I ran this script over the owner's own Claude-edition files: every `**Dead words:**` line in `~/.claude/rules/LOCAL.md` (`:29`, `:39`) and `LOCAL_dev.md` (`:37`, `:46`, `:62`, `:70`) ends with a period and fails to parse here (they also name `REVIEWS.md`/`AUTHORITY.md`, which do not exist in this edition, so renaming is needed anyway). "One entry can be carried between the two editions unchanged" is therefore wrong today.
- **What I would do.** Wire the shared vectors file into `tests/check_local_test.sh` (byte-identical copy, all 44 run), accept one trailing period and trailing blanks, then either correct the byte-for-byte sentence or make it true. The upstream fix is unpublished and moving; the ordering dependency already recorded in the parity matrix should also pin `e5c4f85` (or its successor), not `267057a`.

### 3. MINOR — two guarded behaviours have no test: the local file is never *created*, and the AGENTS.md wording tests do not pin the Dead-words clause

- **Never created.** ADR 0005 decision 1 and `INSTALL.md` say neither script "creates" the local file. Mutation `I10` (install.sh appends `[ -e "$local_layer_target" ] || : > "$local_layer_target"`) and `R03` (same in restore.sh) both **survive** all 372 installer assertions and all of `verify.sh`; every local-layer test starts with a file already present. Assertion that should catch it: after a first install and after a restore on a `CODEX_HOME` with no `playbook-local.md`, `assert_absent "$codex_home/playbook-local.md"`.
- **AGENTS.md paragraph.** Deleting `quotes, after **Dead words:**, the playbook's exact words that no longer apply, each with the file they are in; ` from `AGENTS.md` (mutation `W1`), or `numbered \`L1\`, \`L2\`, and onward — ` (`W2`), leaves `tests/rulebook_test.sh` at exit 0 (`rulebook_test.sh:506-524` pins eleven fragments; neither the Dead-words clause nor `L1`/`L2` is among them) although its pass message claims coverage of "the L numbering, staleness". Without that clause the agent is not told what makes an override stale. Add both fragments to the required list.
- Related, fragile kill: mutation `I05` (preflight checks the *installed* `AGENTS.md` instead of the source one) is caught only because `run_local_layer_survives_lifecycle_test`'s first install happens to have no installed `AGENTS.md` and dies under `set -e`; no assertion names it. `run_local_layer_checked_against_source_test` covers this only for a skill file. Add the AGENTS.md twin (installed copy carries a phrase the source lacks).

### 4. MINOR — `ARCHITECTURE.md:58` still says the router is "approximately 8 KB"

`AGENTS.md` is 9,526 bytes at the target (8,357 at the base). `README.md` and `docs/index.html` were updated to "9 KB"; `ARCHITECTURE.md:58` was not. Reproduction: `grep -n 'approximately 8 KB' ARCHITECTURE.md`. Change to "approximately 9 KB".

### 5. MINOR — the copied template carries live overrides that bind the agent if the file is kept as-is

`INSTALL.md` ("Make it yours") tells the reader to `cp templates/playbook-local.md` into place. The template's two example Overrides (`templates/playbook-local.md:68-74`: the version line "does not apply here"; mechanical review "runs on whatever lane has allowance that day") and its Fill ("The 'I' of every rule is *your name here*") are real entries with the force ADR 0005 gives them. I ran the snippet in a temp `CODEX_HOME`: the copy passes the checker (2 items) and `install.sh` installs with it in place, exit 0. The file does say "delete every example" (`:5-8`), but only "once you have written an entry of your own", so a user who writes none keeps them. Suggest shipping the examples inert (for instance, the Dead-words examples only in a fenced block once the checker skips fences, per finding 2), or stating in `INSTALL.md` that the copied file must be edited before use.

---

## Informational

- **I1.** `INSTALL.md:90` and `:93` are both numbered `1.` (renders 1, 2, 3…; the raw "2. Refuse…" then displays as 3). The list also says override state and destinations are validated *before* the local check; in the code the check (`install.sh:243-250`) runs before those (`:252-276`). Both precede every write, so no behaviour changes.
- **I2.** Parsing a single very long line is quadratic: 3,000 items 7.5 s, 6,000 → 21.9 s, 12,000 → 57.2 s. A realistic file has a handful of items; no damage path, but no bound either.
- **I3.** Quoted words over ~128 KB make `grep` fail with E2BIG: reported as `could not search … (grep exited 126)`, exit 2 — fails closed.
- **I4.** A local file that is a symlink to a regular file is read and checked (good for dotfile managers); a dangling symlink, a directory, a FIFO and `/dev/null` are exit 2; an unreadable file is exit 2.
- **I5.** `[ -x "$repo_root/scripts/check-local.sh" ]` (`install.sh:210`) is redundant with the `|| die` on the call: mutation `I12` survives, and with the exec bit removed and that guard deleted the installer still refuses (`Permission denied` → die, exit 1, `CODEX_HOME` left empty). Fail-closed either way; harmless.
- **I6.** Untested branches of `check-local.sh` (survivors, no damage path): `.` and empty path components (`C16`, `C17`), the `-r` guard (`C21`; without it dash's own redirect error exits 2), a grep status ≥ 2 reported as an error rather than stale (`C27`), no space after the marker (`C22`), `LC_ALL=C` (`C25`, equivalent under most locales), `--` before the path (`C26`, only matters for a relative root starting with `-`), `-f` versus `-e` on the named file (`C18`, equivalent with GNU grep, which errors on a directory).
- **I7.** Portability: no non-POSIX construct found in the new scripts (`[[`, `local`, arrays, `${x//}`, `echo -e`, `$'…'`, `stat -c`, `sed -i`, `readlink -f` — none in `check-local.sh`; the one `stat` use, `tests/install_test.sh` `mtime_of`, probes BSD `stat -f '%m'` first and falls back to GNU `stat -c '%Y'`; I confirmed GNU `stat -f '%m' file` exits 1, so the fallback is reached). Both suites pass under `dash` and `bash --posix`. `BACKLOG.md` already says BusyBox and BSD were not run; that is accurate.

---

## Task 4 of the brief — the installer diff (`git diff 0a09cfb..5c90bb6 -- scripts/install.sh`)

The change is 12 lines: a variable (`:110`), an `-x` guard (`:210`), and the call (`:243-250`). Read against the whole file:

- **The preflight is before `umask 077` (`:282`), before every `mkdir` (`:283`, `:285`, `:333`), before every `mktemp` (`:289`, `:328`, `:334`, `:342`), before every backup/`cp`/`mv`/`rm`.** The only code before it that can run is: the two `trap`s (registered, nothing to clean since every staging variable is empty), `case`/`die` argument checks, `validate_inventory` (read-only `grep`/`sort`), `canonical_path_for_check` (`awk`, `cd`, no writes), `find -type l`. No path exists on which the script writes before the check.
- The call is in a `… || die` list, so `set -e` cannot skip the `die`; a non-zero check exits 1 before anything else.
- **Refusal leaves no backup directory and the destination unchanged, and the tests assert exactly that**: `assert_untouched_destination` (`tests/install_test.sh:978-984`) requires `$codex_home/backups` absent and the seeded `AGENTS.md`, skill file and nested file unchanged; the two refusal tests and the source-text test call it, plus a byte-identical check of the local file itself. Verified end to end on my own reproductions: a stale entry → exit 1, `ls $CODEX_HOME` shows only `playbook-local.md`.
- **The check reads the repository's text, not the installed one** for skills (asserted by `run_local_layer_checked_against_source_test`) and, per `install.sh:246`, for `AGENTS.md` too (only incidentally asserted; finding 3).
- The local file is read once and touched nowhere else: `grep -n 'local_layer_target' scripts/install.sh` shows the assignment and the check call and nothing else; `restore.sh` is unchanged (not in the stat).

## Task 5 of the brief — wording tests

- The pointer line cannot be satisfied by the template, the changelog or `AGENTS.md`: `tests/rulebook_test.sh:530-555` greps only each skill's own file, requires **exactly one** occurrence, requires it to be the first non-empty line after the first `# ` heading, and separately fails if `AGENTS.md` carries it (mutations `W3` drop it, `W4` move it to line two, `W9` put it in `AGENTS.md` — all fail as they should).
- The list of skills is the inventory (`config/managed-skills.txt`), not a hand list; all 16 carry it.
- The eleven `AGENTS.md` fragments each match exactly once inside the one paragraph; because they are fragments, a sentence could be negated around them, and finding 3 lists the two that are missing. The superseded sentence ("Never replace tailored rules…") is asserted absent (`W7` fails as it should).
- The template check (`W5` stale example, `W6` template added to an inventory) fails as it should.

## Task 6 of the brief — conformance and propagation

| Task | Done when | Result |
|---|---|---|
| 1 Rules text | paragraph + pointer in every managed skill, inventory-driven; `AGENTS.md` under limit | Met. 9,526 bytes < 12,288 (`verify.sh` "lean router"); 16/16 skills. Wording pinning incomplete (finding 3). |
| 2 `check-local.sh` | tests for fresh, stale, unparsable, missing, escape, dash, metacharacters, two files, no file, CRLF; proven by mutation | Met — 64 assertions; 31 mutants, 23 killed by the assertion written for them, 8 survivors (all listed in I6). "Byte for byte" grammar clause not met (finding 2); malformed marker passes (finding 1). |
| 3 Installer | preflight before umask; refusal tests with no backup, destination unchanged; local file byte/mode/mtime survive install, `--replace-agents`, restore | Met. All three survive-tests fail under mutation (`I07` truncate, `I08` touch, `I09b` chmod, `I14` append, `R01b` delete, `R02` touch, `I11` copy into checkpoint). Untested: never *created* (finding 3). `verify.sh` runs the new suite (`:98-102`). |
| 4 Template + INSTALL + self-update skill | cold reader can install, update, migrate | Met. I ran the copy, check and migration snippets in a temp home: all work (`test ! -e … && cp` returns 1 when the file exists, harmless). Finding 5 and I1. |
| 5 Propagation | repository describes itself truthfully at 0.1.6 | Met except finding 4 and the pin in finding 2. Counts verified: 55 rulebook checks, 64 local-layer assertions, 372 installer assertions, 16 skills, ADR index row present, `VERSION` 0.1.6 in `AGENTS.md`, README, `docs/index.html`, PROGRESS, template (`verify.sh` "public version carriers match VERSION"). |
| Older records | byte-identical | `git diff --stat 0a09cfb..5c90bb6 -- docs/reviews docs/plans docs/adr/0001* docs/adr/0002* docs/adr/0003* docs/adr/0004* docs/adr/0005*` is empty; `CHANGELOG.md` has 0 removed lines (only the 0.1.6 entry added). |
| Parity matrix | cited commit | `267057ae…` exists in `~/projects/claude-code-playbook`; that repo's highest `checkpoint/*` tag is `0.1.15`, so "does not yet exist" is correct locally (remote not checked). Pin is stale relative to `e5c4f85` (finding 2). |

---

## Everything I ran, with its exact result

1. `./scripts/verify.sh` → **exit 0**; summary lines: `All 55 rulebook verification checks passed.` · `All 64 local-layer staleness assertions passed.` · `All 372 installer lifecycle assertions passed.` · `All Codex Playbook verification checks passed.` (540 `PASS` lines, none `FAIL`; output kept at `/tmp/verify-B.out`).
2. `dash tests/check_local_test.sh` and `bash --posix tests/check_local_test.sh` → both `All 64 local-layer staleness assertions passed.`
3. **`check-local.sh` input probes** (fixture: `/tmp/mrb/fx`, two roots; exit codes as observed):
   - empty file → 0 (`0 items checked`); marker only → 2; marker + space only → 2; empty code span → 2; `(in )` → 2; `(in ``)` → 2; `(in AGENTS.md)` without code spans → 2; trailing text after last item → 2; tab where the space belongs (after marker, or before `(in`) → 2; tab *indentation* → accepted (0); `·` with no spaces, or with one space → 2; dangling `·` → 2; second item stale → 1; two `Dead words:` lines in one entry → both parsed (0 / 1 as their words dictate).
   - Words with `*`, `[a-z]`, `\`, `$HOME`, a leading `-`, `--`, a single space → searched literally (0 or 1, never a regex); words containing a backtick → 2. 200 KB of words → 2 (E2BIG, finding I3). 3,000 items → 0 (7.5 s).
   - No trailing newline: stale → 1, malformed → 2. CRLF: stale → 1, malformed → 2, fresh → 0; two CRs → 2; lone final CR stale → 1. NUL bytes near a stale line → 1.
   - Fenced block: stale line inside → 1, malformed line inside → 2 (not skipped; see finding 2).
   - **Bare or malformed marker: bullet-led, blockquote, colon outside the bold, lowercase, unbolded, mid-line → 0 with 0 items (finding 1).**
   - Paths: directory → 2; dir without leaf → 2; symlinked leaf (outside or inside the root) → 2; symlinked directory component → 2; `../x`, `a/../../x`, `AGENTS.md/../AGENTS.md` → 2; absolute → 2; `./AGENTS.md` → 2; `a//b` and trailing `/` → 2; trailing space in name → 2; FIFO → 2; `-x/SKILL.md` → 2 (missing, not an option error); backslash path → 2; `agents.md` → 2; a symlinked `AGENTS.md` → 2; a symlinked skills root and trailing-slash roots → work (stale → 1); nonexistent roots → 2; swapped roots → 2.
   - Local file: absent → 0 with "nothing is customized"; unreadable → 2; symlink to a regular file → read (0/1); dangling symlink → 2; directory, FIFO, `/dev/null` → 2.
   - Template against the real repo roots (`check-local.sh templates/playbook-local.md . .agents/skills`) → **0, 2 items checked** — the template passes its own checker (it has no fenced example).
   - The 44 shared upstream vectors: 5 mismatches (finding 2).
   - Owner's Claude-edition `LOCAL.md` / `LOCAL_dev.md` through this script: exit 2 (missing files plus trailing-period parse errors; finding 2).
4. **Mutation results** (harnesses `/tmp/mrb/mut.py`, `mut2.py`, `wmut.sh`; each mutant is a fresh copy of the target, `sh -n` checked, then the matching suite run):
   - `check-local.sh` vs `tests/check_local_test.sh`, 31 mutants: **killed 23** — drop `-F`, drop `-e`, ignore a stale result, drop the `..` check, drop the absolute-path check, drop the symlink check, stale exits 0, errors exit 1, drop CRLF strip, drop unterminated-last-line read, ignore the error count, accept an empty span, check only the first file of an item, don't count items, drop tab-indent, drop the empty-argument guard, absent file exits 2, resolve `AGENTS.md` in the skills root, allow a symlinked leaf, accept any text after the separator, accept trailing text, parse only the first marker line, wrong `file:line`; each failed on the assertion named for it. **Survived 8:** `C16` `.` component, `C17` empty component, `C18` `-e` for `-f`, `C21` `-r` guard, `C22` no space after marker, `C25` `LC_ALL=C`, `C26` `--`, `C27` grep error reported as stale.
   - `install.sh`/`restore.sh` vs `tests/install_test.sh`, 16 distinct mutants: **killed 13** — remove preflight, move it after the backup is created (`stale local layer: refused before any backup exists` fails), warn instead of die, check installed skills, wrong local path, truncate / touch / chmod / append the local file, copy it into the checkpoint, restore deletes / touches it, check installed `AGENTS.md` (killed incidentally, finding 3). **Survived 3:** `I10` install creates the file, `R03` restore creates it (finding 3), `I12` redundant `-x` guard (I5). (`R01`, first attempt, did not apply — the anchor was wrong; `R01b` replaced it. `I05b` and `I09b` re-run `I05` and `I09`, so they are not counted twice.)
   - `tests/rulebook_test.sh`, 9 meaningful wording mutants (plus two no-ops of my own, `W8` and `W10`, ignored): **killed 6** (pointer removed, pointer on line two, pointer in `AGENTS.md`, stale template example, template added to an inventory, superseded sentence restored). **Survived 3:** `W1` and `W1b` drop parts of the Dead-words clause, `W2` drops the `L1`/`L2` tokens (finding 3).
   - A harness error of mine: the first `I09` (unguarded `chmod`) was killed by `set -e` on a home with no local file, not by the mode assertion; re-run guarded as `I09b`, it is killed by `first install leaves the local file mode`. Reported result is `I09b`.
5. End-to-end installs into temp homes: stale entry on its own line → exit 1, nothing written; same entry mid-line → exit 0, installed (finding 1); the unedited template in place → exit 0 (finding 5); `INSTALL.md` copy / check / migration snippets → work.
6. Shell portability grep over the diff of `scripts/` and `tests/` for GNU-only and bashism patterns → nothing in `check-local.sh`; `stat -f`/`stat -c` fallback in `tests/install_test.sh` verified.
7. Timing of a 3,000 / 6,000 / 12,000-item line: 7.5 / 21.9 / 57.2 s (I2).

## What I could not verify, and why

- **BusyBox `ash`, BSD userland, macOS `grep`/`stat`/`touch`:** none installed here (`dash` and `bash` only). The scripts are POSIX by inspection; the `grep` behaviour on a directory and the `stat` fallback are untested on those platforms.
- **How a fresh Codex session treats `playbook-local.md` and the pointer lines:** the mechanism is prose, not enforced; `BACKLOG.md` already says it is unobserved. I cannot observe a Codex session from this lane.
- **Whether the Claude edition's tag `checkpoint/0.1.16` exists on GitHub:** I only read the local clone's tags (highest `checkpoint/0.1.15`). The upstream commit `e5c4f85` is unpublished and may change again, so finding 2's numbers describe it as of this review.
- **Whether `e5c4f85`'s wording ("both editions carry one file of conformance vectors, byte-identical between them") reflects a decision for this repository or only the Claude side's plan:** I treated it as the sibling-edition's stated contract; the Codex plan and ADR 0005 contain no such requirement, which is why finding 2 is minor while finding 1 is blocking on the brief's own definition.
