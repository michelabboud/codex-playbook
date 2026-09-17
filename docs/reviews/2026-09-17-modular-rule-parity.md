# Modular rule parity review

**Date:** 2026-09-17

**Version:** 0.1.2

**Reviewed change set:**
`1a4207d2eb8a57fb8c91bfc3c3d96e2420d81dc4..fd3de7a8918f8d69f1704504aaac89266330ac81`

**Pull request:**
[`michelabboud/codex-playbook#2`](https://github.com/michelabboud/codex-playbook/pull/2)

## Scope

Two independent deep reviews inspected the migration from the initial Codex
rulebook to the complete 49-rule modular adaptation. One review compared every
source rule, ownership declaration, public claim, and visual rule entry. The
other reviewed installation, restoration, checkpoint compatibility, rollback,
path handling, metadata preservation, and test quality.

## Findings resolved

- Corrected the documented count of skills removed by a format-1 restore.
- Documented every environment variable read by the scripts and tests.
- Corrected the README upgrade sentence and removed an unsupported visual-site
  claim.
- Rejected malformed checkpoint completion markers and duplicate or invalid
  manifest state entries before restoration can mutate live state.
- Rejected `CODEX_HOME` overlap with managed skills and ambiguous `.` or `..`
  paths, including the reproduced symlink-plus-`..` bypass.
- Preserved original global-rule, skill-directory, and skill-file modes across
  backup and restoration.
- Replaced random-name sorting in tests with the exact checkpoint paths reported
  by install and restore commands.

## Evidence

- The specification review found no missing or misplaced source rules and no
  regression in the Codex-native router/skill architecture.
- The final safety review confirmed every reported data-safety defect has a
  meaningful regression test.
- `./scripts/verify.sh` passed all 43 rulebook checks and all 269 installer and
  restore lifecycle assertions on the exact reviewed commit.
- `sh -n`, `dash -n`, and `git diff --check` passed. `shellcheck` was unavailable
  on the host and was not installed as an undeclared tool dependency.
- No package manifests or third-party dependencies exist, so a package-manager
  dependency audit is not applicable.

## Independent verdict

Both reviewers approved commit `fd3de7a8918f8d69f1704504aaac89266330ac81`.
No Blocker or Important findings remain.

The runtime did not expose per-agent token counts. Model ledger: three initial
analysis passes and two independent final reviews ran on `gpt-5.6-sol` at xhigh
reasoning; the root coordinator used the same model and reasoning tier.
