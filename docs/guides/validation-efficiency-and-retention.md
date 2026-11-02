# Validation efficiency and retention

Use focused feedback while developing and one broad validation run for a coherent
batch. Preserve the evidence needed to assess it without retaining a full working
copy for every successful case. Rules 2.2, 3.1, 6.1–6.2 and 13 remain authoritative.

## Checks without repeated full builds

A compact check matrix belongs in the existing task/batch record, not a new service:

| Work | Per-task feedback | Batch evidence |
|---|---|---|
| Independent changes in one subsystem | Changed behavior and immediate consumers; affected build/lint | One broad suite on the frozen integrated candidate |
| Documentation-only change | Relevant packaging/link checks; no tests over prose | Existing repository verification when required |
| Shared API or dependency change | Affected consumers and compatibility checks | Broader integration coverage before dependent acceptance |
| Security floor, unsafe code, data-loss risk | Required task-level checks and review | Never delayed to fill a batch |

Use the existing 5–15 tasks / roughly 2,000 changed lines as a ceiling for independent
low-risk work. Finish smaller batches when the work ends or dependency/risk makes
waiting costly. One validation owner runs broad checks; mechanical and deep reviewers
independently inspect the same source and verify that owner's receipts. They run
focused checks for doubts and findings, and independent execution when required.
Receipt reuse is not two independent test runs. A local Task Orc requirement for an
accepted prerequisite still governs admission; batching cannot pipeline past it.

For each receipt, name candidate/input hashes, commands, toolchain/configuration,
status, raw output and scope. Record broad checks as pending until run. After edits,
rerun impacted checks and required full gates; do not relabel an old candidate's pass.
No task checkpoint, source review or cache substitutes for integrated acceptance.

## Separate records from working files

An example layout for new runs (names confer no deletion authority):

```text
validation/
  snapshots/<candidate>/      # one immutable input, owner and references recorded
  cache/<compatible-scope>/   # owned build/dependency cache, no conflicting writers
  runs/<run-id>/
    evidence/                # receipts, raw logs, reports, unique reproduction inputs
    scratch/<case-id>/        # isolated generated case working data
```

Keep mutation tests isolated by ordinary copies or verified copy-on-write. Do not
use writable shared trees or hardlinks. A build cache must match the command's
inputs/configuration and preserve reviewer/concurrent-build isolation. Worktrees
retain their existing git removal checks. State, databases, logs and user files
remain protected even inside `scratch`.

Before a large run, estimate fixture count times per-case size and record a storage
budget from measured similar work and available disk. It is advisory: exceeding it
triggers inspection, not deletion or a new permission gate. Prefer reducing new
copies over moving the problem to RAM. At close-out, record allocated retained
bytes, measurement method, bytes actually reclaimed, and the largest retained groups
with owner, reason, regeneration command (or unavailable inputs), and next review
date/event. Count shared storage once; copy-on-write/logical sizes can overstate
physical savings. This can be a short table in the existing close-out.

Preserve raw failed, interrupted and inconclusive results and unique reproduction
inputs. Successful-run records also stay. Classify generated fixtures individually;
only verified disposable/idle output may be removed under existing authority.
A log does not make every sibling source copy evidence, but no recursive cleanup may
remove that log. Existing retention promises cannot be retroactively dismissed.
Compression does not reclaim original bytes without separately authorized removal.

## Why this change

A read-only Genie inventory on 2026-11-02 measured roughly 90 GiB in its validation
state directory. The largest run group was 37 GiB, including a 7.3 GiB Rust target;
four publisher matrix runs together held 7.7 GiB, with individual source copies near
19 MiB. Two Python environments were about 1.4 GiB each. These are rounded observations,
not a deletion inventory or measured savings. Repeated source snapshots and retained
fixtures multiplied across runs while evidence, scratch and held worktrees shared a
parent directory. This policy prevents new accumulation; it neither cleans that
historical directory nor changes Genie's test harness.
