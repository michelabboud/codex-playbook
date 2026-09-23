# GPT-6 Sol reviews of the held Codex candidate — 2026-09-23

**Reviewed commit:** `fd2443f` (base `01c6e9a`). **Combined verdict: FAIL.**
The repair worktree described below is not yet reviewed.

Two fresh read-only GPT-6 Sol agents inspected pinned archives. The mechanical
pass found no blocking defect and returned PASS; the deep pass returned FAIL
with the confirmed data-safety finding below. Both ran the rulebook, local
checker, and installer suites with direct exit 0; the installer had 622
assertions. Shell syntax and diff checks exited 0. ShellCheck remained nonzero
on warnings present in the base candidate. No native macOS run or actual
installation of user files was performed.

## Confirmed blocker

The installed `playbook-local.md` can be a symlink through an intermediate
symlink under a managed skill to an external file. Both install and restore
guarded only the final external target. The deep reviewer reproduced an
install that exited 0, replaced the skill directory, removed the intermediate
symlink, and left the unchanged local-file symlink dangling. The external file
survived but the owner's local rules became unreadable. The preflight must
reject a chain dependent on any managed destination that will be replaced,
while continuing to accept an independent external dotfile-manager symlink.

## Other results and repair state

The prior checkout-newline source-path repair held in absolute, relative, and
symlink-alias tests. Model prices and agent/Herdr guidance were checked against
current primary documentation with no blocker found. The mechanical pass
found one minor changelog mismatch: it claimed Claude-native modes were in the
Codex guide. That line is corrected in the current worktree. The symlink-chain
repair and its red-to-green install/restore tests are implemented locally;
a new pinned GPT-6 Sol deep re-review is required before any tag or push.
