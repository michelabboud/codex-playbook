# 0010 — Approvals are destructive-only

- **Status:** accepted, 2026-09-30 (the owner: "global agent has rule to ask for approvals all the times which make working with codex a horrible experience, please remove all these requests for approvals; only keep the non-destructive actions prevention").
- **Scope:** `AGENTS.md` approval table; rules 7.1, 7.2, 9.3, 10.2 and the first-publish sentence in section 6.

## Context

The Codex edition inherited the source rulebook's approval table: plans and
architecture changes, first publication, new datastores and system, security or
performance configuration all said "ask". In Codex every ask is a stopped turn
plus, under `on-request`, a harness prompt on top. The owner found the result
unworkable, and an installed `~/.codex/AGENTS.md` had already been hand-edited
to the same effect (unversioned, so the next update would have erased it, and
the skills still said "ask" underneath it).

## Decision

Only destructive actions need the owner's OK. Everything else is decided,
recorded (`PLAN.md`, an ADR where rule 4.2 applies, the close-out) and executed.
Kept whole: rules 10.1-10.2, refusal-is-stop, quarantine, worktrees through git,
the self-update replacement gate, review gates (they are not approvals), and the
local layer's ban on weakening the destructive-action gate.

## Alternatives rejected

- **Leave it to a local layer.** A local entry may not remove an approval, and
  that ban is right; the default itself had to change.
- **Keep a lighter plan gate.** A go on the plan is exactly the stall the owner
  described; the plan is written down and executed.
- **Edit only `AGENTS.md`.** The skills load later and said "ask", so the
  router paragraph and the skills would have disagreed.

## Consequences

- Publication to a registry, a native datastore and system configuration are
  no longer asked about. The owner accepts that; each is named in the close-out.
- A harness sandbox prompt is not this rulebook's and is untouched: only
  `approval_policy` in `config.toml` changes those.
- The source (Claude) edition is unchanged and still asks.
