| # | State of the line | What may happen next |
| 1 | N closed and unruled; N+1 building | Normal. Keep building. |
| 2 | N and N+1 closed and unruled | N+2 may start — announced loudly: the review lane is in trouble. |
| 3 | N and N+1 closed and unruled; N+2's last task lands | N+2 closes and its deep review is dispatched — three closed and unruled. **No new batch starts** until one is ruled. |
| 4 | Three closed and unruled; N is then ruled | Two remain. N+3 may start. |
| 5 | Lines X and Y both inherit unruled A; Y also carries unruled B; they merge | The merged line carries `{A, B}` — two, not three. |
| 6 | The union after a merge would exceed three unruled batches | The merge waits until enough are ruled. |
| 7 | A branch is cut from the middle of unruled batch A | It inherits A and starts at one. |
| 8 | Commits of unruled A are cherry-picked or squashed onto line Z | Ancestry does not show it. Record A against Z in the ledger, or treat the copy as new work owing its own review. |
| 9 | A's blocker is fixed on line X; line Y also carries A | A is ruled for X only. Y carries it until the fix is reachable from Y. |
| 10 | A milestone is reached; one task's mechanical review died or timed out | The gate does not start. The review is re-run, or explicitly superseded. |
| 11 | A mechanical review returns a blocking finding | Stop the line, exactly as for a deep review's blocker. |
| 12 | A gate is running; a docs fix is ready | It lands on a line not merged into the candidate. Merging it restarts the candidate's checks and review. |
| 13 | N and N+1 closed and unruled; N+2 building; another batch is proposed | It waits. One batch is open per line; admission is checked again when N+2 closes. |
| 14 | A third batch closes while a later task is already dispatched | The task may finish. Its result is preserved, not accepted onto the line, until a ruling reopens admission. |
| 15 | The line carries three unruled batches; a merge that carries no fix is proposed, and its union stays three | The merge waits: its result is new work, and nothing new starts at three. |
| 16 | Three closed and unruled; the fix for N's blocker is ready | It lands. A fix is what rules a batch, never a new batch. |
