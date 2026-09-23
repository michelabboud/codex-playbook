# Local-layer publication readiness — 2026-09-23

The Codex Playbook 0.1.6 candidate cleared its focused review gate after the
symlink-chain repair at `267dfb5a55505a639483fb99214ff4367989eb22f`.
Claude Playbook `checkpoint/0.1.16` was published first: its remote `main` and
peeled tag both pointed to `97938d0c874b651a7ab1b44b002b289c5c378caa`
when checked on 2026-09-23. This report records source-publication readiness,
not native macOS acceptance or a live Codex installation.

## Review disposition

The GPT-6 Sol mechanical review of `fd2443f` passed. The paired deep review
failed on a local-file symlink chain through a managed skill: replacing the
skill could leave the preserved local file dangling. The coordinator accepted
the finding. The repair at `267dfb5` guards intermediate file and directory
symlinks for both install and restore, while preserving independent external
dotfile-manager chains. A fresh focused GPT-6 Sol deep re-review passed with
no blocker. Reports are
`docs/reviews/2026-09-23-gpt6-sol-symlink-chain-reviews.md` and
`docs/reviews/2026-09-23-gpt6-sol-chain-re-review-pass.md`.

The assignments requested GPT-6 Sol; the child runtime did not expose an
independently verifiable model ID or effort level. The verdicts are therefore
reported with their requested routing, not as runtime attestation.

## Verification and limits

- `./scripts/verify.sh` on the final documentation candidate exited 0:
  56 rulebook checks, 217 local-layer assertions, and 673 installer lifecycle
  assertions. Full output is preserved outside Git in ignored
  `logs/reviews/codex-0.1.6-final-verify.log`.
- Before the final administrative commit, `git diff --exit-code 267dfb5 --`
  over the managed rules, installer, scripts, skills, templates, tests,
  configuration, and version exited 0. `git diff --check` exited 0.
- Linux fixture validation does not prove native macOS behavior, a fresh
  client session loading the local file, or safety under a concurrent
  adversarial symlink swap. No live installation, restore, or uninstall of
  the owner's files was performed.

## Publication boundary and hygiene

The final administrative commit may add only status, parity, changelog, and
review-readiness documents. Compare the managed and executable tree with
`267dfb5` again at that commit, confirm remote `main` has not advanced and
`checkpoint/0.1.6` is unused, then tag and push only this repository. Verify
both remote refs directly afterward. This does not authorize a package
registry, live deployment, private-rule update, or another repository change.

Disk had 115 GB free, above the 40 GB dispatch floor. Ignored raw logs and
review scratch remain preserved; reports and documentation are committed.
