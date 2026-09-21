# LOCAL — my local layer

*Copy this file to `${CODEX_HOME:-$HOME/.codex}/playbook-local.md` and make it
yours. The playbook never ships that file, and neither `scripts/install.sh` nor
`scripts/restore.sh` creates, writes to, copies over, moves, or deletes it — so
an update cannot lose what you write here. The installer does **read** it, once,
during source preflight, to check your Overrides against the text it is about to
install; that is the only way it ever touches it. Nothing in this file is in
force as it stands: every example sits inside a fenced code block, which the
checker ignores and which binds nobody. An empty file and an absent file both
mean nothing is customized.*

*Force: `AGENTS.md`, "The local layer". A Fill only supplies an open value; an
Add is non-authorizing guidance or a stricter constraint; an Override changes a
named rule within that boundary. No local entry may expand authority, remove an
approval, relax a protection, change precedence, or override that boundary.*

*Written against playbook version 0.1.6.*

---

## The three kinds of entry

- A **Fill** supplies a value a rule leaves open, or binds one of its generic
  terms to the thing you actually have. It contradicts nothing.
- An **Add** is non-authorizing guidance or a stricter constraint the playbook
  does not have. Its own sections are numbered `L1`, `L2`, and onward, numbers
  the playbook never uses.
- An **Override** changes what a named rule says. It names the rule, says what is
  different in whole sentences, and binds that change to one named Markdown
  section: its literal heading, its normalized SHA-256 digest, and a quote from
  that section that is at least 16 non-whitespace bytes and occurs exactly once.

*These three bullets describe the kinds; they are deliberately not written in the
shape of an entry. An entry line is one that begins — after any indentation and
an optional `- ` or `* ` bullet — with `**Fill`, `**Add` or `**Override`, and an
Override written that way owes an Anchor, Rule digest, and Dead-words line. Writing about the kinds in that
shape would make this page carry live entries, which a template never does.*

`scripts/check-local.sh` reads every Override's three-line verifier. It extracts
the one literal heading you named, normalizes that section (CRLF becomes LF and
trailing blanks are ignored), hashes it, and then checks the quoted phrase as a
fixed string inside that section. A changed digest or missing phrase makes the
override **stale** and suspended; a short or non-unique phrase is refused. The
stale report prints the current digest to copy after you re-read the rule. There
is no flag to continue past it; if its scope is unclear, apply the stricter
constraint.

### The Override verifier

A script reads it, so its shape is fixed. Immediately after the Override's own
sentence, write these three lines in this order:

```markdown
**Anchor:** `## The literal section heading` (in `AGENTS.md`)
**Rule digest:** `sha256:64-lowercase-hex-characters`
**Dead words:** `at least sixteen non-whitespace bytes, unique in that section` (in `AGENTS.md`)
```

The Anchor heading must occur exactly once in its named managed file. The Rule
digest covers that heading through the line before the next heading of equal or
higher level, after CRLF-to-LF and trailing-blank normalization. `sha256sum`,
`shasum -a 256`, or `openssl` supplies the digest; if none is available, the
checker refuses the Override rather than guessing. The quoted words must name
the same file as the Anchor. Standalone `**Dead words:**` lines remain useful as
read-only compatibility probes and retain the grammar below; they grant no
override authority.

For that Dead-words line:

- the line begins, after any indentation, with the marker `**Dead words:**` and
  at least one space or tab;
- items are separated by ` · `;
- each item is one code span of the quoted words, then `(in `, then one or more
  code spans naming files, joined by `, `, ` and `, or `, and `, then `)`;
- one `.` may close the line; trailing blanks are ignored;
- a file is named `AGENTS.md`, or by its path under the skills root, such as
  `codex-playbook-reviews/SKILL.md`. An absolute path, a `..` component, or a
  path through a symbolic link is refused;
- the quoted words are read verbatim between their backticks, so they may
  contain ` · `, parentheses and the word "in". They may not be empty and may
  not contain a backtick;
- a line may not be longer than 4,096 bytes.

**It fails closed.** The marker is only ever the first thing on its line: a
line that carries it anywhere else is an error that refuses the installation,
never an entry that is quietly skipped. Prose about the marker puts it inside a
code span, the way this page does throughout. Lines inside a fenced code block
are ignored entirely, which is why the worked examples below are inert; a fence
left open at the end of the file is an error.

**And an Override may not go without all three.** An Override entry with no
valid Anchor, Rule digest, and Dead-words line before the next entry line, the
next heading, or the end of the file is an error. That is what makes a mistyped
marker a refusal rather than a silent pass: were it only prose, the Override
would install with no freshness proof. A Fill and an Add owe no verifier.

It is the same grammar, byte for byte, as the Claude edition's local layer, so
one entry can be carried between the two editions unchanged.

---

## Worked examples — shown, never in force

Every line of the block below is inside a fenced code block. The checker skips
it, so none of it is an entry and none of it binds this installation. Copy the
shape you need out of it into the sections underneath, with your own rule, your
own words, and your own file:

```markdown
## Who and where

- **Fill — whose rules these are.** The "I" of every rule is *your name here*.

## 9 · Environment and operations

- **Fill — rule 9.1, the claims registry.** Mine lives at
  `~/.config/agent-rules/ports/`, one file per project.

## L1 · My own additions

- **Add — this section number is mine.** The playbook never uses `L` numbers, so
  an `L` section can never collide with a rule an update introduces.

## Overrides, each with a section verifier

- **Override — the version line of `AGENTS.md`.** My installation records its
  version somewhere else, so the sentence that states it in `AGENTS.md` does
  not apply here.
  **Anchor:** `# My Global Rules — Codex` (in `AGENTS.md`)
  **Rule digest:** `sha256:0000000000000000000000000000000000000000000000000000000000000000`
  **Dead words:** `This rulebook is version 0.1.6` (in `AGENTS.md`)
- **Override — the tier that runs mechanical review.** Here mechanical review
  runs on whatever lane has allowance that day.
  **Anchor:** `# 3 · Code reviews — rules 3.1–3.5` (in `codex-playbook-reviews/SKILL.md`)
  **Rule digest:** `sha256:0000000000000000000000000000000000000000000000000000000000000000`
  **Dead words:** `Mechanical per task, on the Standard tier` (in `codex-playbook-reviews/SKILL.md`)
```

Check your file at any time, against a checkout, without installing anything:

```bash
./scripts/check-local.sh "${CODEX_HOME:-$HOME/.codex}/playbook-local.md" \
  . .agents/skills
```

---

## Who and where

## L1 · My own additions

## My overrides
