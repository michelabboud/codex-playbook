# v0.1.0 release-candidate review

**Date:** 2026-09-16

**Version:** 0.1.0

**Reviewed change set:** `9dbb8ecd638c4afbe23132d71738f26fa50ca91a..4d714f16d9b7466128d780f35bd3ab33957cea14`

## Evidence

- `./scripts/verify.sh` passed every structural, path, link, skill, rule-map,
  whitespace, and functional check.
- `tests/install_test.sh` passed 73 isolated lifecycle assertions covering first
  install, refusal, explicit replacement, custom `CODEX_HOME`, immutable
  checkpoints, restore, incomplete source, backup failure, cleanup failure,
  staged-copy failure, swap failure, rollback failure, and TERM interruption.
- All shell programs passed both `sh -n` and `dash -n` syntax validation.
- `git diff --check` reported no whitespace errors.
- GitHub private vulnerability reporting returned `enabled: true`.
- The earlier browser review remains applicable because no visual asset, HTML,
  CSS, or JavaScript changed in the correction change set.

## Findings resolved

- Installation never replaces a managed destination before a complete,
  read-back-verified checkpoint exists.
- Different global rules are refused unless replacement is explicit.
- Install and restore stage payloads before mutation and recover from copy,
  allocation, swap, verification, rollback, and interruption failures.
- Personal skills use `$HOME/.agents/skills`; global rules honor `CODEX_HOME`.
- The source adaptation report names doctrinal differences instead of claiming
  one-to-one Claude parity.
- The security reporting channel named by `SECURITY.md` is enabled.

## Independent verdict

No Critical or Important findings remain. Approved for the `v0.1.0` commit,
tag, GitHub release, and Pages publication.
