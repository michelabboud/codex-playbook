# Dashboard deep review — 2026-11-03

## Initial independent findings — saved before additional review inputs

- Base: `9b0f6e38f569daa262132ad7bfd50b9d84bf92d9`.
- Target: `02aa0019a04edd46795a775490774f7fa7c1fd4d`.
- Scope: production local file dashboard; project tabs, complete task/agent inspector, truthful reported context and activity, safe literal rendering, state/history preservation, opener and startup guidance across WSL/Linux/macOS/native Windows. No transcript server or dependency expansion.
- Isolation: fresh-context child sharing the filesystem, not a separate-process blind review. Source inspected with pinned Git objects. No other reviewer's findings or coordinator review report read. The supplied ADR/plan and approved raw receipts are inputs. Review product authority is limited to this document; no product edits, worktrees, broad test reruns, Git mutations or live registry changes.
- Model/effort: actual runtime model and effort are not exposed to this child in its brief/tool results; confirmation requested separately. No model identity inferred from fixture data.
- Instruction environment: project router version `0.1.23`, playbook review/testing/repository/dev-mode/documentation/writing skills, supplied global router `0.1.21`, local layer and narrow relevant memory registry guidance. Proposed product instruction changes are reviewed as source.

### CONFIRMED

1. **P2 / blocking requested navigation behavior: automatic refresh exits the mobile inspector.** At widths up to 620 pixels, the initial `data-view="tasks"` hides the inspector. Clicking a task calls `showView('details')`, but `showView` never persists the selected workspace view, and the persisted preferences omit it. The default enabled ten-second reload recreates `data-view="tasks"`; neither initialization nor restored task selection calls `showView('details')`. The user loses the open inspector every ten seconds while reading details, commands, evidence or history on mobile. This is a reachable regression in the new responsive view, not an inferred agent or security concern. Source: `.agents/skills/codex-playbook-build-dashboard/assets/dashboard.html:596-600,679,894-896,920-923,1023-1027,1244-1252`. Preserve/restore the workspace view (and validate the refresh path on mobile). The approved browser receipt shows mobile details and persistence separately; it does not show inspector visibility surviving a reload.

### REFUTED

- Current worker context is not inferred from the coordinator: the latest task event is selected within each session, and all seven task fields must match before its context is used. A newer context-free event prevents reuse of an older association. Worker and coordinator resume actions are separate.
- No script execution path found in task/context rendering: JSON delimiters are escaped before embedding, all data nodes use `textContent`, links are checked, and reported commands are copied/displayed without execution.
- New metadata does not extend the strict v1 task shape: it resides in task-event data; old extra history fields are preserved. Existing state ownership and write protections are retained.

### UNVERIFIED

- Native macOS/native Windows execution and actual external agent routing are not established by the supplied evidence. Platform mocks and the WSL child-process test are narrower evidence.
- Supplied broad receipt ends with one failed verification check from two template-sensitive legacy assumptions. Its passing subsets, the targeted two-test repair receipt, five UI checks and later 38-test dashboard receipt are separate executions, not one wholly green aggregate.
- No independent test execution or live browser interaction has been performed by this reviewer. Browser receipt hashes for dashboard HTML and UI tests match the target objects exactly; broad receipts lack embedded candidate/toolchain/command/exit provenance, so candidate attribution also relies on the coordinator's supplied brief.

The initial finding above was written before requesting follow-up clarification or receiving other review inputs. Final disposition and evidence inventory follow below when complete.

## Final review of the pinned target

**Verdict: changes required for the confirmed mobile navigation defect.** No additional blocking defect found in the scoped source review. This verdict is for `02aa0019a04edd46795a775490774f7fa7c1fd4d`; any repair requires a focused re-review of its exact commit and affected behavior.

Configured dispatch, supplied by the coordinator after the initial note: `gpt-6.1-sol`, `xhigh`, `fork_turns=none`. Runtime self-identification is unavailable. This is a completed fresh-context child review in a shared filesystem, not separate-process blindness. No other reviewer output, coordinator review report or adjudication was read. Product/source inputs were pinned Git objects; allowed external inputs were only the four receipts listed below. The explicitly excluded review/document roots were `docs/reviews/` apart from this owned output, `docs/reports/`, and `docs/handoffs/`. There was no dedicated isolated checkout or scratch parent and no native-host test environment. Review tokens, queue time and runtime-measured latency are unavailable.

The coordinator acknowledged and source-validated the initial mobile finding and intends to repair it. That acknowledgement is not repair evidence and does not change this target's disposition. No further product inputs were consumed.

### Evidence checked

| Area | Source/evidence | Assessment |
|---|---|---|
| v1 state and history | Backend diff; `validate_task`, `validate_board`, locked updates and atomic save | Task fields remain unchanged; context is in history data; sibling sessions and historical unknown data are retained; ownership, symlink/hardlink, size and overwrite protections remain in the existing paths. Older publishers can retain event metadata while posting a newer event without context. |
| Current identity | HTML `indexContext`, `deepEqual`, session-scoped context maps and distinct coordinator section | Latest appended task event only; all current fields must match; a newer ordinary event clears association. Neither task prose nor parent UUID supplies worker identity. |
| Literal text and links | Backend JSON escaping; HTML `node`, `safeURL`, copy actions | No data `innerHTML`, shell execution or invented deep-link scheme. Explicit HTTPS worker URLs are publisher verified by procedure; valid thread UUIDs supply copyable resume text. Evidence links use separate limited schemes and safe new-tab attributes. |
| Timestamp semantics and liveness | `CONTEXT_TIMESTAMP`, Python datetime validation, browser calendar/date validation, `updateAges` | Context timestamps require real calendar dates, seconds and a zone. Polling does not modify task timestamps; age/attention text states that activity is unconfirmed. No worker death inferred from staleness. |
| Platforms and failure handling | `locate`, `opener_command`, `windows_browser_path`, `browser_commands`, `launch_browser` | Interpreter/arguments are returned explicitly; POSIX arguments use `shlex.join`, PowerShell single quotes double embedded apostrophes. WSL-translated path travels in an exported environment variable, not script text; missing conversion produces no fake Windows URL. Launch failures preserve an unset opened marker and return a manual path. Native/macOS execution limits remain explicit. |
| Startup and packaging | Pinned opener skill, router, inventories, aggregate integration and installer fixture update | Read-only discovery, once-per-fresh-session instruction, no automatic startup browser launch; explicit open can initialize an empty owned board without invented tasks. Both packaged resources are inventoried. Startup enforcement is instructions, not a runtime hook. |
| UI and dependencies | Pinned HTML, UI behavior tests, browser receipt | Active-first project/task ordering, solid themes, keyboard tabs, bounded session-history pagination, full inspector, no transcript service or new dependency. Mobile view persistence remains the confirmed gap. |

Read-only independent command run: `git diff --check 9b0f6e38f569daa262132ad7bfd50b9d84bf92d9..02aa0019a04edd46795a775490774f7fa7c1fd4d` exited 0 with no output. No duplicate broad suite was run.

Shared receipt inventory under `/home/michel/.local/state/codex-playbook/20261103-dashboard/`:

- `verify-integrated.txt`: `All 246 rulebook verification checks passed.`, `All 217 local-layer staleness assertions passed.`, `All 813 installer lifecycle assertions passed.`, five UI tests passed; the initial dashboard subset reported `FAILED (failures=1, errors=2)` and the aggregate ended `1 verification check(s) failed.` The two fixture assumptions were the old fixed HTML budget and old visible heading. The source changes repair those tests without weakening registry preservation assertions.
- `backend-template-regressions-fixed.txt`: the two repaired fixture tests, `Ran 2 tests in 0.359s`, `OK`.
- `dashboard-final.txt`: full backend/dashboard rerun, `Ran 38 tests in 11.625s`, `OK`; coordinator supplied exit 0. These are shared execution receipts, not independent reviewer execution.
- `browser-receipt.md`: fixture browser checks of theme, keyboard navigation, task/filter/project persistence, history size, worker copy fallback, missing identity, literal markup, responsive views and clock threshold; no external agent URL was opened and OS clipboard permission policy was stubbed. Target HTML SHA-256 `037d76f33193d7a2da2a743c4696e81bc4aab71a30ee1d2200fdb26e57af3a88` and UI-test SHA-256 `2f43153c29740d611f00dc1bb079bd324c8e7c7d1f1085fb97131bdae67a77d7` were independently recomputed from target Git objects and match the receipt.

Native routing, real native macOS/Windows launch execution and OS clipboard integration remain **UNVERIFIED**, explicitly outside the supplied fixture evidence. They are not converted into failures or silently described as native acceptance. The only confirmed blocker is the mobile refresh regression described in the initial note. No new security defect or hypothetical hardening investigation was added.

## Focused successor ruling — 2026-11-03

**ACCEPT for the reviewed repair scope at `f2c1ef4fa5f6de810994abfce1f992d85e2523fb`.** Original target/findings remain above. Focused base: `02aa0019a04edd46795a775490774f7fa7c1fd4d`. No remaining concrete blocker found in the mobile-view repair or taskless-session inspector interaction. This ruling does not establish a new broad aggregate run or native-platform/client routing acceptance.

**CONFIRMED repaired:** `showView` now records the validated view choice in preferences and persists it. Hash restoration includes `view`, initialization validates it to Tasks/Details, and startup explicitly reapplies it. Task and taskless session selection retain their complete keys; restoration does not infer which session to open from a title or generic agent identifier. The supplied real automatic-refresh receipt records `view: details` together with the exact active taskless session and title after reload. The original ten-second inspector-exit defect is resolved by the source path and this focused browser evidence.

**CONFIRMED focused interaction:** sessions with zero tasks now have explicit records carrying the exact session object and a distinct project/run/session/null key. Their inspector shows session title/status/age, open coordinator details, gates, note, recorded history and an explicitly coordinator-labelled resume action. Task-only fields, evidence and worker actions remain behind the task guard, avoiding null dereferences or a manufactured worker identity. Ordinary task context validation, URL safety, literal rendering, counts, registry writes and platform launcher code are unchanged by this repair.

**REFUTED:** the taskless inspector does not label the coordinator as a worker or manufacture task completion; no task schema or storage change appears in the focused product diff.

**Evidence and limits:** read the pinned focused HTML/UI-test diff and `/home/michel/.local/state/codex-playbook/20261103-dashboard/taskless-mobile-fix-receipt.md`. Independently recomputed target hashes match that receipt: HTML `0e56c723af5e8c73081332ab10d286c1691f38e7d5cc73e0931946f7ae2b296c`, UI tests `f6786f25fcb6c139b1864bbffb01876ff832d72bef647e33b029ea1873c667e4`. Independent focused `git diff --check` exited 0 with no output. Shared worker evidence reports both new regressions failing before repair, all seven dedicated UI checks passing in 0.199s, active/completed taskless session browser checks, automatic-refresh Details/session restoration, and zero browser errors/warnings. No broad suite was rerun and no independent browser execution was performed by this reviewer. Original native-host, external routing and OS clipboard uncertainties remain **UNVERIFIED**. Same configured model/effort and shared-filesystem isolation limits apply. No other reviewer's report was read and no product/state/Git edits were made by this reviewer.
