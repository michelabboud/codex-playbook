# Backlog

New work belongs here only when it is valuable, out-of-scope for the current
approved phase, and described concretely enough to become a future plan.

- **2026-09-21 · parity · closed by the shared ruling** — the 4,096-byte bound on
  a local-layer line existed in this edition only (informational finding I2 of
  the mechanical review). It is now a ruling for both editions, so the divergence
  is gone. This edition applies the bound to every line rather than only to a
  Dead-words line, which is stricter than the ruling requires and satisfies it.
- **2026-09-21 · parity · open** — this edition refuses an **ancestor of the local
  file that exists and is not a directory**, and an Override whose window a
  *bullet-less* `**Override` line opens, both of which the shared ruling leaves
  unspecified. Both are fail-closed readings and neither has a shared vector, so
  the two editions could diverge on them without a test noticing. Raise with the
  Claude edition; the multi-line cases cannot go in the single-line vector file as
  it stands.
- **2026-09-21 · hardening · open** — `scripts/check-local.sh` refuses a glob
  character in a file name, which also means a playbook file whose real name
  contains `*`, `?` or `[` can never be named by an Override. No file in either
  edition has such a name and none should; if one ever does, the grammar needs an
  escape rather than a relaxation of the refusal.
- **2026-09-21 · shared vectors · open** — both editions accept `, and ` as a
  join between two file names and no shared vector covers it, so nothing would
  catch one edition dropping it. The vectors file is byte-identical between the
  repositories, so adding a vector is a change to both: raise it with the
  Claude edition rather than editing the fixture here.
- **2026-09-21 · parity · open** — the Claude edition's checker ends every run
  with a machine-readable count line; this one carries the same count inside
  its human summary instead, which the vector test parses. If a third caller
  ever needs the count, adopt the source's line rather than parsing prose.
- **2026-09-21 · verification · open** — no fresh Codex session has yet been
  observed reading `playbook-local.md` at session start, or honouring a skill's
  pointer line. The mechanism is a sentence in `AGENTS.md` plus one line per
  skill, not anything the client enforces. Load a fresh session against an
  installation whose local layer contradicts a rule, and record which text the
  model follows.
- **2026-09-21 · portability · open** — `scripts/check-local.sh` and
  `tests/check_local_test.sh` were executed under GNU coreutils with `dash` as
  `/bin/sh`. `grep -F -q -e`, `grep -- <file>`, `touch -t` and `stat` are
  assessed against BusyBox and BSD userlands, not executed there. Run both
  suites in a BusyBox container and on a BSD host before claiming portability.
  The same gap is already recorded for the installer's `grep -E` patterns.
- **2026-09-21 · rule question · open** — the staleness check catches a
  rewritten sentence, not a changed meaning that leaves the quoted sentence
  standing. `INSTALL.md` and the self-update skill answer that with a manual
  changelog cross-check. Consider recording, per changelog entry, the rule IDs
  it touched, so the cross-check can be mechanical too.
- **2026-09-20 · test hardening · open** — in `tests/rulebook_test.sh` the two rule 3.5 wording
  loops pass the sentence to `grep -F` without `-e`; a future forbidden sentence that starts
  with `-` would be read as an option, error, and let the sweep pass. None of the fourteen
  current sentences does. Use `grep -nF -e` / `grep -Fq -e` (source: the 0.1.5 mechanical
  re-check, informational).
- **2026-09-20 · measurement · open** — the ceiling (three unruled batches per
  line, the open one included) in rule 3.5 rests on one friendly programme in
  the source's evidence, a behaviour-preserving refactor. Record how often a
  line reached the ceiling on real feature work before treating the number as
  settled.
- **2026-09-20 · measurement · open** — "mechanical review on Standard, never
  Fast" was measured on two Claude models. Take the same nine-defect comparison
  on the Codex configurations actually bound, and record it in the roster
  reference with its date.
- **2026-09-20 · verification · open** — whether every Codex client follows a
  relative reference into a sibling skill's directory is verified only by one
  fresh-session load. If a client does not, the fallback (the reviews skill
  invokes the subagents skill) becomes the primary route.
- **2026-09-20 · verification · open** — what context isolation real reviewer
  launches provide on this client has not been measured. Rule 3.3 asserts
  nothing beyond "record what the runtime actually provides".
- **2026-09-20 · verification · open** — the installer's inventory patterns use
  POSIX extended regular expressions and were run under GNU grep only; BusyBox
  and BSD `grep -E` are assessed, not executed (source: Sol's re-review).
- **2026-09-20 · hardening · open** — the installer's preflight assumes a
  quiescent source checkout; a source mutated between preflight and copy is out
  of scope and undefended (source: Sol's third review).
- **2026-09-20 · rule question · open** — with a Strong tier in the roster,
  should risk-domain implementation (security, concurrency, unsafe code) start on
  Strong rather than Top, keeping Top for planning and review? Wording left as it
  was.
