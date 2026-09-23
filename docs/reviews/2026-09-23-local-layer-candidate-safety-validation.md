# Local-layer candidate safety review and validation — 2026-09-23

**Status: FAIL for reviewed commit `01c6e9a`; the repair below is not yet reviewed.**

The independent read-only reviewer inspected pinned commit `01c6e9a`
(base `43a5580`) and ran its lifecycle, checker, and rulebook suites on the
pinned archive: 592, 217, and 56 assertions respectively, each exit 0.
Syntax and diff checks exited 0. The reviewer reported pre-existing
ShellCheck warnings rather than a new lint pass. The review was not blind to
the previous findings because its context inherited the coordinator's turn;
the next GPT-6 Sol review will use a fresh brief.

## Confirmed blocker

Both `scripts/install.sh` and `scripts/restore.sh` captured their checkout
root through shell command substitution of `pwd`. A trailing newline in the
checkout directory name was stripped, so a sibling directory without it
could be selected as the source. The reviewer reproduced this in a disposable
scratch checkout. This was present before `01c6e9a` but was not protected by
its new path-encoding checks. It is a source-integrity failure, not an
acceptable unsupported-name warning.

## Coordinator validation and repair state

Focused absolute, relative, and symlink-alias invocation fixtures reproduced
the sibling selection before the repair (exit 1), then passed after both
scripts validated their own invocation path before resolving the repository
root with a delimiter-preserving physical-path helper. The post-repair full
local run passed 56 rulebook, 217 checker, and 622 installer lifecycle
assertions; each suite exited 0. Deliberate restore's strict known-router
test is unchanged. The fixed candidate still needs independent GPT-6 Sol
review before any tag or push.
