# ADR0019 — All-project activity and declared plans

Accepted 2026-11-03 for authorized dashboard extension. Production mode.

The default Now view presents reported active work across projects. Project tabs
remain for focused task/session inspection. Status distribution uses current task
snapshots. Activity charts count recorded task-update events in six ten-minute
bins over the last hour; they are event counts, not verified agent activity or
productivity. Empty history shows no recorded activity. Stale reports are never
called dead agents. Filters and project identity cannot merge same-named tasks.

Projects explicitly publish their current plan using update --plan-json FILE.
The JSON object has exactly: id, title, objective, source, status, phase,
current_step, next_step, steps. id is a dashboard identifier; title is nonempty;
objective/source/phase/next_step are bounded text. source is inert human-readable
provenance (for example PLAN.md), not a file to fetch. status is active, blocked,
completed or cancelled. steps is an array of at most 100 objects with exactly
id, title, status; IDs unique, titles nonempty and statuses use TASK_STATUS.
current_step is empty or names a declared step. At most 4000 characters per text.

The complete snapshot is stored as project_plan in an ordinary session-kind
history event. update --clear-plan appends project_plan:null; neither operation
changes the exact v1 session/task schemas. They are mutually exclusive. Ordinary
updates preserve the declaration; only a new plan declaration/clear supersedes
it. Rendering reads the newest declaration per session and retains its timestamp.
Older helpers preserve the history dictionary. New validators reject malformed
declarations before any state write. No source files are inferred or read.

Plans remain attributable to their project/run/session. Multiple differing plans
are visibly concurrent declarations, not silently resolved by most recent post.
Plan step counts are separate from task counts; neither is an elapsed-time ETA.
No plan is inferred from task names. Missing plans are explicitly Not declared.

The current plan pane and Now cards use text nodes for publisher content, retain
keyboard/mobile usability and do not execute commands. Small SVG/CSS charts have
equivalent textual counts. Solid light/dark/system themes continue. No dependency,
server, native client protocol or monitoring authority is added.
