# Astra opinion — non-blocking review pipeline port

**Verdict: proceed with changes — keep the port, but settle the review-debt accounting, independence claims, execution permissions, and task/phase closeout before implementation.**

Advisory to Michel and the planning seat, 2026-09-20. This is not approval to
implement. “Blocking” below means the plan, implemented literally without the
identified correction, would produce a wrong rule or an unusable workflow.

## Evidence and reading order

- Target **C**: `codex-playbook` commit
  `a654bde2637fd64dfacee551351c447b6a549338`.
- Source **S**: `claude-code-playbook` tag `checkpoint/0.1.13`, resolved to
  `6926f8ca86eecd69a81d27d17569f48e7ac3c89b`. The sibling repository was readable.
- **P** means C's
  `docs/plans/2026-09-20-non-blocking-review-pipeline-port-plan.md`.
- All repository evidence was read from git objects, not checkout contents.
  Line citations below refer to those fixed objects.
- `ASTRA-COLD-READ.md` was written before the first sibling-source read. It is
  unchanged. **Cold** findings originated there; **Post-source** findings arose
  afterwards; **Cold → confirmed/refined** identifies the distinction explicitly.
- I consulted current official Codex documentation for client behavior. Links
  are beside the claims they support. Documentation is not proof that this
  particular dispatcher implements every documented feature.
- This lane was dispatched as `gpt-6-astra`; provider runtime identity and actual
  reasoning effort are not independently measured. No child reviewer was run.

## 1. D2 — tiers and model names

**Keep capability-based normative tiers, add Strong, and require an explicit
runtime assignment of each role to a model and supported effort.** Product names
need not be permanent law. Operators still need actual names at dispatch time.
“No names in canonical policy” and “no names anywhere, including evidence” are
different proposals; only the first is useful.

Strong and Top are neither official Codex model classes nor synonyms for two
reasoning-effort values. Define them by responsibility: Strong handles ordinary
deep review; Top handles planning, architecture, and high deep gates. Bind those
roles to the available runtime. That binding may use different models, or one
model at different supported efforts. It can also use the same strongest
configuration for both roles when the roster is small. Do not invent a weaker
assignment just to populate four rows, or relabel an identical rerun as an
escalation. Escalate to the next genuinely stronger available configuration;
otherwise report that the ceiling has been reached.

Codex documents model and reasoning effort as separate settings and documents
inheritance when neither is configured. This supports recording both, not a
universal mapping of Strong to one effort and Top to another.
([Official subagent documentation](https://learn.chatgpt.com/docs/agent-configuration/subagents))

The binding record should include role, requested model identifier, effort,
observed/resolved settings if exposed, date, and selection rationale. Keep an
operator's local mapping outside the managed canonical definitions unless an
explicit customization mechanism is designed. An installer upgrade should not
silently erase an operator-maintained mapping inside a replaced skill package.

**Do not call the existing measurement a Codex benchmark.** S's
`rules/ROSTER.md:43–47` names two Claude models and expressly says a measurement
belongs to the models tested. Port that limitation along with the nine-defect
result. The current C reviews skill at lines 20–22 abstracts the result too far.
Treat Standard as a conservative policy floor, with Codex-specific comparative
evidence still unavailable. Effort alone does not prove greater accuracy or
independent failure modes.

Keep a second family optional. P:50–51 does this correctly, but T10 at P:97
makes one mandatory. Specify a same-family independent-session fallback with
its limitation recorded; when the required independent process or configuration
is unavailable, report the missing gate rather than silently substituting.

## 2. D3 — a roster inside the subagents skill

**Keep the proposed single owner. Codex can be instructed to read that reference;
a link alone is not a guaranteed transitive import.**

Official documentation describes a skill as an entrypoint plus optional
references, with the entrypoint loaded on selection. It does not promise that
every linked file is automatically expanded, or document a ban on reading a
sibling skill's file.
([Official skill documentation](https://learn.chatgpt.com/docs/build-skills))

Use this instruction in the reviews skill:

> Before assigning a review tier, read
> `../codex-playbook-subagents/references/roster.md`, resolving the path from
> the directory containing this `SKILL.md`, not from the project's working
> directory. Use the roster packaged alongside this skill. If it is missing or
> unreadable, report the missing prerequisite before assigning the reviewer.

The subagents skill reads its own `references/roster.md`. That preserves one
owner without a seventeenth skill or an uninstalled repository-level dependency.
Avoid an absolute `$HOME` path: repository skills and installed skills should
both resolve to their own matching package, not accidentally mix versions.

**Evidence classification:** the feasibility judgment is an inference from the
documented loading model, the filesystem access exposed in this session, and
the pinned installer code. It is not an observed successful automatic
cross-skill load. The proposed file does not yet exist at C.

The packaging claim is substantially correct. C `scripts/install.sh:273–277,
295–299,335–338` copies and compares complete directories; C
`scripts/restore.sh:280–289,308–316` does likewise. No inventory-format change is
needed merely to add this nested file. But C `tests/install_test.sh:81–91`
checks only the installed entrypoints in its active-install helper. Add nested
resource coverage for installation, upgrade, rollback, and restore, plus a
fresh-session load check from an unrelated project directory. Existing recursive
comparisons are useful evidence, not a replacement for testing the new dependency.

If a particular client will not follow a sibling reference reliably, have
reviews explicitly invoke `codex-playbook-subagents`, whose entrypoint then
loads its local reference. Do not duplicate the definitions as the first
fallback. A client that actually forbids access across skill packages would
require a separately supported shared resource or revised packaging; there is
no evidence here of such a restriction.

## 3. D4 — Codex mechanics and suggested wording

**Adapt capabilities and information flow, not Claude process terminology.**
The immutable target is the strongest part of the proposal and should remain.

| Mechanic | Recommended wording and consequence |
|---|---|
| Review input | “Pin the full target commit and, for a change review, the base commit. Record scope and acceptance criteria. Inspect source through git objects; never inspect the live development checkout as evidence for that target.” A moving branch name is insufficient. |
| Build and test input | “Execute only from an isolated snapshot/worktree of the pinned target. Record the checkout identity and any generated or modified inputs. Use dedicated writable build/cache/temp locations where needed.” Tests necessarily read checked-out files; distinguish this execution exception from accidentally inspecting the developer's live tree. |
| Worktree preparation | “The coordinator or authorized runner prepares the isolated checkout when it has permission to do so. Worktree creation needs both filesystem and Git metadata access; the review brief grants neither.” The coordinator is not automatically outside the sandbox. |
| Review-only authority | “The reviewer may write only its designated report and disposable execution artifacts when the active permissions allow that. It may not repair product code, stage, commit, tag, or push.” Read-only purpose and an OS-enforced read-only filesystem are different. |
| Read-only execution | “If the active sandbox cannot write required outputs, return findings through the response channel and mark unrun tests unavailable; use an already-authorized execution lane for required checks. Do not weaken containment.” A pre-created worktree alone does not enable a read-only build or a cold-read file write. |
| Context separation | “Use a fresh review context with the approved brief and inputs; do not inherit implementation discussion, other reviewers' findings, or coordinator judgments. Record what isolation the runtime actually provides.” A separate process is a useful conservative default, not proof of blindness. |
| Cold read | “Persist findings after reading the allowed primary material and before opening other reviews or adjudication. Then perform a clearly labeled reconciliation pass.” The literal phrase “before it opens anything else” cannot mean before reading the code itself. |
| Completion | “Continue eligible work while review runs. Register its completion mechanism and handle completion, failure, timeout, and interruption. Use the runtime's event/wait facility; use bounded status checks only when necessary. Wait when required inputs or a gate require it.” Never equate an exited worker with an accepted review. |
| Stop the line | “On a blocking finding, stop new dependent dispatch and prevent already-running dependent results from being accepted or merged until triage. Preserve their work. Continue only work shown to be independent.” A blanket instruction to kill workers would create a separate data-loss problem. |
| Artifact capture | “At review completion, capture the exact report and cold note, target/base, completion status, and reviewer configuration. The coordinator commits only those artifacts under exclusive index ownership.” Merely adding one path does not remove unrelated changes already staged. |

The official sandbox documentation says command subprocesses, including tests
and Git, inherit sandbox restrictions. The permissions documentation also
describes protected `.git`, `.agents`, and `.codex` paths inside otherwise
writable roots. Therefore “the coordinator creates it” requires a capability
check, not an assumed escape hatch.
([Sandbox](https://learn.chatgpt.com/docs/sandboxing),
[Agent permissions](https://learn.chatgpt.com/docs/agent-approvals-security))

Codex documents inherited subagent permissions and failure propagation when a
non-interactive run cannot obtain an approval. Actual per-agent controls remain
client-dependent.
([Subagent permissions](https://learn.chatgpt.com/docs/agent-configuration/subagents))

**This session's exposed contract**, not a universal Codex claim: child tasks can
inherit full history by default; the provided `spawn_agent` accepts `fork_turns`
and has restrictions on model overrides for full-history forks. It exposes no
per-call working-directory or sandbox parameter, and agents share the workspace.
Thus a prompt saying “use this worktree” would not itself enforce containment.
No child was spawned to test those controls.

For separate CLI processes, the official non-interactive interface provides
final output and JSON events including completed and failed turns. That is an
available completion protocol; it is not a guarantee that every external
dispatcher automatically delivers a notification to the coordinator.
([Non-interactive execution](https://learn.chatgpt.com/docs/non-interactive-mode))

## 4. Rule 3.5 — ceiling, ancestry, waits, and gates

**Keep a small ceiling and all three waits; amend the accounting before calling
the port Direct.** Two is a reasonable starting policy, not a measured safety
threshold. The source itself acknowledges its narrow evidence.

First choose the meaning of two. S `rules/REVIEWS.md:51` allows N+2 to start while
N remains unruled, but also says a third never starts. If N and N+1 are pending
and N+2 has begun, three batches contain unreviewed work. The phrase “under its
tip” does not settle when an active batch acquires an identity or starts counting.

My recommendation is **two unresolved slots including the active batch**:
reserve a slot at the first dispatch, keep it through review and remediation,
and release it only after the applicable ruling. N reviewing plus N+1 building
uses both; N+2 waits for a slot. This matches a literal ceiling of two, but
changes the source's N+2 example and must be approved and recorded as an
intentional adaptation. If Michel instead wants the source's outage allowance,
spell it as **two completed pending batches plus one bounded active batch** and
define what happens before that active batch closes; its possible exposure is
three batch ranges, not two. Do not conceal that choice behind unchanged prose.

Ancestry is useful evidence, not the whole debt database:

- **Merge by set union.** If both branches inherit unresolved A and one also
  carries B, the union is `{A, B}`: two, not `1 + 2 = 3`. The source's literal
  “adds the two counts” is wrong for overlapping ancestry.
- **Keep stable batch/review identities and ranges.** Git does not know which
  commits constitute a batch or whether findings were ruled. Branching halfway
  through a batch must not hide its already-inherited changes just because the
  eventual batch-tip commit is not an ancestor.
- **Track copied and semantic dependencies.** Cherry-picks, squashes, copied
  code, and dependencies across repositories can carry risk without preserving
  ancestry. Preserve the debt mapping or treat the new work as requiring a new
  review. Worktrees are a checkout arrangement, not proof of independence.
- **Clear debt per applicable candidate.** A blocker fixed on branch X remains
  present on branch Y until Y contains the fix or an independently validated
  equivalent. A global “batch ruled” checkbox cannot clean every descendant.
- **Review new integration behavior.** Merging two accepted parents can introduce
  a defect in conflict resolution or their interaction. Zero inherited debt is
  not automatic acceptance of the merge result.

The three waits override both the ceiling and the mechanical/deep label.
A missed input limit can be a security defect even if a mechanical reviewer
finds it. Replace “mechanical findings are local” with a scheduling policy:
pending routine review alone need not block reversible work, but impact and
dependency determine what stops. The source's cost-equality claim does not hold
for every finding in its own mechanical checklist.

High deep reviews should remain gates. Before one starts, **all required lower
reviews for its scope**, including task mechanical reviews, must have a final
disposition; missing, killed, empty, or timed-out reviews remain outstanding.
The source explicitly drains deep reviews but does not resolve this mechanical
backlog case. Keep risk-class task reviews represented in the ledger too, rather
than counting only scheduled batch reports.

Freeze the gate candidate. Work on backlog, docs, or test improvements may
continue on an independent line, but a change merged into the candidate needs
appropriate renewed checks and review coverage. Documentation is especially
not automatically independent here: documentation *is the rulebook product*.
Store review evidence separately or make the later evidence-only commit and its
relationship to the reviewed candidate explicit. Never claim an unreviewed
product change was covered just because it followed a green verdict.

## 5. Task table — order, tiers, and repository contracts

**The surface inventory is good; the unit-of-work definition and acceptance
checks need correction.** I would retain one logical port task, express T1–T11
as implementation steps, and retain the intended single patch checkpoint. If
they really are eleven tasks or a named phase, follow those existing closeout
rules instead. Do not call the same change “Phase 3” and “not a phase.”

Recommended adjustments to the existing table, not an authorization to execute:

| Existing step | Change |
|---|---|
| Before T1 | Incorporate the owner's decisions on ceiling semantics, isolation claims, task/phase meaning, and reviewer fallback. Record the ADR at decision time rather than waiting until T7. Preflight the required review/build/browser capabilities. |
| T1 | Lock the 50-ID contract and explicit reference ownership/resolution. Preserve RED evidence inside the implementation task; do not call a deliberately broken contract a completed task checkpoint. Add behavioral scenario acceptance cases for accounting and gate rules, not just heading/name matches. |
| T2–T3 | Keep rule/roster design on Top. Settle the roster interface before parallel authors write both consumers. Numbered rules remain in their manifest owners; the reference holds unnumbered definitions. Treat both skills as a coherent interface. |
| T4–T6 | Apply approved wording to manifest, router, parity rows, and page. Test nested packaged resources and installed reference paths. Preserve the real-browser checks; source inspection cannot substitute for them. |
| T5 | Add a dated source-provenance note identifying which rows moved to S and which remain at the prior source. Update 8.1's treatment as well as 3.1–3.5. Corrected ceiling/accounting wording is Adapted, not Direct. |
| T7 | Keep historical reports and ADRs intact. Update current carriers and navigation selectively. Cover `docs/index.html:174`, not just title/meta/eyebrow. Include the workflow skill's old tier wording and review-range reference in the propagation scope. |
| T8 | Use the normal version-allocation check; 0.1.4 is the intended next version, not a reserved number established by this review. CHANGELOG is also a verified carrier; T7 currently owns it, so coordinate that dependency. |
| T9 | Run the repository's required commands, then record exact exits/counts. `verify.sh` already executes both suites; preserve the documented gates without adding gratuitous repeat runs. This advisory did not execute them. |
| T10 | Pin base/target and record process/context controls, raw output, and triage separately. Make second-family availability conditional consistently with D2. Review fixes against the updated candidate. If the work remains a phase/milestone, Strong batch review does not replace its Top high deep gate. |
| T11 | Reconcile final candidate, evidence, tag and remote state. Check the actual branch protection and publication hooks before applying the proposed direct-to-main route. Git author addresses alone do not establish those facts. |

Ordinary propagation belongs on Standard or the lowest capable permitted
implementation configuration; the exact tier label is less important than not
delegating unresolved policy design as mechanical text replacement. Requiring
the Top planner to validate every routine finding at T10 also undercuts the
coordinator/planner separation in C's subagents skill at line 27. Keep routine
triage with the coordinator; route policy changes and unresolved disputes to Top.

Concrete test and installer observations:

- D1 is right: the canonical test list, manifest, headings, page dataset and
  parity matrix must move together. Current ownership scanning examines
  `AGENTS.md` and skill entrypoints, not arbitrary nested Markdown
  (`tests/rulebook_test.sh:155–165`). Do not accidentally move numbered rules
  into the reference or allow it to become an untracked second rule owner.
- Scope “one roster definition” to the current normative packages. An assertion
  that *no file* outside the roster contains a definition is too broad for
  historical plans, evidence, and illustrative prose. Test identifiable table
  ownership, valid links, expected role assignments, and failure on a missing
  resource; do not pretend a grep proves all semantic parity.
- P:121–123 excludes changes outside sections 3 and 8, but the rename affects
  C `.agents/skills/codex-playbook-workflow/SKILL.md:10,57`. Amend that scope for
  necessary terminology and review-range propagation.
- No seventeenth skill, managed-inventory change, or restore-format migration is
  required for the nested roster. The added shared dependency still needs tests.
- The metadata risk is overstated: using the repository's own metric, C has
  **3,121** name-plus-description characters against **8,000**. Changing
  `3.1-3.4` to `3.1-3.5` changes no length. Re-measure the final text, but do not
  treat that digit substitution as budget growth.

## 6. What the plan missed entirely

**The missing piece is a small durable control record, not another service.**
Git supplies immutable inputs and ancestry, but it cannot supply review identity,
required reviewers, verdict state, failure recovery, or permission evidence.
An ordinary coordinator-maintained document is sufficient initially.

Record at least: review/batch identity; kind; base and target; scope; explicit
dependencies; active/queued/running/failed/completed/ruled status; actual reviewer
configuration when exposed; cold-note and report artifacts; finding dispositions;
fix commits and verification; candidate(s) to which acceptance applies; and the
owner responsible for resuming failed work. Snapshot/restore this record in a
handoff. Dispatching a review, or receiving its process exit, cannot release debt.

Also make these behaviors explicit:

1. A reviewer outage remains a review obligation. A retry preserves the original
   target or is explicitly superseded by a new one; a timeout is not “no findings.”
2. Concurrent coordinators must reserve slots and serialize shared Git/index
   operations, or have one designated coordinator. Two simultaneous admissions
   based on the same stale count can exceed the ceiling even with correct math.
3. Review capacity and implementation capacity need separate budgeting. The
   unchanged host-load heuristic in rule 8.1 does not measure remote model/token
   capacity. Reserve enough actual reviewer capacity to prevent development from
   indefinitely starving its own safety net; do not raise the ceiling to hide it.
4. Review inputs include the instruction environment. A fixed source commit does
   not pin global rules, skills, inherited conversation, memory, or harness
   injections. Record relevant versions/exclusions without claiming total
   isolation. When reviewing a rulebook, treat the proposed rules as the subject
   under review rather than letting them grant themselves new authority.
5. Record observable latency, queue time, rework, and exposure alongside findings.
   Record tokens only if the runtime supplies them; use “unavailable” otherwise.
   S's friendly refactor is evidence that overlap occurred, not proof that every
   project becomes faster or that two batches bound the cost of a defect.

## Findings — most severe first

### F1 — blocking — the ceiling has incompatible active-batch interpretations

**Origin:** Cold → confirmed/refined after source.
**Anchors:** P:29–33,92; S `rules/REVIEWS.md:49–51`;
S `docs/guides/non-blocking-review-pipeline.md:99–115`.

The N+2 example and “third never starts” permit different schedules depending on
whether begun work counts. This makes both enforcement and the claimed exposure
bound unreliable. Choose an explicit admission rule, count work from dispatch,
and demonstrate the boundary with examples. My preferred two-slot rule and the
source-preserving alternative are in answer 4. Record the chosen semantic change
in the ADR/parity matrix instead of asserting unchanged Direct parity.

### F2 — blocking — ancestry arithmetic is wrong, and acceptance is not branch-invariant

**Origin:** Cold → confirmed/refined after source; branch-specific fix acceptance
and merge-result coverage added post-source.
**Anchors:** P:30–32; S `rules/REVIEWS.md:51–52`;
S `docs/guides/non-blocking-review-pipeline.md:117–125`.

Adding counts double-counts shared ancestors. Testing only a batch's final tip
misses a branch cut within that batch. A global ruled flag can excuse an unfixed
branch after a fix lands elsewhere. Union stable unresolved identities, carry
explicit copied/dependency provenance, and bind clearance to the relevant
candidate/fix reachability. Treat changed integration behavior as reviewable work.

### F3 — blocking — process separation and a note do not prove independence

**Origin:** Cold → confirmed after source.
**Anchors:** P:26–28,70–75,97; S `rules/REVIEWS.md:44–45,58`;
S `docs/guides/non-blocking-review-pipeline.md:63–68,142–171`.

A separate process can receive contaminated inputs; a cold note can contain
findings already injected before the note was written. Committing the note
preserves its content, not the history of everything the reviewer knew. Keep
fresh sessions and early notes as useful controls, but qualify the claim as
procedural independence with recorded limits. Do not export an untested
Claude-session leak into a universal claim about Codex threads. Stage the
primary review and subsequent reconciliation separately.

### F4 — blocking — D4 prepares a checkout but leaves read-only execution impossible

**Origin:** Cold → confirmed by source and official documentation.
**Anchors:** P:70–75; S `rules/REVIEWS.md:42,45`;
C `.agents/skills/codex-playbook-subagents/SKILL.md:28`.

The reviewer may still be unable to write build outputs or the mandatory cold
note; the coordinator may also lack Git metadata write permission. Specify
actual write roots, output capture, execution ownership, and the unavailable-check
path. Do not widen the sandbox to make the rule appear satisfied. Use the
capability-based wording in answer 3.

### F5 — blocking — the proposed closeout conflicts with its task/phase labels

**Origin:** Cold → confirmed by additional C objects.
**Anchors:** P:80–82,88–98; C `PLAN.md:3–15`;
C `.agents/skills/codex-playbook-workflow/SKILL.md:12,16–22,31–39,62`.

Eleven task labels, deliberate RED completion, one version bump/tag, and a named
phase with no phase release cannot all satisfy the existing workflow. Make them
steps of one logical task and remove the phase claim, or plan real per-task
closeouts and the phase gate/release. An explicit owner-approved workflow
exception is another possible decision, but the draft does not state one.

### F6 — blocking — a high deep gate can drain deep debt while required task reviews remain missing

**Origin:** Post-source; extends the cold concern about mechanical findings.
**Anchors:** P:29–33,97; S `rules/REVIEWS.md:31,47,49,53–54`.

The rules promise per-task mechanical review but explicitly drain only deep
reviews before a high deep gate. An unbounded failed mechanical lane can remain
unfinished while the gate claims completion. Require every lower review needed
for that candidate to reach a final disposition, with failed/partial reviews
remaining debt. Apply stop rules according to impact, irrespective of which
review kind found the defect.

### F7 — minor — shared-resource packaging needs a behavioral acceptance check

**Origin:** Cold → refined after installer inspection.
**Anchors:** P:56–68,88,96,112–114;
C `tests/install_test.sh:81–91`;
C `scripts/install.sh:295–299,335–338`.

Recursive installation supports D3, but entrypoint equality and roster-table
uniqueness do not establish loading or restored-resource behavior. Test the
nested payload, reference resolution from both consumers, missing-resource
handling, upgrade/restore, and one fresh-session load. Keep a single owner.

### F8 — minor — tiers need a runtime binding and honestly scoped evidence

**Origin:** Cold → confirmed/refined after source.
**Anchors:** P:42–54,88–97;
C `.agents/skills/codex-playbook-reviews/SKILL.md:20–22`;
S `rules/ROSTER.md:24–31,43–47`.

Abstract tier names do not select a runnable model/effort pair. The source's
measurement does not validate Codex configurations, and T10 contradicts D2's
optional-family condition. Require a recorded binding, preserve the measurement's
provenance and limitation, and state the fallback consistently. No new product
names need to enter the canonical policy.

### F9 — minor — report commits and gate-time work need explicit candidate integrity

**Origin:** Post-source, with cold foundations on fixed targets.
**Anchors:** P:25–26,97–98; S `rules/REVIEWS.md:44,54`;
S `docs/guides/non-blocking-review-pipeline.md:63–68,129–140`.

Adding one report path is insufficient when other content is already staged.
Likewise, “work on docs while waiting” can change a supposedly frozen release
candidate. Serialize the coordinator's index use, inspect exactly what will be
committed, capture both artifacts, and separate candidate changes from evidence
capture. Any changed product candidate needs renewed applicable coverage.

### F10 — minor — the propagation scope leaves stale workflow terminology

**Origin:** Cold concern about scope → confirmed by additional C objects.
**Anchors:** P:90,94,121–123;
C `.agents/skills/codex-playbook-workflow/SKILL.md:10,57`;
C `docs/index.html:174`;
C `docs/reports/2026-09-17-rule-parity-matrix.md:5,51`.

The plan limits scope to sections 3 and 8 while a live workflow example still
names the old deep tier and its review-range reference omits 3.5. Include these
dependent updates, the page's body count, and precise source provenance for the
updated parity rows. Preserve historical statements rather than doing a global
replacement. Scope the one-owner assertion to normative definitions.

### F11 — informational — the metadata change is cheap; the claimed economics remain provisional

**Origin:** Post-source/static measurement; evidence caution originated cold.
**Anchors:** P:94,106–111; C `tests/rulebook_test.sh:107–145`;
S `docs/guides/non-blocking-review-pipeline.md:180–196`.

The current metadata metric is 3,121/8,000 characters, and changing the rule-range
digit adds zero. The guide's evidence comes from one friendly refactor and does
not establish a general optimum. Keep the test budget and evidence limitation;
measure actual queue behavior and rework instead of claiming guaranteed savings.

## Verification performed and limits

The following read-only checks operated on C's git objects in memory. No source
checkout, worktree, installation, service, or disposable file was created:

- Full target and source commit identities resolved successfully.
- **16** managed skills; `AGENTS.md` **8,357 bytes**; discovery metadata
  **3,121 characters** by the repository's name-plus-description metric.
- Canonical expectation, manifest, page and parity lists each contain **49**
  IDs and compare equal. The current rule headings contain **49 unique IDs**.
  This is baseline inventory evidence, not a test of the proposed 50-rule port.
- `sh -n` on the pinned contents of `scripts/install.sh`, `scripts/restore.sh`,
  `scripts/verify.sh`, `tests/install_test.sh`, and `tests/rulebook_test.sh`:
  **5/5 exit 0**, no syntax diagnostics. The combined inspection command exited 0.

I did **not** run the test suites or installer. The suites read checkout paths
and create temporary fixtures. Also, `scripts/verify.sh:94–98` invokes the
installer lifecycle suite, whose first fixture invokes the installer at
`tests/install_test.sh:111`. I chose object-only inspection to honor both the
pinned-input rule and the instruction that only these two report files be
created. Nothing here claims that the repository's complete suite passed.

## What I could not verify

- **ESCALATE: automatic cross-skill loading in the proposed installation.** I
  checked official skill documentation, runtime-exposed file access, and the
  pinned install/restore implementation. The reference does not exist at C, and
  no installer or fresh Codex process was run. The final implementation needs
  the fresh-session acceptance check described above.
- **ESCALATE: information isolation across actual Codex/HEXE reviewer launches.**
  I inspected this session's exposed tool contract and official subagent docs.
  I did not run a cross-context leakage experiment. The source guide also calls
  its proposed leakage mechanism untested. Neither absence nor inevitability
  of leakage is established here.
- **ESCALATE: which current model/effort pairs deserve Strong and Top.** The
  available labels and settings are not a comparative review benchmark. I did
  not measure quality, cost, or latency; the source measurement is for different
  models. A dated operator mapping can proceed as a policy choice with that
  limitation stated.
- **ESCALATE: direct-to-main eligibility, remote version availability, and push
  publication effects.** Git objects do not reveal current branch protection or
  all server-side automation, nor establish that two accounts represent one
  person. I did not inspect remote state. D6 needs those checks at execution.
- **ESCALATE: underlying experimental records for the source guide and roster.**
  I read the four specified source objects, not the original programme's raw
  review logs or benchmark artifacts. Its measurements are attributed source
  reports, not independently replicated results.

The source resolved one important cold-read uncertainty: it **does** define
“ruled” as findings validated and blockers fixed or dismissed with reasons
(`rules/REVIEWS.md:51`). I withdraw any suggestion that the source lacks that
definition. The remaining issue is how that disposition applies to each
candidate, including failure, active-work, and branching cases.

Only `ASTRA-COLD-READ.md` and `ASTRA-OPINION.md` were written by this review.
No product files, staging, commits, tags, pushes, or installations were changed.
