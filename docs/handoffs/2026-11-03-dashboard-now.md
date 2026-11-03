# All-project Now dashboard — checkpoint 0.1.24

Implementation `078b93ab8ef3c4f0d52e0f04fd85e130593a4e46` passed the full integrated
check and both independent source reviews. See the
[close-out](../reports/2026-11-03-dashboard-now-closeout.md) for exact test counts,
browser evidence, scope, models, retained bytes and installation boundary.

Now spans reported active work across projects; project tabs preserve focused
inspection. Small charts have explicit snapshot/event scopes. Current plans are
complete explicit declarations owned by project/run/session; concurrent plans,
clear events, missing plans and ended-owner provenance remain visible. This run
publishes its own plan as an actual producer demonstration.

The shared board is rendered from the source template at close-out. Global managed
rules remain 0.1.21, and older producers can still render their older template.
The previously prepared local reconciliation proposal passes against 0.1.24:
`~/.local/state/codex-playbook/20261103-dashboard/local-reconciliation-proposal.patch`.
It preserves the user's model bindings and constraints. Exact protected replacement
of the global router and 21 managed skill directories still needs owner approval;
no personal layer or installed managed package was changed by this task.

LSP's separately authorized local repair is complete and active; rollback links
and verification receipt are under `~/.local/state/codex-lsp-repair/20261103T104525Z/`.
No dashboard repository code was needed for that repair.
