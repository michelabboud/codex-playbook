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
  different in whole sentences, and quotes, on a `**Dead words:**` line, the
  playbook's exact words that no longer apply, each with the file they are in.

*These three bullets describe the kinds; they are deliberately not written in the
shape of an entry. An entry line is one that begins — after any indentation and
an optional `- ` or `* ` bullet — with `**Fill`, `**Add` or `**Override`, and an
Override written that way owes a Dead-words line. Writing about the kinds in that
shape would make this page carry live entries, which a template never does.*

`scripts/check-local.sh` reads every `**Dead words:**` line and searches the
named file for each quoted phrase as a fixed string. Found: the override still
bites on the text it was written against. Not found: the playbook rewrote that
rule, the override is **stale** and suspended: the installer or restore refuses
the change until you re-read the rule and rewrite the entry. There is no flag to
continue past it; if its scope is unclear, apply the stricter constraint.

### The grammar of a Dead-words line

A script reads it, so its shape is fixed:

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

**And an Override may not go without one.** An Override entry with no valid
Dead-words line before the next entry line, the next heading, or the end of the
file is an error too. That is what makes a mistyped marker — lower case, the
colon outside the bold, the bold left off — a refusal rather than a silent pass:
were it only prose, the Override would install with nothing checked. A Fill and
an Add owe no such line, and a Dead-words line that stands alone is still read
and searched.

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

## Overrides, each with its Dead words

- **Override — the version line of `AGENTS.md`.** My installation records its
  version somewhere else, so the sentence that states it in `AGENTS.md` does
  not apply here.
  **Dead words:** `This rulebook is version` (in `AGENTS.md`)
- **Override — the tier that runs mechanical review.** Here mechanical review
  runs on whatever lane has allowance that day.
  **Dead words:** `Standard tier` (in `codex-playbook-reviews/SKILL.md`)
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
