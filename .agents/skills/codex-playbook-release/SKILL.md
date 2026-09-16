---
name: codex-playbook-release
description: Close a completed task or phase with verification, documentation, version allocation, commit, immutable tag, push, dependency audit, and GitHub release evidence.
---

# Task and release close-out

Use this procedure when a task or phase is ready to close. It implements the
standing workflow in `AGENTS.md`; it does not broaden the task or add approval
requirements.

## Task checkpoint

1. Confirm the requested outcome is complete and inspect the full diff.
2. Run the narrow checks for the changed behavior, then every repository-required
   test, build, lint, and formatting check. Quote the decisive output.
3. Update affected documentation, including `CHANGELOG.md`, `PROGRESS.md`, and
   architecture or usage guides. Record discovered but out-of-scope work in
   `BACKLOG.md`.
4. Read `VERSION` immediately before allocation. Choose the next unused semantic
   version according to the repository's release policy.
5. Update every current version carrier in the same change and verify they agree.
6. Commit once with the configured identity. Create the repository's checkpoint
   tag from `VERSION`; never move a published tag.
7. Push the commit and tag. On a shared repository, push the feature branch and
   open the pull request instead of pushing `main`.
8. Deliver the five-part close-out report required by `AGENTS.md`.

## Phase release

1. Confirm every planned task and review is closed.
2. Merge with a true merge commit when work used branches; never squash a phase.
3. Run the ecosystem dependency audit and resolve every fixable advisory.
4. Repeat the complete verification suite on the exact release commit.
5. Create `v<VERSION>`, push it, and create a GitHub release with browsable notes
   covering behavior, verification, advisories, migrations, and known limits.
6. Verify the tag, release, and default branch all resolve to the intended commit.

Do not claim completion from earlier output. Release evidence must be fresh and
must describe the exact commit being published.
