---
name: codex-playbook-workflow
description: Apply Codex Playbook workflow rules 6.1-6.4 before version allocation, commits, tags, pushes, pull requests, merges, phase close-out, or releases.
---

# 6 · Task & phase workflow — rules 6.1–6.4

*Local layer: if `playbook-local.md` exists in the Codex home, its entries apply only within the non-authorizing, never-weaken boundary in (`AGENTS.md`, "The local layer").*

*Read before the first `VERSION`, commit, or tag operation of a task, and before any phase release. This is mechanics; it adds no gate the approval table doesn't have.*

*Working directly on `main` is the **solo-developer** default — it holds when I am the only human committing to the repo and no agreed plan says otherwise. **With a team — a second human contributor, or a repo others merge into — work goes on a feature branch and lands through a pull request:** the checkpoint chain below runs unchanged on the branch, the PR is the review gate (rules 3.1–3.5), and `main` is only ever reached by a merge. Decide which mode you are in from the repo itself (contributors, branch protection, an existing PR flow, `CONTRIBUTING.md`), say which one you took, and never push straight to a protected or shared `main`. A project AGENTS.md may add its own gate (e.g., a planning phase); honor it. Everything below is a **standing order**: it runs automatically, every time, to completion. These are commands, not requests for permission — never ask whether to do them; asking is a rule violation, not politeness.*

**Vocabulary.** A **task** is one unit of work that closes with rules 6.1 and 6.2. A **plan** is any work that earns a `PLAN.md` entry — more than one task, or anything touching architecture, a public API, storage, or security; it passes the plan gate (rule 7.1) once. A **phase** is a named group of tasks inside a plan that ends in a releasable state; the plan names its phases, and each closes with rule 6.3. **Inside a phase the planner names milestones and batches:** a **milestone** is a point where something real can be shown working end to end — a vertical slice in rule 1.1's sense — named in the plan with the demo that proves it; a **batch** is 3–10 tasks grouped for deep review (rules 3.1–3.2), boundaries written into the plan. The ladder is **task → batch → milestone → phase**, and a phase ends in a **release**. Small plans collapse levels — a single-task fix has none, a short plan may be tasks straight to a release — but the review tier of whatever level closes never drops (rule 3.1). A single-task fix needs no plan and no phase.

**Git identity, every repo:** commits use `29182417+michelabboud@users.noreply.github.com`. If a co-author trailer is used, prefer `Co-Authored-By: Codex <noreply@openai.com>`.

6.1 **After each task** (the definition of done — run the whole chain, then move on):
    1. Code meets the standards above (rules 1.1–1.5)
    2. Tests written (rule 2.1) and **actually run, output shown** (rule 2.2); build and lint clean
    3. Docs updated (rules 4.1–4.3); ADR added if a decision was made (rule 4.2)
    4. Bump `VERSION` — see **Version allocation** below
    5. Commit with a clear message — one logical change per commit
    6. Tag `checkpoint/<VERSION>` and push — to `main` when working solo on `main`, otherwise the feature branch with its tags, and open or update the pull request when the repo is a team's (the PR carries the close-out report, rule 6.2). **Commits never pile up unpushed:** every task ends pushed.

    **Version allocation.** `VERSION` is strict SemVer and the single source of truth. One writer at a time: announce a hold before you touch it, and hold it until you've pushed. **Reading it just before writing is not a lock** — it is only a smaller race, and races exactly this way in practice. To allocate:

    1. Refresh the worktree and the remote refs, read-only. Don't reset anyone else's work to do it.
    2. Collect `VERSION` on disk and every `checkpoint/*` and `v*` tag, local **and** remote. No remote access means you cannot claim the remote is reconciled.
    3. Compare by **SemVer precedence, not string sort**: major, minor, patch as numbers; a stable version outranks a prerelease of the same core; `snapshot/*`, `gate/*`, `deploy/*` and anything malformed don't count. `sort -V` alone gets this wrong — a `snapshot-*` tag outranks every version tag under it.
    4. Take the greatest, apply the row below, and verify the tag you're about to create doesn't already exist locally or remotely. If someone allocated while you worked, reconcile — never overwrite their number.

    | Where you are | Next version |
    |---|---|
    | Task close-out, stable | `X.Y.Z` → `X.Y.(Z+1)` |
    | Phase release, stable (rule 6.3) | `X.Y.Z` → `X.(Y+1).0` |
    | Task close-out, numbered prerelease | `X.Y.Z-label.N` → `X.Y.Z-label.(N+1)` |
    | Phase release, numbered prerelease | `X.Y.Z-label.N` → `X.(Y+1).0-label.1` |
    | A major bump, or graduating a prerelease to stable | **My word only** — never implicitly |

    The phase's last task takes its own checkpoint bump first, then the phase takes its minor: a task at `1.4.7` closes as `checkpoint/1.4.8`, and its phase releases as `v1.5.0`.

    **Repos that aren't one version.** A monorepo or a repo with independently versioned packages keeps its own scheme: each package's version source, its tag namespace, and what a root `VERSION` means there, recorded in `CONTRIBUTING.md`. Never compare one package's tags against another's, and never lock their versions together because it looks tidier. An undocumented or contradictory scheme is a compatibility decision — bring it to me before you allocate, and keep working on everything that doesn't depend on it.

    **Tag namespaces — a closed list.** Form: `<namespace>/<VERSION>`. Using a namespace not on this list is a rule violation; a new one needs my word and a row here first.

    | Namespace | Meaning | Who, when | Triggers |
    |---|---|---|---|
    | `checkpoint/<VERSION>` | the task is done (step 6 above) | the agent, every task | nothing — my fine-grained debug checkpoint; I can check out any known-good point |
    | `v<VERSION>` | a phase release (rule 6.3); the one namespace without a slash, because publish tooling keys on `v*` | the agent, every phase | may publish (a registry, release assets, a deploy); workflows trigger on `v*` only |
    | `gate/<VERSION>` | the exact tip presented at a gate (mine or the gatekeeper's) | the agent presenting it | nothing |
    | `deploy/<VERSION>` | the commit that went live | whoever deploys, at deploy time | nothing |
    | `snapshot/<YYYY-MM-DD>` | a dated data snapshot, not a version (older ones are `snapshot-<date>`) | the snapshot job | nothing |

    **Mechanics.** The number is `VERSION` at that moment. A tag never moves (rule 6.4). No tag may equal a bare namespace name — a tag named `checkpoint` would block the whole namespace. Only `checkpoint/*` and `v*` feed the next-version computation (step 4). **A tag's name does not control what automation does with it.** Before the first `checkpoint/` tag in a repo — and again whenever the workflows changed or you don't know what they do — read `.github/workflows/` and any publish hook, **including what fires on a branch push**: a repo can deploy on push to `main` with no tag involved at all. If anything fires on every tag, on a namespace other than `v`, or on a plain push, fix the trigger first, in its own commit. If a routine push would publish something unapproved, stop and tell me before you push. Never report hooks as audited when you couldn't see them. The first `v` tag that publishes off this machine in a repo is a rule-10.1 action — ask once; after that the plan's approval covers it. **History:** a repo can carry old `v*` tags from before this scheme was adopted that were per-task checkpoints, not releases; they stay as they are and the numbering continues from them.

6.2 **Every task ends with a close-out report**, five sections — the audit side of the autonomy contract (rule 7.2):
    1. **What was built** — the outcome, not a narration
    2. **Verification evidence** — actual test/build/lint output (rule 2.2), measurements for any performance claim (rule 2.3); when subagents were used, a one-line model ledger (which tiers ran what, e.g. "12 implementation on the Standard tier, 6 reviews on the Standard tier, 1 final review on the Top tier") so the spend is auditable
    3. **Assumptions made** — every judgment call you decided, so I can correct any cheaply in review
    4. **Concerns & observations** — overengineering notes, defects spotted outside scope, suggested sub-tasks (each also logged in `BACKLOG.md`)
    5. **Close-out confirmation** — docs updated, `VERSION` bumped, commit/tag pushed

    **Hygiene checkpoint:** after every task, ask whether its worktree and generated debug/build data are still needed. Run this checkpoint again at the end of every phase and plan, and during a task when temporary outputs or disk pressure warrant it. Check free disk space and available resources before work that consumes them and before cleanup; a low-space reading calls for investigation, not indiscriminate deletion. Inventory the exact worktrees, branches, files, owners, active processes, dirty state, unique/unpushed commits, and evidence dependencies before removing anything. Remove a task worktree only when it is idle, clean, and no longer needed; remove only its proven-obsolete feature branch after its commits are safely reachable and recoverable. Never treat an ordinary or long-lived branch as cleanup. Generated debug data (including Rust `target/debug` outputs) may go only when proven regenerable, idle, and no longer needed. Preserve logs, reports, documents, and uncertain material under rules 9.4 and 10.2; save reports and documents as they are produced and commit safe repository records in the normal close-out chain. Record what was retained, removed, and why in the close-out report. Do not turn this checkpoint into permission to widen the task's repository scope.

6.3 **After each phase** — run the moment the phase's last task closes, as boring and automatic as a commit: merge the phase branch into `main` (if work happened off `main`) **as a true merge commit, never a squash, so every checkpoint tag stays reachable from `main`** → **dependency audit** (`cargo audit` / `npm audit` / `composer audit`, as applicable) → update docs → commit → release tag `v<VERSION>` → push → **`gh release`** with browsable notes. Run rule 6.2's hygiene checkpoint at phase and plan close-out, after preserving their evidence. **Advisories:** fixable → fix or pin away before the release; unfixable (no patched version, no safe pin) → the release is blocked — bring me the advisory ID, the exposure, and the options in one ask. Whatever ships, the release notes list every advisory considered and its resolution. Never let a tag-triggered publish race ahead of the checks that gate it: the required checks pass for that exact candidate *before* the trigger goes out, not in a job that starts after the release exists. Report the release, the artifacts, the registry, and the live runtime as four separate facts. The merge and the release are steps in the chain, not decisions.

6.4 **Never rewrite published history.** Don't amend or move a pushed tag, force-push, or rewrite `main`'s history — it makes my checkpoints unreliable.

---
