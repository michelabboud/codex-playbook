---
name: codex-playbook-dev-modes
description: Apply Codex Playbook dev-mode rules 14.1-14.8 before writing a plan, dispatching a reviewer, triaging a security finding, or changing a project's dev mode (spike, poc, mvp, production, sensitive).
---

# 14 · Dev modes — rules 14.1–14.8

*Local layer: if `playbook-local.md` exists in the Codex home, its entries apply only within the non-authorizing, never-weaken boundary in (`AGENTS.md`, "The local layer").*

*Load before writing a plan, before dispatching any reviewer, when a review returns a security finding, and when I change a project's mode. It sets how much review and how much security a project owes at each stage of its life. It adds no approval: the approval table in `AGENTS.md` is unchanged.*

**Why this shape:** asked for a production-ready app, reviewers spend most of their effort on exotic edge cases, and an exotic finding that stops the line costs the schedule more than the attack it guards against. Security is not optional here: a floor holds in every mode, a realistic finding that does real damage stops the line, and nothing found is ever dropped. What the mode changes is *when* a finding is fixed and *how much* review runs. An early product fixes what an attacker can really use; hardening runs as its own phases once there is a product worth hardening.

14.1 **Every project has a dev mode, and only I change it.** It is one line in the project's `AGENTS.md` — `Dev mode: <mode>` — repeated in each plan's header. The modes, lowest to highest: **spike** (a throwaway test: localhost only, fake data, never deployed) · **poc** (a demo for other people, perhaps hosted, no real users' data) · **mvp** (real but early users) · **production** (many or paying users) · **sensitive** (personal, financial or health data, or other people's credentials). With no line, the mode is **mvp**, or **production** if the project already serves real users. **The data sets the minimum, not the schedule:** a project holding real personal, financial or health data is **sensitive** whatever its line says, and no word lowers it below that. I change the mode with `$codex-playbook-dev-mode <mode>`; you never change it yourself, and you never read a deadline as permission to lower it.

14.2 **The mode sets the amount and the kind of review** — section 3's ladder (`codex-playbook-reviews`), scaled:

| Mode | Per task | Per batch | Milestone | Release | Reviewers look for |
|---|---|---|---|---|---|
| **spike** | none | none | none | none; one mechanical review if the code outlives the test | the floor (rule 14.3) |
| **poc** | automated checks | mechanical per batch; one deep review when the work is done | none | deep | the floor, and anything reachable beyond localhost without login |
| **mvp** | automated checks | mechanical and deep, up to 15 tasks or about 2,000 lines | high deep, **pipelined like a deep review — not a gate** | high deep, a gate | realistic findings (rule 14.4) |
| **production** | automated checks | mechanical and deep, 5–15 tasks or about 2,000 lines | high deep, a gate | high deep, a gate | realistic findings, and the backlog entries due at production |
| **sensitive** | automated checks; deep for every task that touches the floor | mechanical and deep, 3–6 tasks or about 1,000 lines | high deep, a gate | high deep, a gate | as production, plus medium-likelihood findings on a data path |

    Section 3 runs unchanged inside each row: the tiers, pipelining, stop-the-line, the ledger and the three-batch ceiling. **Risk overrides cadence from mvp upward** (rule 3.2); in a poc a task that touches the floor gets a mechanical review of its own, with the floor named in the brief. Economy mode (rule 3.1) is separate, and still my word only.

14.3 **The floor — every mode, never deferred, never parked in the backlog.**
    - No secret in code, a commit, a log, or an error message (rule 9.5, `codex-playbook-environment`).
    - No injection — SQL, shell, template, `eval`, path traversal — on input that anything outside the process can reach.
    - Nothing reachable beyond localhost without authentication, and no endpoint that skips the authorization check its peers make.
    - No code path that loses or corrupts data (rules 9.4, 10.1–10.2, `codex-playbook-destructive`).
    - Every new dependency vetted (rule 1.5, `codex-playbook-code`).

    A floor finding is blocking in every mode, a spike included.

14.4 **No attack story, no blocker.** Every security finding states its **attack story** in one sentence: **who** — the attacker and where they stand (anonymous on the internet, a logged-in user, another tenant, someone on the same machine); **through what** — an entry point that exists in this build; and **what they get**. A finding is **realistic** when its path is open at the project's mode and the damage is real: account takeover, data exposed or lost, code execution, a leaked secret, money moved. A realistic finding is blocking (rule 3.3). One whose path opens only at a higher mode is due at that mode. One whose path opens at no mode is a **hardening** finding — typically an attacker who already has a shell, root or the operator's configuration; a timing side channel outside cryptography; resource exhaustion by an authenticated early user; a race with no window an attacker controls; defence in depth behind a control that already holds. **Downgrading takes a reason:** a finding is below realistic only when its record names the step the attacker cannot take at this mode. A story with no entry point, or a downgrade with no missing step, counts as realistic until someone completes it.

    **Effort follows the class — this is where the time goes back to the schedule.** A reviewer writes a hardening or later-mode finding in one line — the story and the missing step — and moves on: no proof of concept, no deep dive, no fix proposal. The coordinator validates realistic findings against the source (rule 3.3); the others go to the backlog marked *unverified*. Every review brief carries the mode, the plan's threat sketch (rule 14.8) and this rule.

14.5 **The security backlog — every finding kept, none ignored.** Every security finding, whatever its class and whether or not it was fixed, gets one entry: an ID, the date, the review and commit that found it, the attack story, severity, likelihood, **due** — `now` (blocking), `mvp`, `production`, `sensitive`, or `hardening` (rule 14.7) — and status. An entry leaves only by a fix commit named in it, or by my word recorded in it verbatim. It lives at `docs/security/backlog.md`. **In a public repository an open realistic finding is a map for an attacker:** keep open entries due at a mode the project has reached, or will reach, out of the tracked tree — in a git-ignored `docs/security/backlog.local.md` on this machine or in a private security advisory — and keep only closed entries and hardening notes in the tracked file. Say in the close-out when an entry exists only on this machine.

14.6 **Moving up a mode is mine, and it starts a hardening phase.** I decide when a project moves up — typically at staging, when we like what we see. The planner then writes a **hardening plan** from the backlog: every entry due at the new mode, plus any I pick. My move is the instruction for that plan (rule 7.1, `codex-playbook-collaboration`). It runs as its own phase, with that mode's reviews and its own release (rule 6.3, `codex-playbook-workflow`). The move is complete when every due entry is closed or accepted by me in words recorded in the entry. Feature work may continue on other lines meanwhile (rule 3.5).

14.7 **Extra hardening is its own phase, after production.** Once a project is in production, the entries due at `hardening` — the paths no mode opens — are worked through as their own phase when I schedule it — `$codex-playbook-dev-mode harden`, which is also the instruction for its plan: defence in depth, exotic paths, and the edges the earlier modes deferred by design. It runs on its own line beside feature work, under the production row's reviews, and nothing in it blocks a feature release. Each entry closes by a fix or by my acceptance of the risk, recorded in the entry.

14.8 **Security is designed in, from the first plan.** Every plan opens with a **threat sketch**, ten lines at most: the mode; what is worth stealing or breaking; the entry points; the trust boundaries; who attacks, and from where; which floor items the design touches and how it meets them. Authentication, authorization, the data model and secret handling are designed in the plan, before the first task, because fitting them afterwards is the expensive path. Reviewers judge against the sketch; a finding outside it is still reported, and the sketch is corrected when it was wrong.
