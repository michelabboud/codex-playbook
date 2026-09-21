---
name: codex-playbook-platform-macos
description: Use the macOS implementation of Codex Playbook platform rule 11.1 only when running on macOS and another playbook rule requires operating-system-specific commands.
---

# 11 · macOS — platform commands

*Local layer: if `playbook-local.md` exists in the Codex home, its entries apply only within the non-authorizing, never-weaken boundary in (`AGENTS.md`, "The local layer").*

11.1 **Use platform-native commands and semantics.** On macOS, use this file for port checks, capacity measurement, hashing, private directories, process inspection, conventional paths, and atomic moves.

*Load this skill only for macOS when another rule requires a platform command.*

macOS is BSD-derived, not Linux — several of the usual tools are absent or spelled differently. There is no `ss`, no `nproc`, no `free`, and no `sha256sum` on a stock install; `stat` takes `-f` format strings, not `-c`.

## 1. Is this port free?

| Need | Command |
|---|---|
| List all listening TCP sockets | `lsof -nP -iTCP -sTCP:LISTEN` |
| Check one specific port | `lsof -nP -iTCP:<PORT> -sTCP:LISTEN` |

No output for that port = free.

## 2. Host capacity before a fan-out

| Measurement | Command | Reading it |
|---|---|---|
| Logical CPU count | `sysctl -n hw.ncpu` | a plain integer (there is no `nproc`) |
| Current load | `sysctl -n vm.loadavg` or `uptime` | `vm.loadavg` prints `{ 1m 5m 15m }`; `uptime`'s trailing three numbers are the same triplet. Divide the one you use by `hw.ncpu` for the load factor the `codex-playbook-subagents` skill's formula wants. There is no `/proc/loadavg`. |
| Free memory | `vm_stat` | **this is not `free -m` — it reports PAGES, not megabytes.** The first line states the page size (`page size of 16384 bytes` on Apple Silicon, `4096` on Intel). Read `Pages free:` plus `Pages inactive:` (both reasonably reclaimable) and convert: `(pages_free + pages_inactive) * page_size / 1024 / 1024` = MB available. |

## 3. Hash a file

- Digest: `shasum -a 256 <file>` — always use this one. `shasum` is the only SHA-256 tool a stock macOS ships (`/usr/bin/shasum`); it produces the identical hex digest format as Linux's `sha256sum`.
  **The trap, measured:** `sha256sum` can still be *present* on a particular Mac — installed by Homebrew `coreutils`, by a corporate security package, or by some other vendor tool — so a script that calls it works on the machine that wrote it and fails on a clean one. `command -v sha256sum` succeeding proves nothing about anyone else's Mac. Write `shasum -a 256` and the script travels.
- Size and modification time: `stat -f '%z %m %Sm' <file>` — macOS `stat` uses `-f` with its own format letters, not Linux's `-c`. `%z` is bytes, `%m` is the epoch mtime, `%Sm` is the human-readable mtime.

## 4. A private directory only I can read (the quarantine root)

- Create it owner-only: `mkdir -p -m 700 <dir>`
- Verify afterward: `stat -f '%Lp %Su' <dir>` should print `700 <your-username>`; `ls -ld <dir>` shows the same thing as `drwx------`.

## 5. Process holding a port / still alive / stop it

Inspect before you terminate:

1. Who holds the port: `lsof -nP -iTCP:<PORT> -sTCP:LISTEN` (PID and command are columns in the output)
2. Is it still alive: `kill -0 <PID>` — exit status `0` with no output means alive; "No such process" means it's already gone. `ps -p <PID>` also works.
3. Stop it: `kill <PID>` first (SIGTERM); only if it doesn't exit, `kill -9 <PID>` or `pkill -9 -f <pattern>` for a name-matched kill.

## 6. Conventional paths on this OS

| Purpose | Path |
|---|---|
| Per-user config directory | Two conventions coexist: `~/.config/` for cross-platform CLI tools that follow XDG even though macOS doesn't enforce it, and `~/Library/Application Support/<App>/` for native macOS apps. Use whichever a given tool already expects; default to `~/.config/` for a new cross-platform CLI. |
| Quarantine root | `~/.quarantine/` (per the `codex-playbook-quarantine` skill) |

## 7. Atomic move

`mv <src> <dst>` is atomic when both paths sit on the same volume — it's a single `rename(2)` call on APFS (or HFS+), so there's no window where the file is half-written or missing.

**Caveat:** across volumes (an external disk, a different APFS container, a network share) macOS can't rename across devices, so `mv` silently falls back to copy-then-delete — no longer atomic. Check first with `stat -f %d <src>` and `stat -f %d <dst-dir>` — if the device IDs differ, you're not getting atomicity. Keep the quarantine root on the same volume as anything you intend to move into it.
