# Codex Playbook Initial Release Implementation Plan

> **For agentic workers:** execute each checked task in order and keep the
> release evidence in `docs/reviews/2026-09-16-initial-release.md`.

**Goal:** Publish an installable, documented, visually polished Codex rulebook.

**Architecture:** Put governing rules in one global `AGENTS.md`; put infrequent
procedures in Codex skills; keep the public explanation and visual map separate
from the installed payload.

**Tech stack:** Markdown, portable POSIX shell, dependency-free HTML/CSS/JS,
GitHub Pages.

---

- [x] Create the public GitHub repository and local checkout.
- [x] Preserve the approved first-person global rules in `AGENTS.md`.
- [x] Add the three procedural Codex skills and installation guide.
- [x] Add public project documentation, parity report, and contributor files.
- [x] Build and visually verify the dependency-free rule map.
- [x] Run repository verification and link checks.
- [x] Prepare the verified `v0.1.0` commit, tag, GitHub release, and Pages publication.
