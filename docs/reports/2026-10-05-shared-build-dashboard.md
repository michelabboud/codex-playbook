# Shared build task dashboard — close-out record

## What was built

A reusable Codex skill provides one persistent local browser task board across
projects and independent Codex sessions. Producers post to their own canonical
project/run/session identity. Locked transactions retain task history and
failures; the browser reloads snapshots every ten seconds, preserves filters,
and shows timestamps and staleness. Build, review and publication acceptance
remain separate. Python 3.9+ and the standard library are the only requirements;
there is no server, port, scheduler or background heartbeat.

The canonical source package is
`.agents/skills/codex-playbook-build-dashboard`. It is the twentieth managed
skill, with four exact nested resources. Install, rollback and restore carry
its complete tree while runtime state stays outside package ownership. The
local standalone copy is installed under `~/.codex/skills/`; the authorized
local guidance names it. No whole live Playbook upgrade was performed.

## Verification evidence

Frozen predecessor `264c4b15c5a2c604e3882b2542680c00ef99e613` passed the
full verification script with 193 rulebook checks, 217 local-layer assertions,
789 installer lifecycle assertions and 19 dashboard behavioral tests, exit0.
That success did not accept its source. Independent deep review found two
blocking functional defects, each confirmed by an isolated failing fixture:
template-looking user text changed during rendering, and Unicode expansion
could produce a generated file too large for the helper to reopen. Original
cold notes, red fixtures and receipts remain preserved outside the repository.

Mechanical review independently reproduced a WSL path-conversion timeout that
skipped available opener fallbacks. This was a non-security, non-data-loss
failure-path defect. Repairs were evaluated on pinned successors; passing predecessor counts did
not establish successor acceptance.

The first capacity repair, bb2271, removed the second HTML recognition check
between registry publication and HTML replacement. Independent mechanical and
focused deep fixtures both proved that it could overwrite a concurrently
introduced unrecognized file. The original 264c guard preserved that file.
Repair 1378f4f restores the guard after registry commit without moving the
capacity checks. Its regression fails on bb2271 and passes on 264c and the
repair. All 24 helper tests pass; independent mechanical and deep focused
reviews accept 1378f4f with no open blocker. Final combined-tree verification passed on `f70ca00`; source checkpoint
publication is directly verified below. Fixtures,
red/green logs and hashes are retained in
`../nhb-lanes/dashboard-html-swap-repair-20261005/`.

Actual native proof on the owner's host opened the board in Windows Chrome.
An isolated Chrome proof observed revision 14→15 automatically after 10067 ms
while retaining the selected project filter. Only run-owned proof browsers
were stopped; the user's browser window remains open. A real initial WSL
opening failure was preserved and repaired with child-only WSLENV export. A
literal-path probe preserved spaces, apostrophe and dollar-expression text
without executing them. Empty XDG state configuration received a fallback
regression. Linux/macOS openers were mocked, not natively accepted here.

Model ledger: scoped implementation/integration used GPT-6 Sol configurations;
independent mechanical review used GPT-6 Luna max; independent deep review used
GPT-6.1 Sol xhigh. Reviewers were separate fresh contexts, blind to one another
before their sealed cold notes. Focused repair reviews were briefed on defect
scope and are not blind rediscovery. No alternate model family was used. Runtime
model receipts, token totals, queue time and latency are not exposed; dispatch
configuration is recorded rather than claimed as an independent receipt.
One task/batch was open; neither three unruled batches nor admission at two
unruled batches occurred.

## Assumptions made

A static local file meets the requested persistent browser window. Browser
refresh proves a changed snapshot was read, not producer liveness. Session IDs
are ownership conventions within one OS identity, not authentication against
that same user. The existing installer can safely distribute the whole package
without a new installer implementation or dependency. Standalone local skill
installation does not imply upgrading all managed rules. This is a task source
checkpoint, not a new phase release.

## Concerns and observations

Browser opening is best effort across interruption between launching and
persisting the opened marker; normal concurrent open requests serialize.
Capacity admission must bound both generated outputs before replacing either.
Native macOS/Linux browser launch and native Windows filesystem-lock acceptance
remain unverified. A same-user ancestor-swap hardening observation is kept
unverified in the backlog; the missing attacker prerequisite is already having
write access to the operator's private filesystem identity/parents.

Hygiene: no data or worktree was removed, zero bytes reclaimed. Keep shared
runtime state, live browser, cold reviews, failed/successful receipts and
run-owned browser profiles as protected state or evidence. Installer tests use
isolated owned temporary homes; they preserve prior tree bytes and modes.
No MAI resources or Codex session records were touched. Existing unrelated Hexe worktrees were retained without modification. No cleanup candidate
is proposed as part of this feature.

## Close-out confirmation

Version 0.1.13 is allocated under the shared version lease. Documentation,
architecture, decision, installer inventory and handoff are updated. Source
review is accepted on `1378f4f`. Final combined-tree verification passed with
193 rulebook checks, 217 local-layer and 789 installer assertions, and
24 helper tests (6.195 s), exit 0. The final skill metadata validator passed.
Annotated `checkpoint/0.1.13` and main were pushed atomically; direct remote
inspection resolved both to `f70ca00b684bb5d5eecf5c509a1753cd31ebf9c4`. This main-line receipt
follow-up preserves that tag and the verified helper/template/test bytes.
The solo-owner repository uses main. There are no repository workflows or
active local hooks; hooksPath is unset. Existing GitHub Pages publishes /docs
from main to https://michelabboud.github.io/codex-playbook/, so pushing the
public documentation also requests its normal site rebuild. No v-tag release
or live whole-rulebook installation is part of this task. Pages deployment is
separate from source push and cannot be inferred from it.

## Durable evidence locations

- Local browser and opening proof: `~/.local/state/nhb-release-0.53.6-20261005/`.
- Shared state: `~/.local/state/build-task-dashboard/`.
- Cold deep review and forward fixtures: `../nhb-lanes/dashboard-review-264c/`.
- Cold mechanical review: `../nhb-lanes/dashboard-mechanical-264c/`.
- Second focused deep review: `../nhb-lanes/dashboard-final-review-bb/`.
- Red/green repair fixtures: `../nhb-lanes/dashboard-template-repair-20261005/`.

Resume identity and source links are in
[the task handoff](../handoffs/2026-10-05-shared-build-dashboard.md).


### Accepted focused review seals

- Mechanical 1378f4f: `3c5871b910111083779ab199d70689aa5a02775cfe518b1c6b663f59ddcd80da`.
- Deep 1378f4f: `2bda7914cfa00766eda41f42190d37cf76e75cdebc087ef1f90b5571443156dd`.
- The mechanical fixture's first attempt omitted its session ID and did not
  reach the intended hook; the corrected fixture passed. Both attempts remain
  preserved. This was a fixture error, not evidence of a failing candidate.
- Deep independent real-process interruption recovery and guard fixtures passed.

The final combined-tree diff after 1378f4f consists only of public records,
backlog and a corrected public skill count. Helper, tests and template bytes
remain identical to the reviewed source and installed local skill.


### Publication receipt

- Verified checkpoint tree: `f70ca00b684bb5d5eecf5c509a1753cd31ebf9c4`.
- Annotated tag object: `0cf75f470e5276955727502a72b260da76e0b088`.
- Remote peeled tag and main immediately after push both matched the tree.
- Final full log: `~/.local/state/nhb-release-0.53.6-20261005/playbook-final-verify-0.1.13.log`.
- Final local/source skill trees match byte-for-byte. Runtime state and history
  are retained, with no cleanup and zero bytes reclaimed.
- Native WSL opening/refresh were verified against the unchanged HTML asset.
  Native macOS acceptance remains unverified. No phase release was requested
  or published for this task.
- Existing GitHub Pages reported checkpoint commit built, with no error, at
  https://michelabboud.github.io/codex-playbook/. The main-line receipt follow-up
  is a separate automatic site rebuild, whose completion is not inferred here.
