# Approval interruption repair — 2026-09-30

## What changed

The owner requested uninterrupted execution of ordinary authorized work, with
consent retained for destructive actions. The 0.1.8 router already said this,
but repository and workflow skills still required a plan approval, and the
public visual guide still required publication and configuration approval.
The 0.1.9 corrections align those surfaces and clarify that the coordinator
handles technical review waits without asking the owner to continue.

The local Codex configuration keeps `approval_policy = "never"` and changes
the default sandbox from `workspace-write` to `danger-full-access`. The enabled
Superpowers plugin was disabled through its config entry: its brainstorming,
planning and execution workflows required repeated design/specification and
integration approval. Its cached files were preserved. The local development
workflow reference also had stale publication and version-decision gates.

These are targeted edits under the owner's fix request, not a wholesale
installer replacement. A private, byte-verified backup was retained under
`~/.codex/backups/approval-repair-20260929T223342Z/`. No credentials, session
records, databases, logs, or local-layer entries were modified. Destructive
rules, refusal handling, review safeguards and the local MAI boundary remain.

## Specific file-edit prompt diagnosis

Read-only session metadata identified two distinct project threads with the
same displayed eight-character prefix. One thread and its parent used approval
`never` and disabled sandboxing. The other thread and its parent used
`on-request` and a restricted sandbox. Their latest recorded turn contexts
agreed with those policies. The restricted worker's writable roots did not
include the sibling worktree destination shown in the owner's prompt.
The detailed diagnosis is retained privately alongside the recovery copies;
this summary omits the operational identifiers.

This explains the file-edit approval requirement. The short thread label alone
does not establish a cross-repository edit or prove which terminal displayed
the request. Shared-server UI routing was not reproduced. Neither project's
source nor running session state was changed.

## Verification and limits

- Codex CLI and running app server both reported 0.159.1.
- `codex --strict-config doctor --summary --no-color --ascii` exited 0:
  `config loaded`, `unrestricted fs + enabled network · approval Never`;
  total `19 ok | 4 notes | 2 warn | 0 fail degraded`. Warnings concerned the
  existing session index/rollout inventory and noninteractive terminal. No
  repair or deletion of session records was attempted.
- A fresh `codex debug prompt-input` exited 0. Its model-visible prompt included
  full access and never approval; Superpowers skills were absent. The initial
  attempt with `--strict-config` was rejected because `debug` does not support
  that flag; retrying without it rendered the prompt successfully.
- No end-to-end claim is made that a future model can never pause. Saved
  defaults do not rewrite active threads' policies. CLI/project overrides,
  managed requirements, external tool consent and actual blockers can still
  constrain execution. The existing restricted threads require a session permission
  change or a fresh launch/resume with explicit full-access/never options;
  existing workers must also acquire the intended policy.
- Full access with `never` is not an enforced destructive-command filter.
  Destructive consent remains an agent instruction. There is no claim that
  arbitrary shell scripts can be classified safely by a small prefix list.
- The first full repository run caught an interim HTML version mismatch while
  the source lane was finishing. It exited 1; its 217 local-layer and 689
  installer assertions passed. The frozen final tree is checked separately.
- The router and three corrected installed skills match source byte for byte.
  The live local-layer check passed all three dead-words items against both
  source and installed text; the digest-bound overrides remain valid.
- Final frozen source verification exited 0: 140 rulebook checks, 217
  local-layer assertions and 689 installer lifecycle assertions passed, ending
  `All Codex Playbook verification checks passed.` Logs are retained locally as
  `/tmp/codex-playbook-approval-verify-20260930.log` (initial failure) and
  `/tmp/codex-playbook-approval-final-verify-20260930.log` (passing run).
- No new prose-matching tests were added; existing contract/lifecycle tests,
  fresh configuration rendering and direct installed-source comparisons cover
  this instruction/configuration correction. No dependency or executable
  implementation changed.

## Sources

- [Official configuration reference](https://learn.chatgpt.com/docs/config-file/config-reference)
  distinguishes sandbox defaults, approval policy, plugin enablement and config
  precedence.
- [Official sandbox and approvals documentation](https://learn.chatgpt.com/docs/agent-approvals-security#sandbox-and-approvals)
  distinguishes technical execution controls and approval; external app tools
  may have their own consent requirements.

## Execution and recovery

The coordinator owns local configuration, installed corrections, records and
Git. Astra at xhigh supplied a read-only plan; Sol at high implemented the
scoped source corrections. Recovery copies are private and retained; restore
only intended settings or paragraphs, after comparing subsequent changes.
Do not replace a current config wholesale with an old backup.

The repository follows its documented solo-maintainer main-branch workflow.
A main-branch push also publishes the visual guide through GitHub Pages from
`/docs`; the destination is the existing Codex Playbook public site.

Hygiene: no user data, session records, logs, branches or worktrees were removed.
The test suites removed their own disposable fixtures through their existing
traps. Private recovery copies and both verification logs are retained. No
task-created service remains running. Working filesystem free space was about
55 GiB, above this owner's 3 percent floor.

To resume an affected parent with explicit permissions, after leaving
its old client, use:

```sh
codex resume <full-session-id> \
  -C <project-directory> -s danger-full-access -a never
```

This command is documented, not executed by this repair. Check existing child
workers separately; resuming a parent is not proof their permissions changed.
