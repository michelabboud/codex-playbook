# Local-layer source publication receipt — 2026-09-23

Codex Playbook 0.1.6 was published to the repository's source host after
Claude Playbook `checkpoint/0.1.16` was verified there. The final Codex source
commit was `a5d41bc46e9ef7f9fba58d041ebc10623306dfac`. A direct remote
check after push found `main` at that commit and the peeled annotated
`checkpoint/0.1.6` tag at the same commit. The tag object was
`a7b8afe06c6740c4364ab102b304a8be05260cf4`.

The tagged tree's `./scripts/verify.sh` exited 0: 56 rulebook checks, 217
local-layer assertions, and 673 installer lifecycle assertions passed.
Ignored raw output is preserved at `logs/reviews/a5d41bc-full-verify.log`.
The managed and executable source tree at the tag is byte-identical to the
reviewed `267dfb5`; the intervening commits changed only status, parity,
changelog, and review documents. The pre-push diff check exited 0. Review
evidence and limits are in
`docs/reports/2026-09-23-local-layer-publication-readiness.md`.

This confirms source hosting, not a package release, live installation,
private-rule sync, native macOS acceptance, or concurrent-adversary safety.
No other repository, evidence log, worktree, or user file was cleaned or
modified as part of this publication receipt.
