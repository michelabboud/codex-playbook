---
name: codex-playbook-open-dashboard
description: Open the shared local Codex task dashboard, or announce its location and opening command once at session start without launching a browser.
---

# Open the task dashboard

*Local layer: if `playbook-local.md` exists in the Codex home, its entries apply only within the non-authorizing, never-weaken boundary in (`AGENTS.md`, "The local layer").*

Resolve `../codex-playbook-build-dashboard/scripts/dashboard.py` relative to this
skill's actual installed folder. The publisher skill and this opener are installed
together. Do not use a hardcoded user path or assume a particular WSL distribution.

At the first response of a fresh Codex session, run the helper's `locate` command.
It reports the actual dashboard path, browser-friendly URL, whether it exists and
an opening command without creating state. Mention once, concisely: the dashboard
link and `$codex-playbook-open-dashboard`. If reported uninitialized, say that this
command creates an empty board and opens it; do not claim a missing file is already
available. If existing state is unavailable or invalid, report the reason without
reinitializing it or describing it as an empty first-use board.
Then continue the user's request. Do not auto-open a browser at startup, repeat
the notice on every turn, or treat context compaction as a fresh session.

When asked to open/show the dashboard, invoke the resolved helper with an available Python 3 interpreter (`python3` on POSIX; `py -3` or `python` when that is the verified Windows installation):

```sh
python3 /resolved/skill/root/codex-playbook-build-dashboard/scripts/dashboard.py open --again
```

Use the actual resolved path as a quoted argument. Prefer the helper-reported executable/argument list or opening command in its named shell; never paste POSIX quoting into PowerShell. This explicit request may
create an empty owned board; it must preserve existing projects, sessions and
history. It does not authorize cleanup, starting tasks, or launching agents.
Use the helper's detected platform launcher: WSL bridge, macOS `open`, native Windows default handler, or Linux `xdg-open`/`gio`. On failure, report the error and its actual
URL/command; do not claim a browser opened or invent another protocol handler.

The dashboard shows reported task progress. A stale task is not proof its agent
died. Agent links open only publisher-supplied destinations where supported;
copyable resume commands do not automatically launch a client or start a turn.
Never infer the worker's identity from its coordinator session.
