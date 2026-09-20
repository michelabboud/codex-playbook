# Backlog

New work belongs here only when it is valuable, out-of-scope for the current
approved phase, and described concretely enough to become a future plan.

- **2026-09-20 · test hardening · open** — the rule 3.5 wording contract in
  `tests/rulebook_test.sh` greps the whole reviews skill; apply its required-phrase
  checks to the extracted rule 3.5, as the worked-case comparison already does, and
  keep the whole-file sweep for forbidden wording (source: Sol's fifth review,
  informational; not changed after a passing review).
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
