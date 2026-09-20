# The non-blocking review pipeline — why it works, and how it fails

*The reasoning behind rules 3.3 and 3.5 in the `codex-playbook-reviews` skill.
The rules are self-contained; this guide is for the reader who asks "why is it
done this way?" and for anyone about to change a number. Written 2026-09-20.*

*This guide is ported from source 0.1.15 of the Claude Code Playbook. Its
"corrected in 0.1.14" and "corrected again in 0.1.15" notes are the history of
the source rulebook, kept because they explain why the rules read as they do;
the evidence it cites was gathered on the source's own programme, not on Codex.*

## The problem

Reviews are slow. Deep reviews are slow *and* expensive in tokens. If development
waits for each one, a project with a review after every task spends most of its
wall-clock time idle — and the pressure that creates is to review less, which is
the wrong fix. The right fix is to stop waiting, safely.

## The one idea

**A review is a function of a commit, not of a working tree.**

If the reviewer's input is a fixed commit, the working tree is free the instant
that commit exists, and review and development are two independent processes
that happen to run at the same time. If the reviewer's input is "the current
state of the repository", they are one process, and one of them must wait.

Everything in rule 3.3's mechanics follows from that sentence.

## The loop

1. Finish a unit of work and **commit it**. That commit is the review target and
   it never moves.
2. **Dispatch the reviewer against the commit.**
3. **Start the next task at once**, in the working tree. No waiting, no polling,
   no "are you done?" messages — completion is registered and handled.
4. The reviewer returns findings, each **pinned to the commit** it was found on.
5. **Re-check every finding against the current tip** before acting: it may be
   fixed already, the code may have moved, or it may be moot. All three are
   useful answers.
6. Act on what survives. A blocking finding stops the line; the rest queue.

## The ways it fails silently

Each mechanic in rule 3.3 exists because skipping it produces a pipeline that
looks right and quietly is not.

**The reviewer reads the working tree.** It sees the half-written next task and
reports defects that do not exist in what it was asked to review — or reads a
file mid-write and reports garbage. Both waste a review and, worse, teach you to
distrust reviews. Hence *git objects only*. In the programme this guide draws
on, the committed tip almost never moved under a running review; the uncommitted
working tree moved constantly. This rule carried the load.

**The reviewer has to build, and builds in the shared tree.** Reading git
objects is enough for a reviewer that only reads. A mechanical review is defined
as *tests and lint actually run*, and a single file extracted from a commit does
not build a project. The general form is a **detached worktree of the reviewed
commit, in the reviewer's own scratch directory, with its own build-output
directory**. It costs disk and a cold build. Sharing the build directory with
the developing lane avoids that cost and replaces it with lock contention and
cross-contaminated artefacts, which is worse.

**Nobody defined "blocking".** Then every finding is negotiable under schedule
pressure, and "non-blocking review" decays into "ignored review". The brief
defines it, before the findings exist.

**The reviewer's output stays open in scratch.** Then the record is whatever the
file became later. Committing it the moment the findings are complete makes the
reviewed version the record — and makes "this review was blind" demonstrable
from the history rather than self-reported. The coordinator commits it, never
the reviewer, and commits that one path only — checking the index first, because
anything already staged rides along with a commit however narrowly the last
`git add` was aimed (corrected in 0.1.14; the first version said "stages that
one path only"). The working tree holds someone's half-written task.

**The dispatch is pipelined and the coordinator waits anyway.** The easiest
failure to commit, because the review feels important. It has the pipeline's
shape and none of its benefit.

### What validation does and does not buy

The coordinator re-derives each finding against the repository before acting on
it (rule 3.1). This is sometimes credited with making non-blocking review
*possible*. It does not: a coordinator that merely relayed findings could
pipeline just as well — it would simply act on false findings. Validation buys
**correctness**, not concurrency. What makes running ahead *safe* is the
stop-the-line rule, the three waits and the ceiling in rule 3.5.

## Why deep review gets a ceiling and mechanical review does not

The test is never what the review costs. It is what being wrong costs.

- *Most* of what a **mechanical** review finds is local: a wrong comment, an
  ignored return value. Fixing it three tasks later costs what fixing it now
  would, so waiting for a routine mechanical review costs more than it saves.
  Not all of it, though (corrected in 0.1.14): an unenforced input limit is a
  mechanical finding and can be a security defect. **What a finding stops is
  decided by its impact, never by the kind of review that found it.**
- A **deep** finding is structural: a concurrency model, a data path, an API
  shape. Its fix grows with everything built on top of it while the review ran.

So the trade is: gating costs the review's full latency on every batch,
guaranteed; running ahead costs the probability of a blocker multiplied by the
rework on what was built meanwhile. Blockers are rare and a deep review takes
about as long as one to three tasks, so running ahead wins — until the rework is
unbounded or the step cannot be undone. Those are the three waits.

### Why the ceiling leaves room for a second review, not one

*Read this section as history of the number. The operative statement is the invariant
further down — a line carries at most three unruled batches, the open one included: two in
review plus the one being built is the expected shape, and three closed is also valid.
"A ceiling of two" below means two batches in review behind the one being built.*

*Corrected in 0.1.14. The first version of this section said the ceiling's cost was that
"worst-case rework doubles". It does not double; see the last paragraph.*

A batch is 3–10 tasks and a deep review lasts about one to three tasks, so in
normal running batch N's review lands long before batch N+1 is finished. A
ceiling of one is therefore never reached in normal running. It is reached only
when the review lane is abnormally slow — an exhausted allowance, a dead lane, a
dual-blind pair held up on one side. With a ceiling of one, that outage halts
development too, which is exactly the stall the pipeline exists to remove. A
ceiling of two buys one more batch of room.

It costs two things. **The honest worst case is three batch ranges of unreviewed
code, not two:** two batches awaiting a ruling, and the batch being built
standing on top of them — all three count against the ceiling. With N and N+1 closed and unruled and
N+2 building, three ranges are exposed. That is why the planner runs smaller
batches whenever two are outstanding. (The stricter reading — two slots
*including* the batch being built — caps exposure at two ranges, and is exactly
the ceiling of one rejected above: any slow review halts the line.)

And batch N+1's deep review examines code built on
unreviewed batch N, so a blocker in N can make parts of that second review moot
after it has been paid for. Both are bounded, and both are cheaper than a halted
line. *Corrected again in 0.1.15.* The 0.1.14 text said "at most two closed, unruled
batches" and then let batch N+2 close with two still unruled — three closed, its
own invariant broken at the boundary. A second independent review caught it. The
ceiling is an **admission rule**: *a new batch starts only while at most two
closed batches are unruled.* When N+2 closes there are three closed and unruled;
all three reviews run, and nothing new starts until a ruling brings the count
back to two. (The alternative offered — N+2 may be built but may not *close* —
was not taken: a batch whose last task has landed is closed whatever it is
called, and withholding its review helps nobody.) Because prose had now failed
twice at exactly this boundary, rule 3.5 carries a **normative table of worked
cases**, and where the prose and a row disagree, the row wins.

*Completed before 0.1.4 was published.* A third independent review, of that repair,
judged every row correct and found the defect in the rows that were missing: the
rule never said what *starting* a batch means, nor that one batch is open at a
time — so at a count of two, a coordinator could admit N+2 and N+3 on the same
count and exceed three ranges while obeying every word. **One batch is open per
line at a time**; a batch starts at the first dispatch of a task the plan
allocates to it, and admission is checked again when it closes. Batches that must
run in parallel run on separate lines, and the merge rule bounds what comes back.
And one exception that was always meant and never written: **at three, the line
still accepts the fixes that rule a batch** — otherwise the count could never
come down. Everything else waits, including a merge whose union stays at three
(the merge result is new work) and a later task that was already running when
the third batch closed: it may finish, and its result is kept, not accepted,
until a ruling reopens admission.

*And then restated rather than patched.* A fourth review found two more states
the wording missed — a batch that rule 3.2 closes early while one of its tasks is
still running, and a branch cut from a batch that is still *open* — and, asked
directly whether to keep patching, said no. The diagnosis is worth keeping: every
defect so far sat at one seam. The rule counted batches once they were *closed*,
while everything it governs — admission, branching, merging, accepting a result —
acts on work from the moment it *opens*. So the ceiling is now one invariant:
**a line carries at most three unruled batches, the open one included.** A batch
takes its slot at its first dispatch. Closing it pins the review target and
freezes what belongs to it — a straggler goes to the next batch — and changes its
state, never the count. Only a ruling brings the count down. And nothing lands on
a line outside a batch: a change belongs to the open batch or is a fix attached
to an unruled one, which is why, at three with none open, only fixes land. The
exposure is what it was: two in review plus the one being built.

*And the restatement was reviewed too.* It failed on what it had newly created.
"Nothing lands outside a batch" made an authorized hotfix with no plan impossible
to land, and contradicted the row that lets a docs fix proceed beside a gate; a
fix attached to a closed batch owed no review of its own; and merging a line
whose batch was still open let a fourth range in. So **every landing belongs to
the line's open batch** — the plan's, or an *ad-hoc batch* the coordinator names
in the ledger for authorized unplanned work, which is bookkeeping and never a new
approval — **except the fix for a recorded finding**, which gets a focused review
at the depth of the review that found the defect before its batch is ruled.
**Only closed work merges between lines**, because an open batch has no pinned
target; a task's own worktree is not a line — its result simply lands in the
open batch. The lesson of five reviews is the last clause: **what the rule does
not name is resolved toward review.** Git branching times batch states times
fixes times gates has more states than a table will ever list. A rule that must
list them all cannot converge; a rule that fails safe on the ones it missed can.

### Why the count follows ancestry

Counting per worktree is almost right and leaks in two places. A branch started
from unreviewed work is standing on that work, so it starts at one, not zero.
And two lines each carrying two unruled batches produce, when merged, a line
carrying up to four — so fan-out and merge-back would be a way around the ceiling.
Defining the count as *the set of unruled batches with any commit reachable from
the tip* closes both with no extra rule.

*Corrected in 0.1.14.* The first version said "a merge adds the counts". That
double-counts a shared ancestor: if both lines inherit unruled batch A and one
also carries B, the merged line carries `{A, B}` — two, not three. The count is a
**set union**. Three further limits of ancestry, all found by independent review:

- **A branch cut inside a batch** inherits part of it although the batch's tip is
  not its ancestor — so a batch counts when *any* of its commits is reachable.
- **Cherry-picks, squashes and copied code carry no ancestry.** Carry the batch's
  identity by hand, or treat the copy as new work owing its own review.
- **A ruling is not global.** A blocker fixed on one branch is still open on
  another until the fix is reachable from it. And a merge result is new work: a
  conflict resolution can hold a defect neither parent had.

Which is why git alone is not enough. Git knows ancestry; it does not know which
commits form a batch, which reviews are owed, or whether one was ruled. The
coordinator keeps a small ledger — identity, kind, base and target, status,
dispositions, fix commits, the lines a ruling applies to — and one coordinator
owns admission, because two admitting work from the same stale count can exceed
the ceiling with perfectly correct arithmetic.

### Why high deep reviews are gates

A deep review hunts for defects; the ceiling bounds what a defect can cost. A
high deep review also re-reads the plan against reality and may *revise the
plan*. Work done past a milestone risks being built against a plan that is about
to change, and no ceiling bounds that. At a release, the tag must sit on exactly
the commit that was reviewed, so nothing can be added on top while it runs.

Two consequences follow. A high deep review takes every review below it as input
— **mechanical reviews included** (corrected in 0.1.14: the first version drained
only the deep ones, so a mechanical review that died or timed out could be left
owed while the gate claimed completion) — so all of them are settled first — **the count drains to zero at every
milestone**, and unreviewed work never survives past one however the batches
went. And the wait is not idle: the queue of minor findings, the backlog, test
hardening and docs depend on nothing the review might change, and they are
exactly the work the pipeline has been deferring. One caution: the gate's
candidate is frozen, so that work happens on a line that is not merged into it
until the gate passes — and where documentation *is* the product, as in a
rulebook, docs are not "independent work" at all.

## Blindness is a convention, not a platform property

Two reviews of one commit can run concurrently, which is what makes dual-blind
review affordable: neither reviewer is on anyone's critical path. But in the
programme behind this guide, context crossed the blind boundary **in both
directions** between a coordinating session and an in-process subagent reviewer,
with neither side composing a read: after its findings were complete, the
reviewer found another reviewer's output and the coordinator's documents in its
context, while the coordinator had been receiving automated diagnostics naming
the reviewer's scratch files as it created them.

The likely mechanism is ordinary: a harness injects context — task
notifications, file-change notices, memory, editor diagnostics — at session
level, below the reach of any brief. **That explanation has not been tested**,
and the rule deliberately does not depend on it.

**The leak described here was observed on another client — the source
rulebook's programme — and nothing is asserted of Codex threads.** What
isolation a Codex reviewer launch actually provides has not been measured here;
the controls below are worth having whether or not it leaks, and the rule asks
only that the runtime's real isolation be recorded. The controls, in increasing
order of value:

1. **Enumerate excluded paths; do not describe them.** "Read nothing outside
   your scratch directory" is ambiguous about whose.
2. **A dedicated parent per reviewer, holding only that reviewer's material, within
   the task-managed workspace** — two sibling reviewers are one `ls ..` apart.
   Judge it by what the reviewer can actually reach, not by the layout, and record
   in the review header when the runtime cannot provide it. ("Nothing anywhere
   above it" was the first wording; no filesystem can satisfy that.)
3. **A cold-read note written to disk after the brief and the material under
   review, and before anything else is opened**, with
   only the findings in that note counted as independent corroboration. This one
   generalises: it costs nothing, it works whether or not the isolation leaks,
   and it turns "it was blind" from a claim into evidence. Anything the reviewer
   adds later is still a finding — an ordinary one.
*These are controls, not proof.* A separate process can be handed contaminated
inputs, and a note preserves what the reviewer wrote, not everything it knew.
Record what isolation the runtime actually provided and claim no more.

4. **A separate process for the second reviewer.** Two in-process subagents of
   one session are not decorrelated at all. A model reached through another
   coding CLI is a separate process by construction — one more reason the
   roster reference has an optional second family.

## What it costs

Findings arrive after you have moved on, so some need re-checking against a tip
that changed, and occasionally one is moot by the time it lands. That is
strictly cheaper than serialising. The cost that is easy to miss is disk and
build time for reviewers that must build, above.

## The evidence, and its limits

One programme, September 2026: a sixteen-task, behaviour-preserving refactor of
one large module, with sixteen mechanical reviews and four batch deep reviews,
two of them dual-blind across model families. In six of seven consecutive task
pairs examined, the mechanical review of task N was committed 9 to 24 minutes
after that task closed and before task N+1's commit existed. One batch deep
review landed four minutes *after* the next batch's first task was committed;
its one real finding was fixed while that task closed out. Nothing stalled and
nothing was reworked.

**That is the friendliest case there is.** The tasks were nearly independent and
"correct" meant "unchanged". It shows the mechanics work; it does not show that a
ceiling of three unruled batches per line is right for feature work with heavy
dependencies. That is why the reviews skill's closing paragraph asks every
close-out to record how often the ceiling was reached — the number is a starting
point with a measurement attached, not a finding.
