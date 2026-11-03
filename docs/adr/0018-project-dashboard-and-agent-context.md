# ADR 0018 — Project dashboard and explicit agent context

## Status

Accepted for implementation, 2026-11-03. Authorized by the owner's redesign and
packaged opener request. The owner selected task details and open-in-Codex where
supported, not an embedded transcript bridge.

## Context

The shared board is an increasingly long list of sessions. Users need active work
first, bounded navigation, readable task details and a reliable association with
the agent doing the work. The v1 registry rejects unknown task fields, so adding
optional fields there would break older producers sharing the board.

## Decision

Keep the file-only board and v1 task schema. Add validated optional `agent_context`
inside task history event data, which old producers already preserve as a dictionary.
Use only the latest matching task event and never infer a worker from the parent
session. Missing context after an older publisher's update means unavailable.
Context contains reported model/effort, worker thread/link, worktree, command,
checkpoint, blocker and decision when supplied. It grants no process access.

Render project tabs ordered by active work, a bounded task list with running work
first, and a task/agent detail inspector. Keep history/evidence and terminal tasks
discoverable. Use solid accessible colors, light/dark/system themes and preserved
navigation across refresh; no gradients, remote fonts, analytics or server.

Only explicit verified HTTPS agent links can open a client-supported destination.
Without one, a valid reported UUID supplies a copyable `codex resume` command;
unknown IDs have a truthful unavailable state. Never invent a deep-link scheme or
label the coordinator as a worker. No transcript, auto-kill or shell execution UI.

Package a small opener skill alongside the existing publisher skill. At the first
response of a fresh Codex session, the router directs discovery of the actual
dashboard location, a concise link and the skill command. Do not auto-open a browser
at every startup. A locate command is read-only and reports a missing board honestly;
an explicit open can initialize an empty owned board without inventing a task.

## Alternatives rejected

- Add fields to v1 tasks: older producers reject them.
- A sidecar registry: adds locking/revision coordination unnecessarily.
- Parse arbitrary task prose for identity: ambiguous and easy to misassociate.
- A local transcript server: not the owner's selected scope.
- Show every project/session fully expanded: recreates the current navigation cost.

## Consequences

Old producers preserve valid state but can rerender the older template until their
installed helper updates. Context is reported evidence, never proof of liveness.
Native client launching is limited to explicitly supplied supported links; command
copying is a fallback, not an automatic launch. Startup guidance is instruction-based,
not a runtime hook that executes before the model starts. Installer round-trip,
mixed-version preservation, rendering, keyboard, theme, responsive and escaping
checks must cover the delivered behavior.

The owner explicitly requires WSL, macOS, native Windows and Linux. Resolve OS,
URLs, interpreter and shell quoting separately; validate WSL on this host and
label mocked macOS/Windows checks honestly until native hosts are available.
