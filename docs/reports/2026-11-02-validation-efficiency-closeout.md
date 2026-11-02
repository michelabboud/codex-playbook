# Validation efficiency and retention — 0.1.21

## What was built

Focused task feedback, broad checks once per coherent batch, one validation owner and independently reviewed shared receipts. The existing 5–15-task / roughly 2,000-line bounds remain ceilings, with risk and accepted-prerequisite gates intact. Durable records are separated from disposable working data at creation; source/environment duplication is avoided where isolation permits. Retained bytes, reasons and review events are reported within existing close-outs. No automatic cleaner was added.

## Verification evidence

Policy candidate `a6696de7a7828d480aad50a4f96e56dfbec179ae`; corrected successor `8c15e29f73781e0ce7a41f428a76665e3342201e` changes only the PROGRESS current-version field. Combined verifier exited 1 due to that stale field (version carrier and rulebook aggregate failures). Its 217 local-layer assertions, 789 installer lifecycle assertions and 24 dashboard tests passed. Focused rulebook rerun exited 0 with all 244 checks; all five public version carriers also passed direct assertions. The unchanged suites were not rerun for a prose version correction. This is composed evidence, not a claim that the first combined invocation passed.

Evidence: `~/.local/state/codex-playbook/20261102-validation-retention/verify-01.log`, `rulebook-02.log`, and `local-compatibility-01.log`. No new tests over prose, no changed executable code, no visual-layout changes. Final record-only edits receive diff/link checks rather than another installer cycle.

## Assumptions made

One bounded policy task in the existing solo main workflow, not a phase release. The user's added speed request is implemented as batching and removal of redundant validation, never skipped required gates. No Genie harness changes, data cleanup, or wholesale installed-policy replacement were included. Two fresh same-family reviewers received the same source pins and shared test receipts: requested GPT-6.1 Sol high for mechanical and xhigh for deep. Requested configurations are not provider attestation. Tokens are unavailable; no review ceiling was reached.

## Concerns and hygiene

The personal local-layer compatibility check exits 1: line 35 anchors the review section's old digest. The Task Orc accepted-prerequisite constraint is preserved in policy; the owner file remains untouched and requires deliberate reconciliation before installation. No claim of local activation or measured development speed/storage savings is made.

Root retained approximately 112 KiB allocated in the evidence directory (`du -B1 -s`, 114688 bytes at measurement), covering the original failure, corrected check and local compatibility failure. Owner: this task's coordinator. Reason: publication and compatibility evidence. Review event: next explicit installation or retention audit. Logs are non-regenerable execution records. Zero bytes reclaimed; no prior artifact, worktree or cache removed. Test harnesses disposed of their own synthetic fixtures. No watcher/server was started.

## Close-out confirmation

Source version 0.1.21; checkpoint publication follows accepted reviews. No release tag, live deployment or installed-policy activation is claimed. See persisted mechanical/deep review records. Shared dashboard: `~/.local/state/build-task-dashboard/tasks.html`, run `validation-retention-20261102`, session `01a19a1b-2cf0-7413-aec5-cc1154bccea1`.
