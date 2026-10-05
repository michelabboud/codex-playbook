# ADR 0012 — Shared file task dashboard

## Status

Accepted for implementation, 2026-10-05, at Michel's request for a persistent
refreshing build task view across Codex sessions and distribution in this
repository. Independent source review accepts the final 1378f4f repair;
combined-tree verification passed and annotated `checkpoint/0.1.13` is pushed
at `f70ca00b684bb5d5eecf5c509a1753cd31ebf9c4`. No v-tag release is implied.

## Context

Concurrent Codex sessions need one readable task view. A browser can reload a
local HTML file without adding a service, port or application dependency.
A status board must retain failures and cannot establish that a producer is
alive or that a release is accepted. Multiple producers must not lose one
another's updates.

## Decision

Bundle a standard-library Python helper and static HTML in an automatically
discoverable Codex skill. Store a versioned registry and generated HTML outside
the managed package, under XDG state. Lock the registry transaction, validate
its schema and complete canonical project/run/session identity, append truthful
history and atomically replace each recognized generated file. JSON is the
authority; render repairs HTML after an interrupted write. Refuse unexpected
files and invalid state rather than clearing or bypassing them.

Every producer owns its session entries. The browser refreshes the snapshot
at ten-second intervals, preserving filters, and shows last-post timestamps.
No scheduler or inferred heartbeat is implemented. Separate build, review and
publication acceptance. Keep failed attempts, completed sessions and evidence
links. Do not read raw logs or copy secrets into state.

Open the shared browser once through the platform default handler. WSL passes
the translated Windows path through child-only environment export, preserving
unrelated WSLENV entries. Raw paths never become PowerShell code. Install,
rollback and restore include the complete package; dashboard state is outside
that lifecycle. No whole live rulebook upgrade is implied by creating this
skill locally.

## Alternatives rejected

- One independently rendered HTML file per session cannot provide the requested
  shared view and complicates discovery.
- A local HTTP server adds lifecycle, ports and restart obligations to a
  workflow already served by static files.
- A browser timer that marks producers alive would manufacture liveness.
- Last-writer-wins JSON replacement loses concurrent task posts.

## Consequences

Python3.9+ is required to post updates. Producers must use the same state
location to share a board and retain their identities across resume/handoff.
An already-running Codex session must load the new skill before posting;
installation does not change its context automatically. Native Linux/macOS
browser opening is covered by mocks here; actual WSL-to-Windows opening and
browser refresh are validated on the owner's host. State capacity is bounded
and unexpected/capacity failures preserve the original board. No implicit
cleanup is authorized.
