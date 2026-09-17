# Modular Rule Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> `subagent-driven-development` or `executing-plans` to implement this plan
> task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild Codex Playbook as a faithful, modular Codex adaptation of all
49 Claude Code Playbook rules and open a verified pull request from the
`nice-michel` fork to `michelabboud`.

**Architecture:** A lean global `AGENTS.md` owns authority and routes triggers.
Sixteen repository skills own full subject procedures and platform commands.
A single manifest drives parity verification and the transactional installer.

**Tech Stack:** Markdown, POSIX shell, dependency-free HTML/CSS/JavaScript,
Git, GitHub CLI.

---

### Task 1: Lock the parity and installation contract

**Files:**
- Create: `config/managed-skills.txt`
- Create: `config/rule-manifest.tsv`
- Modify: `scripts/verify.sh`
- Modify: `tests/install_test.sh`

- [x] Add failing verification for the exact sixteen-skill inventory.
- [x] Add failing verification for all 49 unique rule IDs and their owner files.
- [x] Add failing verification that the global file is a router rather than the
      complete subject rulebook.
- [x] Generalize lifecycle assertions to every managed skill.
- [x] Run `./scripts/verify.sh` and record the expected contract failures.

### Task 2: Implement the modular rulebook

**Files:**
- Modify: `AGENTS.md`
- Create/replace: `.agents/skills/codex-playbook-*/SKILL.md`

- [x] Move rules 1.1–12.4 into their subject skills without semantic loss.
- [x] Add the self-update skill and all three platform skills.
- [x] Adapt Claude-specific model and file-loading mechanics to Codex while
      preserving the review ladder, escalation, and safety behavior.
- [x] Restore the exact Docker, secret, destructive-action, quarantine, testing,
      writing, repository, and workflow guarantees from the source.
- [x] Run focused manifest and metadata verification until green.

### Task 3: Generalize backup-first installation and restoration

**Files:**
- Modify: `scripts/install.sh`
- Modify: `scripts/restore.sh`
- Modify: `tests/install_test.sh`

- [x] Read managed skills from `config/managed-skills.txt` with strict
      validation and no unsafe path construction.
- [x] Write format-2 checkpoints containing the exact managed inventory.
- [x] Restore format-1 checkpoints for backward compatibility.
- [x] Preserve the existing preflight, verified-backup, atomic-swap, signal,
      rollback, and unrelated-skill guarantees for all skills.
- [x] Run the lifecycle suite and repair every failure before proceeding.

### Task 4: Correct the public product and visual playbook

**Files:**
- Modify: `README.md`
- Modify: `INSTALL.md`
- Modify: `ARCHITECTURE.md`
- Modify: `docs/index.html`
- Modify: `docs/reports/2026-09-16-source-parity.md`
- Create: `docs/reports/2026-09-17-rule-parity-matrix.md`
- Create: `docs/adr/0002-progressive-disclosure-rulebook.md`
- Modify: `docs/adr/README.md`

- [x] Replace the retired 42-rule/three-skill claims everywhere public.
- [x] Document exact Claude-to-Codex adaptations and zero silent omissions.
- [x] Publish a human-readable 49-rule parity matrix.
- [x] Update the visual rule dataset, counts, search, and architecture copy.
- [x] Inspect desktop and mobile renders and exercise rule search.

### Task 5: Close the pull-request checkpoint

**Files:**
- Modify: `CHANGELOG.md`
- Modify: `PROGRESS.md`
- Modify: `PLAN.md`
- Modify: `HANDOFF.md`
- Modify: `VERSION`
- Modify: all public version carriers

- [ ] Mark the approved plan complete and record the exact verified state.
- [x] Allocate the next unused checkpoint version from local and remote state.
- [x] Run shell syntax checks, lifecycle tests, full verification, link checks,
      placeholder checks, whitespace checks, and the applicable dependency audit.
- [x] Run independent specification and code-quality reviews; fix and re-review
      every confirmed finding.
- [ ] Commit with the configured identity and create `checkpoint/<VERSION>`.
- [ ] Push the feature branch and checkpoint tag to `nice-michel`.
- [ ] Open a pull request against `michelabboud/codex-playbook:main` containing
      the five-part close-out report and verification evidence.
