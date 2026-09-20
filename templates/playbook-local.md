# LOCAL — my local layer

*Copy this file to `${CODEX_HOME:-$HOME/.codex}/playbook-local.md` and make it
yours. The playbook never ships it, and neither `scripts/install.sh` nor
`scripts/restore.sh` creates, writes over, moves, or deletes it — so an update
cannot lose what you write here. Delete every example below once you have
written an entry of your own; an empty file and an absent file both mean
nothing is customized.*

*Force: `AGENTS.md`, "The local layer" — where an entry here changes a rule, the
entry wins over the playbook's wording. It never adds authority the approval
table does not have, except by adding a row in so many words.*

*Written against playbook version 0.1.6.*

---

## The three kinds of entry

- **Fill** — supplies a value a rule leaves open, or binds one of its generic
  terms to the thing you actually have. It contradicts nothing.
- **Add** — a rule or note the playbook does not have. Its own sections are
  numbered `L1`, `L2`, and onward, numbers the playbook never uses.
- **Override** — changes what a named rule says. It names the rule, says what is
  different in whole sentences, and quotes after **Dead words:** the playbook's
  exact words that no longer apply, each with the file they are in.

`scripts/check-local.sh` reads every **Dead words:** line and searches the named
file for each quoted phrase as a fixed string. Found: the override still bites
on the text it was written against. Not found: the playbook rewrote that rule,
the override is **stale**, and the installer refuses the update until you
re-read the rule and rewrite the entry. There is no flag to install past it.

### The grammar of a Dead-words line

A script reads it, so its shape is fixed:

- the line begins, after any indentation, with `**Dead words:**` and one space;
- items are separated by ` · `;
- each item is one code span of the quoted words, then `(in `, then one or more
  code spans naming files, then `)`;
- a file is named `AGENTS.md`, or by its path under the skills root, such as
  `codex-playbook-reviews/SKILL.md`. An absolute path, a `..` component, or a
  path through a symbolic link is refused;
- the quoted words may not contain a backtick.

It is the same grammar, byte for byte, as the Claude edition's local layer, so
one entry can be carried between the two editions unchanged.

---

## Who and where

- **Fill — whose rules these are.** The "I" of every rule is *your name here*.

## 9 · Environment and operations

- **Fill — rule 9.1, the claims registry.** Mine lives at
  `~/.config/agent-rules/ports/`, one file per project.

## L1 · My own additions

- **Add — this section number is mine.** The playbook never uses `L` numbers, so
  an `L` section can never collide with a rule an update introduces.

## An Override, with its Dead words

- **Override — the version line of `AGENTS.md`.** *(Example. It changes nothing
  real; delete it.)* My installation records its version somewhere else, so the
  sentence that states it in `AGENTS.md` does not apply here.
  **Dead words:** `This rulebook is version` (in `AGENTS.md`)
- **Override — the tier that runs mechanical review.** *(Example. Delete it.)*
  Here mechanical review runs on whatever lane has allowance that day.
  **Dead words:** `Standard tier` (in `codex-playbook-reviews/SKILL.md`)
