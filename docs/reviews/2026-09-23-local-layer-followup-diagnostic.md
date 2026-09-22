# Local-layer follow-up diagnostic — 2026-09-23

**Candidate reviewed:** `5644fba` (local main, not published).  **Verdict:** FAIL.  This is a focused deep review of the local-layer repairs, not batch acceptance or a release review.  The reviewer inspected Git objects; it did not run the test suites.  A separate mechanical re-check of `2e05e55` also returned FAIL on the restore-shadowing issue.

## Blocking findings and disposition

1. **Restore can deactivate a preserved local file through a global override.** A non-empty `AGENTS.override.md` shadows the restored global router.  Fixed locally in `94e38dd`: restore now refuses before checkpoint or destination writes, with six lifecycle assertions.
2. **A supported symlinked local file can point into a managed skill directory.** An install or restore can replace that directory and leave the local link dangling.  The content survives in the recovery checkpoint, but the customization becomes inactive.  Still open.  The existing checker explicitly supports links for dotfile managers (`tests/check_local_test.sh`, `run_symlinked_local_file_test`).  The proposed compatibility-preserving repair is to refuse only when the resolved local target lies inside a managed destination; this is a trust-boundary choice awaiting owner approval.
3. **Restore's loader proof can match text inside a fenced example.** Its `awk` search recognizes a paragraph under `## Authority` without proving that the paragraph is active instruction, so a crafted checkpoint can make a local file inert.  Still open.  The proposed repair is to accept a known local-layer-capable router, not a paragraph match; this compatibility/trust-boundary choice awaits owner approval.
4. **Markdown-shaped Overrides can be silently skipped.** Split-bold and Unicode-lookalike lead-ins escaped the checker.  Fixed locally in `94e38dd`: both cases now refuse with exit 2, and the full verification suite passed (56 rulebook, 217 checker, 403 lifecycle assertions).
5. **Trailing heading blanks broke the anchored-section comparison.** Fixed locally in `2e05e55` and covered by the checker suite.

The green suite does not overrule the two still-open findings.  No model update, tag, or push is justified by this diagnostic.  After the owner rules on the two boundary choices, the repair needs a pinned focused re-review; the original risk-class task reviews and batch deep-review gate remain separate.
