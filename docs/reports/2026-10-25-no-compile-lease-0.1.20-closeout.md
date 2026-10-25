# Compile-lease removal: 0.1.20 close-out

## What changed

Rule 9.7 admits single-crate and workspace-wide heavy work from current host
measurements without a compile-lease prerequisite. Load bands, available-memory
floor, disk hygiene, bounded concurrency, ownership and foreign-process
protections remain. The site, version carriers and regression checks agree.

Michel requested both source publication and local installation. The local
machine notes were also reconciled so they do not reinstate the removed lease
rule. Original bounded Cargo-job guidance remains; historical bridge command
examples are explicitly not build admission requirements.

## Verification evidence

Source pin: `e15f1c99b55d37abbd0e79c7a9e8401b155ee9d0`.
`./scripts/verify.sh` exited 0: **244 rulebook checks, 217 local-layer assertions,
789 installer lifecycle assertions and 24 dashboard tests**. The first run
found a missed PROGRESS version field, corrected before the tested source pin;
its failed log is retained beside the successful second log.

[Mechanical review](../reviews/2026-10-25-no-compile-lease-mechanical-e15f1c9.md)
and [deep review](../reviews/2026-10-25-no-compile-lease-deep-e15f1c9.md) accept the
same pin with no actionable findings. Fresh native GPT-6.1 Sol contexts at high
and xhigh respectively; same-family independence, not provider attestation.
Root validated both reports and owns all execution.

The public raw VERSION returned 0.1.20 after publication. Remote checkpoint
read-back peels to the tested source pin. `scripts/install.sh --replace-agents`
exited 0 and reported 0.1.20, the global router and 20 managed skills. Installed
router and every managed skill directory match source byte for byte, retired
skills remain absent, and the personal local-layer check passes all three
existing override anchors. No local-layer edit was made.

Private evidence is retained under
`~/.local/state/codex-playbook/2026-10-25-no-lease/`: verify-01.log (failed),
verify-02.log (passed), install-01.log and the before/final machine-note copies.

## Assumptions made

Removing the lease requirement locally includes reconciling the machine notes
that supplied it. This changes admission policy only; no other session's lease,
process, project files, data or service was touched. The bounded concurrency
advice remains. The user's explicit request to update locally authorizes the
backup-first managed replacement; no redundant permission exchange was added.

## Concerns and hygiene

No new blocker or deferred defect. No caches, old worktrees, branches, logs or
backups were removed; zero bytes reclaimed. The test suites dispose of their
own synthetic fixtures. Both test processes and review lanes finished; this
Playbook task leaves no watcher, server or other long-running process.

## Close-out confirmation and recovery

Source version is 0.1.20. Published annotated `checkpoint/0.1.20` points at the
reviewed/tested source pin; subsequent commits record reviews and installation.
No phase release, v tag or GitHub release is claimed by this bounded task.

Verified installer recovery checkpoint:
`~/.codex/backups/codex-playbook-preinstall-20261025T201301Z-wTZus2`.
Restore with:

```sh
./scripts/restore.sh ~/.codex/backups/codex-playbook-preinstall-20261025T201301Z-wTZus2
```

The separately verified machine-note backup is
`~/.local/state/codex-playbook/2026-10-25-no-lease/machine-before.md`; restore only
that file if reverting the local machine-note policy. The installer does not
manage it or the owner's playbook-local.md.
