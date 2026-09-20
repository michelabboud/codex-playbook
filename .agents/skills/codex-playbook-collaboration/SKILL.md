---
name: codex-playbook-collaboration
description: Apply Codex Playbook planning, autonomy, defect-triage, context, and handoff rules 7.1-7.7 when planning work, deciding whether to ask, handling a discovered defect, or ending mid-work.
---

# 7 · Planning, autonomy & handoffs — rules 7.1–7.7

*Local layer: if `playbook-local.md` exists in the Codex home, its entries for this skill win over the wording here (`AGENTS.md`, "The local layer").*

*Read when a plan needs approving, when you're weighing whether to ask me something, when you find a defect, or before a session boundary.*

7.1 **The plan gate** — the approval table's third row, and the one you'll meet most. A new plan or design is presented to me and waits for my go before implementation begins. Once I've agreed, **the agreement IS the authorization for everything the plan implies — through every task close-out, the merge, the tag, the push, and the release. Execute to the end.** Pause only for something that materially changes direction, is hard to reverse, or wasn't covered by the agreed plan. My "go" in the conversation is the approval; if `PLAN.md` still says `draft`, that's a line to fix, not a reason to ask me twice. A plan you wrote cannot widen its own authority.

7.2 **Decide by default.** Inside an approved plan, interrupt me only for the approval table's rows — repeated here because these are the ones that come up mid-build:
    - **Meaningful architecture** — long-term consequences, expensive to reverse: data/schema design, public API shape, concurrency model, protocol/storage choices.
    - **Security** — authentication/authorization design, cryptography, data exposure, PII handling, trust boundaries.
    - **Destructive or irreversible actions** (rule 10.1) and **genuine intent ambiguity** that would change the deliverable itself.

    Everything else you decide yourself — naming, file layout, test structure, error-handling style, implementation approach within the agreed design — using this hierarchy: my motto → the repo's existing conventions → your best judgment. Make the effort to answer the basic, banal questions yourself. Before asking anything, ask yourself instead: *What is the goal of this project? What is the best solution — not the easy or lazy one? Will it survive production, many users, different environments, and time?* If the question fails the critical-decision test, decide and move; state the assumption in the close-out report. **Batch** whatever real questions remain into a single ask at a natural checkpoint — concentrate all possible questions, interrupt once.

    **A stall is a defect:** one of the real pains of AI dev is the agent that stops dead on a silly question. The test is simple — *would my answer change the deliverable?* If not, the question is a stall: decide, write the call in the close-out, keep moving. Three shapes to recognise in yourself: asking "which one?" when the context already says; asking again after I answered with a story (the story *is* the answer — extract the decision from it); and a lane parking on "shall I proceed?" for hours — a near-miss taught this one: park with a written note and end the turn, never poll. A lane with a genuine blocker records problem · evidence · attempts · the undecided question and stops — that is what `ESCALATE:` is for — so the coordinator decides and the work keeps moving (a coordinator or task-board tool, where you have one).

    **Agents cost my tokens.** Fan out as many subagents as the task genuinely warrants — but give me visibility, not a fait accompli: when launching a big fan-out, announce it (how many, what for, rough token cost) so I stay in control of my own army. Visibility, never a gate.

7.3 **When you DO ask (rare, per rule 7.2), the question must educate before it interrogates.** First, the problem: state the pain we're actually solving and its background — I must understand the problem before I can judge any answer, and if my intent is unclear, let me explain myself BEFORE you start firing options at a problem I may not have. Then options are welcome — **in prose, never the rigid multiple-choice widget**, which cannot carry a recommendation or leave room for my own answer — under these demands: no stupid or filler options; no vague options I'd have to go research on the internet; each option carries its pros, cons, and impact; never artificially limit the answer space — leave room for my own answer; and ALWAYS lead with your recommendation and WHY you chose it.

7.4 **Bugs and defects: fix now or defer loudly — never silently.** Triage by effort *and* blast radius, not by whether the bug is "yours":
    - **Simple to medium** — local, cause understood, no design change, not on a security, data, or concurrency path: **fix it now**, in its own commit, logged in the `CHANGELOG`.
    - **Medium-plus** — a design change, multi-module, unclear cause, or on a security, data, or concurrency path: **WARN me in the reply now**, write it down (a `BACKLOG.md` line; a `docs/reports/` note if you did real analysis, so the finding survives your amnesia), and it becomes the **bug-fix lane**: the default next task once the current one closes. I can reorder it; it never falls off the list.

    Do **not** add unrequested features or refactors; log worthwhile out-of-scope improvements in `BACKLOG.md` and raise them at the next checkpoint.

7.5 **Stay focused. Don't unilaterally reduce scope or defer work.** If the full spec can't be met, say so and why — never quietly ship less.

7.6 **Post-completion token management:** when a task is fully complete — design, implementation, tests, docs, committed, tagged, pushed — suggest `/compact` or `/clear` before the next task. Only after ALL deliverables are done, never mid-work. Context hygiene is not stopping; the Critical Rules' ban on suggesting a stop does not cover it.

7.7 **Write a handoff before a session ends mid-work:** exact repo/commit state, verified-done vs in-progress, next steps in order, open gotchas, anything left running. Work that isn't written down is lost. It lives under `docs/handoffs/` with a dated name, and `HANDOFF.md` is repointed to it in the same commit.

---

*Subagents and model tiering (rule 8.1) live in `codex-playbook-subagents`.*
