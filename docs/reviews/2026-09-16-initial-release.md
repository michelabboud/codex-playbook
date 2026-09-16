# Initial release review

**Date:** 2026-09-16

**Version:** 0.1.0

**Reviewed commit:** `9dbb8ecd638c4afbe23132d71738f26fa50ca91a`

## Scope

The independent review inspected the complete initial repository, its install
instructions, static site, and release readiness before the first push.

## Verified strengths

- The exact reviewed commit passed its structural verifier, shell and JavaScript
  syntax checks, skill metadata validation, and 42-rule site mapping.
- Desktop and mobile browser checks passed; search returned the intended rule;
  the console contained no errors or warnings.
- The repository structure, public documentation, original hero, and visual
  system matched the approved editorial direction.

## Findings

Publication was blocked because the documented copy commands could overwrite an
existing global `AGENTS.md`; backups reused one directory and could hide
failures; `CODEX_HOME` was promised but ignored; and personal skills targeted a
deprecated location. The review also identified an overstated parity report, a
disabled private vulnerability channel, insufficient functional installer
coverage, and two inaccurate architecture paths.

## Resolution requirement

The release may proceed only after safe install, update, and restore behavior is
covered by isolated tests; current Codex skill locations are used; documentation
states adaptation differences accurately; private vulnerability reporting is
enabled; and the corrected tree receives fresh verification.

## Disposition

Changes required. This record preserves the first review instead of rewriting
it as a pass after the fact. Final release-candidate evidence is recorded in a
separate review file.
