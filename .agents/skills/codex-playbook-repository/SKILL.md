---
name: codex-playbook-repository
description: Apply Codex Playbook repository rules 5.1-5.3 when creating a repository, first touching an existing repository, adding a document, or checking required project records.
---

# 5 · Repository structure — rules 5.1–5.3

*Local layer: if `playbook-local.md` exists in the Codex home, its entries apply only within the non-authorizing, never-weaken boundary in (`AGENTS.md`, "The local layer").*

*Read when creating a repo, on the first task that touches an existing one, and whenever you add a document.*

5.1 **Every repository contains these files from the start** (an existing repo missing any of them gets them in the first task that touches it, as their own commit before the task's work):
    - `README.md`, `PROGRESS.md`, `CHANGELOG.md`, `ARCHITECTURE.md`
    - `PLAN.md` — **the plan that is running right now.** Either the plan itself (small repos) or an index of the plan files under `docs/plans/` — one entry per plan with its path, a one-line description, its status (`draft` / `approved <date>` / `running` / `done <date>` / `parked <date, why>`), and its dates (written, approved, last updated). This file is the written record of the plan gate (rule 7.1): a plan not listed here as approved has no go. Update it the moment a plan is proposed, approved, finished, or parked; a stale `PLAN.md` is worse than none.
    - `HANDOFF.md` — one pointer to the **current** seam tape under `docs/handoffs/` (its path and date) plus a three-line "where we are". Repointed at every seam (rule 7.7); a stale pointer is a lie.
    - `BACKLOG.md` — dated one-liners for everything deferred or spotted and not done: out-of-scope defects (rule 7.4), sub-tasks and concerns (rule 6.2 §4), ideas. Each line carries date, source, and status. An item leaves this file only by being done or by my word.
    - `.env.example` — every variable the code reads: name, purpose, required/optional, safe default. **Never a real value.** Rules 1.2 and 9.5 push config into the environment; this file is how anyone learns what to set.
    - `LICENSE` — extensionless plain text (GitHub's detection depends on the exact name)
    - `VERSION` — a bare version string, e.g. `0.3.1`. **The single source of truth for the version**: the per-task bump updates this file; the git tag is derived from it.

5.2 **When the condition applies, the repo also carries:**
    - `SECURITY.md` — public repos: reporting channel, supported versions, what is in and out of scope. GitHub surfaces it.
    - `CONTRIBUTING.md` — public repos, or any repo with a second contributor: dev setup, the test/lint/build commands, the commit identity and trailer, tag-from-`VERSION`.
    - `RUNBOOK.md` (or `docs/runbooks/` once it outgrows one file) — anything deployed or long-running: start/stop/teardown (rule 9.6), ports (rule 9.1), container names (rule 9.2), after-reboot checks, known failure modes and their fixes.
    - `GLOSSARY.md` — repos with heavy house jargon: one line per term.

5.3 **Always maintain a `docs/` folder** with proper subfolders — `docs/guides/`, `docs/reports/`, `docs/plans/`, `docs/adr/`, `docs/handoffs/`, `docs/reviews/`, `docs/ideas/`, `docs/runbooks/`, etc. Create the subfolder if missing; never dump docs in the repo root. **Dated documents are named `YYYY-MM-DD-slug.md`** so they sort by name.

---
