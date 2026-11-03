# Efficient Codex operations

Checked 2026-11-03 against Codex CLI 0.166.0, this repository and official OpenAI
documentation. These are operating procedures, not an empirical speed benchmark.

## Model choice

Start a comparison with **GPT-6.1 Sol at medium effort** as coordinator; use high
for ambiguous integration, and reserve xhigh for a named hard decision or review.
This is a recommendation to test, not a silent change to the owner's binding.
Sol low can suit mechanical routing after decisions are settled. A Terra high or
xhigh run is not automatically a better coordinator simply because effort is high.
The [official model guide](https://learn.chatgpt.com/docs/models#recommended-models)
positions Sol for complex, repeated long-running work and Terra for efficient
writing, visual understanding and computer use. It does not establish which wins
on this owner's projects. The [subagent documentation](https://developers.openai.com/codex/subagents)
recommends Sol for demanding multi-step agents and notes that higher reasoning
effort increases response time and token use.

Keep the same bounded task mix and acceptance criteria when comparing settings.
Record time to accepted result, tokens where exposed, rework, repeated checks,
missed checkpoints and escaped defects. Include failed runs. Compare accepted
deliverables per elapsed time and cost, not tokens per minute or raw draft volume.
Do not promote a model from one anecdote or invent unavailable usage metrics.
Current local model restrictions remain effective until explicitly reconciled.

## Visibility inside Codex

In the CLI, use `/subagents` to inspect/switch agent threads. In the app, open the
subagent thread from the main thread's activity. Ask the coordinator for:

> Show completed/total tasks, running owners and models, the current operation,
> last evidence-producing progress, next checkpoint, blocked dependencies, and
> the remaining acceptance gates. Inspect any missed checkpoint now.

These controls are documented in [Subagents](https://developers.openai.com/codex/subagents).
Client surfaces and account availability differ. A thread marked running does not
prove useful progress. Tool-call cards such as “Waiting for agents” are generated
by the client; the rulebook can reduce redundant waits, not control their rendering.

## Shared dashboard

Use the [shared board guide](shared-build-dashboard.md). The default Linux view is
`~/.local/state/build-task-dashboard/tasks.html`; invoke the packaged helper's
`open --again` only if the previous window was closed. On WSL, use the helper's
Windows-aware opener rather than a Linux file URL in a Windows browser.

The board shows task counts, owners, decisions in notes, per-task age and stale
active tasks independently from session updates. Remaining means all tasks except
done/cancelled; failed and blocked work remains outstanding. Counts are not a time
estimate. Refresh and inspection are not evidence-producing progress. Post real
transitions, actual check results and the next checkpoint, never fake heartbeats.

This is a reported-state board. It neither watches native processes nor sends an
alarm after Codex stops. For unattended runs, the next useful alternative is a
small external observer of the existing client's runtime events and task ledger,
with desktop alerts for missed checkpoints. The [App Server API](https://learn.chatgpt.com/docs/app-server)
documents thread status and turn events; an adapter must verify the installed
client's protocol and access to the actual running server. Starting another server
does not establish visibility into the first one's live processes. Do not claim
this watchdog exists, or automatically terminate agents, from a static dashboard.

## Stalled agents and abandoned worktrees

| Observation | Meaning | Action |
|---|---|---|
| No task update for ten minutes | Unconfirmed activity | Inspect native status and last output; request a concrete handback |
| Same failure twice with no new evidence | Approach stalled | Change method or escalate with both receipts; preserve failed gate |
| Known long build, observed activity | Possibly healthy | Record process/job identity and the agreed longer checkpoint |
| Native terminal failure or confirmed exit | Agent finished/failed | Inspect children and output; a compiler may survive its parent |
| Old worktree or Git lock | Historical ownership clue | Resolve owner and retained work; neither age nor lock proves liveness |
| Missing access/process evidence | Unknown | Preserve the affected resource; state the exact missing observation |

Start with these read-only commands on the repository and one candidate at a time:

```sh
git worktree list --porcelain
git -C /absolute/candidate status --short --ignored --untracked-files=all
git -C /absolute/candidate for-each-ref --contains HEAD refs/heads refs/tags
git -C /absolute/candidate reflog
```

Review ignored content by type without printing secrets. Inspect the recorded
process ID and start time, its children, cwd/open files and runtime terminal state.
For Linux, `ps -p PID -o pid,ppid,lstart,etime,stat,comm` avoids dumping command-line
secrets. `lsof +D /absolute/candidate` can be expensive and incomplete; no output
alone is not proof of idleness. PIDs can be reused. A dead parent does not prove
all children stopped. Do not blanket-kill `node`, `cargo` or `codex` processes.

Then classify separately: source/unique commits, state/secrets, durable evidence,
and regenerable output. Verified idle compiler output may be removable even when
the source worktree must stay. Removing a whole worktree requires the Git checks,
resolved ownership, preserved ignored/protected contents and no live consumers.
Use `git worktree remove` without force only after those checks and applicable
authority. A foreign lock requires its owner's handoff; do not unlock by age.

## Storage and cleanup outcomes

Record paths before creating them. Keep new worktrees/build output in the
established native-filesystem project layout; never silently spill to `/mnt/d`,
another mount or RAM. A specific owner destination instruction can select a
different disk. Capacity shortage requires measured cleanup or a precise capacity
blocker, not a surprise relocation.

Every large artifact ends with one of: removed with measured bytes; retained with
specific evidence/reference and owner; or blocked by an identified failed check.
“Might be useful” warrants an inventory, not indefinite blanket retention. Existing
logs, state, failure inputs and user files retain protection. Quarantine preserves
data but usually frees no space on the same filesystem. Creating both compressed
and original logs also does not reclaim their original bytes.

The 2026-11-02 receipt records installation of 0.1.21 and only 2.96 GiB reclaimed
from Genie compiler intermediates. It is not evidence that historical cleanup
across projects completed. This revision creates no automatic cleaner and performs
no cross-project deletion.
