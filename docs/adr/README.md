# Architecture decision records

| ADR | Decision | Status |
|---|---|---|
| [0001](0001-separate-codex-native-repository.md) | Publish a separate Codex-native repository | Partially superseded by ADR 0002 |
| [0002](0002-progressive-disclosure-rulebook.md) | Preserve all 49 source rules through a lean router and sixteen skills | Accepted |
| [0003](0003-non-blocking-review-pipeline.md) | Port the non-blocking review pipeline (source 0.1.14): rule 3.5 as the fiftieth rule, a capability-based roster with one owner and a Strong tier | Accepted; amended by ADR 0004 |
| [0004](0004-port-repaired-after-deep-review.md) | Repair the port after its deep review failed it: the ceiling as an admission rule with normative worked cases (source 0.1.15), an installer preflight for nested files, rules own assignments and the roster owns selection | Accepted |
| [0005](0005-the-local-layer.md) | Customizations live in one local file the installer never touches: `playbook-local.md`, three kinds of entry, and a mechanical staleness check that refuses the install | Accepted |
| [0006](0006-verifiable-local-overrides.md) | Bind every local Override to a unique Markdown section, digest, and minimum-length quote | Accepted; supersedes ADR 0005's staleness-check portion |
| [0007](0007-local-layer-restore-compatibility.md) | Preserve external local symlinks but refuse links into replaced destinations; restore only a checkpoint with the complete known active router | Accepted |
| [0008](0008-local-layer-chain-and-transaction-rollback.md) | Guard every local-file path hop through managed destinations and use exact originals for install rollback | Accepted |
