# 0005 — Customizations live in one local file the installer never touches

- **Status:** accepted, 2026-09-21 (the owner's design; his approval the same day).
- **Ports:** `claude-code-playbook` ADR 0004, *Customizations live in a local layer the playbook never touches* (its 0.1.16). The reasoning, the measurement behind it and the alternatives rejected are recorded there and are not repeated here; this record states the decision as it applies to Codex, and where it differs.

## Context

`AGENTS.md` says "never replace tailored rules without the backup and approval procedure" — so tailoring has meant editing managed files, and every update has meant a merge by hand. The installer makes that worse than in the Claude edition: it swaps each managed skill folder whole, and replaces `AGENTS.md` whole under `--replace-agents`. Anything a user wrote inside either is moved into the checkpoint at the next update.

## Decision

1. **One file belongs to the user: `${CODEX_HOME:-$HOME/.codex}/playbook-local.md`.** The playbook never ships it; `scripts/install.sh` and `scripts/restore.sh` never create, write, move, copy over or delete it. One file, not two: Codex has no path-scoped loading, so there is no scoping for a second file to preserve. It sits beside `AGENTS.md`, outside every skill folder the installer swaps. The name is deliberately not `AGENTS.override.md`, which Codex reads *instead of* `AGENTS.md`.
2. **`AGENTS.md` gives it its force, in words, and tells the agent to read it:** at the start of a session, read the local file if it exists; where an entry there changes a rule, the entry wins over the playbook's wording; an absent file means nothing is customized. Each managed skill carries one line pointing at it, because a skill loads long after the session began.
3. **Three kinds of entry — Fill, Add, Override — exactly as ADR 0004 defines them**, with `L`-numbered local sections the playbook never uses and a **Dead words:** line on every Override. The grammar of that line is the same, byte for byte, so one user can carry entries between the two editions. A file named in an item is `AGENTS.md`, or a path under the skills root such as `codex-playbook-reviews/SKILL.md`.
4. **`scripts/check-local.sh` checks staleness, and the installer runs it in source preflight** — before `umask`, before any directory is created, before any backup — against the repository's own text, which is the text about to be installed. A stale override, an unparsable line or a named file that does not exist **refuses the install**, with the entry's `file:line` and the words. There is no flag to install past it: the fix is to re-read the rule and rewrite the entry, which is a one-line edit to a file the user owns.
5. **`--replace-agents` keeps its meaning.** An installed `AGENTS.md` that differs from the source is still refused without it; the guide now says where the tailoring goes first.
6. **A template lives at `templates/playbook-local.md`** and is never installed by the script; `INSTALL.md` offers it.

## Alternatives rejected

- **A local file inside each skill folder.** The installer moves the whole folder into the checkpoint; the entry would vanish at the first update. Teaching the installer to carry files across is new write logic in the repository's risk-class file, for no gain over a file it simply never touches.
- **An unmanaged local *skill*.** A skill loads when its description matches the task; a customization that must always hold cannot depend on that.
- **Copying the local file into the checkpoint.** Harmless, but restore would then have to decide whether to apply it. A file the scripts never touch needs no such decision.

## Consequences

- An update can no longer lose a user's customization, and the installer's write paths did not grow: the change to `install.sh` is one read-only preflight.
- Reading the local file costs one tool call per session.
- The check catches a rewritten sentence, not a changed meaning elsewhere in the rule; the update guide lists from the changelog every rule an update touched that the user overrides.
