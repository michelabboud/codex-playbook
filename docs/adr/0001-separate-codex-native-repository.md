# 0001 — Separate Codex-native repository

## Context

The existing `claude-code-playbook` contains a mature working doctrine, but its
entry file, conditional rule loading, installation paths, tools, and model
language are specific to Claude Code. Codex discovers global and project
instructions through `AGENTS.md` and loads reusable procedures through skills.

The new edition must preserve the first-person language and character of the
original while behaving naturally in Codex.

## Decision

Publish `codex-playbook` as a separate public repository. Keep the same working
principles and stable subject areas, but use one compact global `AGENTS.md` plus
Codex-native skills for detailed procedures. Maintain a source-parity report
that names every intentional adaptation.

## Alternatives rejected and why

- **One multi-client installation repository:** it would mix incompatible entry
  files and make "install this" ambiguous.
- **A mechanical rename of the Claude bundle:** it would preserve file-loading
  assumptions Codex does not implement.
- **A generated shared-core repository now:** two clients do not yet justify a
  generator, schema, and release train. The parity report captures the evidence
  needed if a third client makes extraction worthwhile.

## Consequences

The two playbooks can evolve at different release cadences. Shared principles
must be reviewed deliberately rather than assumed identical. Installation is
clear, and each repository can use the native strengths of its client.

## Status

Accepted — 2026-09-16.
