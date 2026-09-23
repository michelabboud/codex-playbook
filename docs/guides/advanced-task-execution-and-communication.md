# Advanced task execution and communication in Codex

Checked 2026-09-23. This guide explains available execution transports, not new authority. The approved plan and project records remain the durable ledger; the playbook's approvals, resource checks, ownership, tests, and review gates still apply.

## Make the plan executable

For every task, write down dependencies, named owner and exact file scope, worktree or directory, model and reasoning effort, expected artifact and acceptance checks, review gate, communication route, and the next unblocked task. The coordinator owns the ledger (`PLAN.md`/approved plan) and reconciliation. Give each file one writer; parallelize only independent work after host and disk checks. A task closes only after inspecting the delivered artifact and direct check results, not when a child thread becomes idle. Update the ledger and begin the next admitted task immediately. If approval, capacity, or a failed gate genuinely blocks it, record the evidence and exact decision needed; do not skip it.

## Choose the runtime actually exposed

| Mode | Useful for | What is real and what to check |
|---|---|---|
| [Codex subagents](https://learn.chatgpt.com/docs/agent-configuration/subagents) | Scoped exploration, implementation, tests, and independent review | Current local Codex releases enable subagent workflows by default; app, CLI (`/agent`), and IDE expose agent threads. Applicable `AGENTS.md` or skills can request delegation. Confirm the active client exposes the controls before relying on them. Parallel writes need exclusive file ownership. |
| [Agents API multi-agent sessions](https://developers.openai.com/api/docs/guides/agents-api/multi-agent) | An application creates a managed coordinator and child agents | Enable at session creation with `agent.multi_agent.enabled: true`; `max_concurrent_subagents` defaults to six if enabled. Coordinator and children share the environment, not separate filesystem sandboxes. This API setting is **not** a Codex CLI or playbook configuration switch. |
| [Responses API multi-agent tools](https://developers.openai.com/api/docs/guides/responses-multi-agent) | A harness explicitly exposes child-agent lifecycle and messages | The documented tool surface includes `spawn_agent`, `send_message`, `followup_task`, `wait_agent`, and `interrupt_agent`. Use only the controls present in the active harness; do not assume another Codex client exposes the same API. |
| Sequential coordinator | Work is dependent, shares files, or has no delegation transport | Follow the approved ledger task by task and preserve the same acceptance gates. |

Codex subagents can be steered or given follow-up work through supported client controls. In a runtime exposing `send_message`, agents can pass a focused note without starting a new turn; `followup_task` starts or resumes work. These messages are **not** a Claude-style shared task list, a durable plan, or user authorization. Keep task ownership, dependencies, and completion status in the project ledger. [Codex subagent documentation](https://learn.chatgpt.com/docs/agent-configuration/subagents) describes inherited sandbox/approval controls; messages cannot grant extra permission. Never describe a worktree as a sandbox.

Brief each child with its task ID, exact files, dependencies, acceptance checks, report destination, and `ESCALATE:` signal. When an interface or prerequisite changes, message the affected live agent with the task ID, path/commit, impact, and action. Inspect the agent's final answer, changed files, and direct test exits before marking the task done. A spawn acknowledgement, wait return, thread marked idle, or sent message is not proof of accepted work. If communication tools are absent, route the note through the coordinator and the on-disk plan; do not fabricate a peer channel.

## If Herdr is the terminal host

Herdr is a terminal/pane lifecycle layer for Codex or Claude sessions, not a task ledger, native Codex message bus, or approval source. Use it only inside a Herdr-managed pane (`test "${HERDR_ENV:-}" = 1`), after reading installed `herdr --skill`, and within the authorized task. Confirm command syntax with `herdr --help` and `herdr agent`. See Herdr's [agent automation](https://herdr.dev/docs/agent-automation/) and [CLI reference](https://herdr.dev/docs/cli-reference/).

1. Find the exact live target with `herdr agent list`; address a unique name or the returned pane ID. Inspect `herdr agent get <target>` before sending.
2. Submit a bounded brief with `herdr agent prompt <target> "<task ID and brief>" --wait --timeout 120000`. Use `herdr agent wait <target> --timeout 120000` to watch an already-running agent's first settled lifecycle state (`idle`, `done`, or `blocked`), not a particular task. Prefer native Codex inter-agent messaging when that runtime exposes it; otherwise send via the coordinator's Herdr prompt.
3. Read `herdr agent read <target> --source recent-unwrapped --lines 120`, then inspect artifacts and check exits. `idle`/`done` mean ready for input, not accepted; `blocked` requires inspection, and `unknown` proves nothing. Timeout or `agent_prompt_stalled` does not prove the prompt was not delivered: inspect before any retry.

Do not answer an approval for another agent, use a neighboring pane's state as authority, or remove someone else's pane or worktree. Record outcome in the plan, and preserve logs/reports according to hygiene rules.
