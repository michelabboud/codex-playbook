| # | State of the line | What may happen next |
| 1 | N closed and unruled; N+1 building | Normal. Keep building. |
| 2 | N and N+1 closed and unruled | N+2 may start — announced loudly: the review lane is in trouble. |
| 3 | N and N+1 closed and unruled; N+2's last task lands | N+2 closes and its deep review is dispatched — three closed and unruled. **No new batch starts** until one is ruled. |
| 4 | Three closed and unruled; N is then ruled | Two remain. N+3 may start. |
| 5 | Lines X and Y both inherit unruled A; Y also carries unruled B; they merge | The merged line carries `{A, B}` — two, not three. |
| 6 | The union after a merge would exceed three unruled batches | The merge waits until enough are ruled. |
| 7 | A line of work is cut from the middle of batch A, open or in review | It inherits A as it stood at the cut and starts at one. A stays the batch of the line that opened it; work on the new line is a new batch, admitted there. |
| 8 | Commits of unruled A are cherry-picked or squashed onto line Z | Ancestry does not show it. Record A against Z in the ledger, or treat the copy as new work owing its own review. |
| 9 | A's blocker is fixed on line X and the fix's focused review is validated; line Y also carries A | A is ruled for X only. Y carries it until the fix is reachable from Y. |
| 10 | A milestone is reached; one task's mechanical review died or timed out | The gate does not start. The review is re-run, or explicitly superseded. |
| 11 | A mechanical review returns a blocking finding | Stop the line, exactly as for a deep review's blocker. |
| 12 | A gate is running; a docs fix is ready | It lands on a line not merged into the candidate, in a batch admitted there — ad-hoc if the plan has none — owing its normal reviews. Merging it restarts the candidate's checks and review. |
| 13 | N and N+1 in review; N+2 open; another batch is proposed | It waits: the line already carries three, and one batch is open per line. |
| 14 | Rule 3.2 closes a batch early while a task allocated to it is still running — at any count | The task may finish. Its result belongs to the next batch: preserved, and accepted only once that batch is admitted. |
| 15 | Three unruled, none open; a merge that carries no fix is proposed, and its union stays three | The merge waits: nothing lands outside a batch, and none can be admitted. |
| 16 | Three unruled, none open; the fix for N's blocker is ready | It lands, attached to N: only the changes necessary to resolve the recorded finding. N is ruled once a focused review of N's pinned target plus its fixes is validated. |
| 17 | A task of open batch A runs in its own worktree | That worktree is not a line. Its result lands on the line it was dispatched from, as part of A. |
| 18 | An authorized hotfix or docs correction that no plan covers is ready | With a batch open, it belongs to that batch. With none open and at most two unruled, the coordinator names an ad-hoc batch in the ledger and admits it — same reviews owed, no new approval. At three, it waits unless it is the fix for a recorded finding. |
| 19 | Line Y's batch B is still open; Y is proposed for merge into X | The merge waits until B closes: an open batch has no pinned target. |
| 20 | A state that no sentence and no row covers | Resolved toward review: the work counts as unruled, belongs to a new batch, and waits at three. Record the case in the ledger. |
