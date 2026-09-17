---
name: codex-playbook-platform-linux
description: Use the Linux implementation of Codex Playbook platform rule 11.1 when running on Linux or WSL and another playbook rule requires operating-system-specific commands.
---

# 11 · Linux — platform commands

11.1 **Use platform-native commands and semantics.** On Linux or WSL, use this file for port checks, capacity measurement, hashing, private directories, process inspection, conventional paths, and atomic moves.

*Load this skill only for Linux or WSL when another rule requires a platform command.*

## 1. Is this port free?

| Need | Command |
|---|---|
| List all listening sockets | `ss -tlnp` (add `sudo` to see the owning process name/PID; `-6` sockets are included by default) |
| Fallback if `ss` is missing | `lsof -i -P -n \| grep LISTEN` |
| Check one specific port | `ss -tlnp \| grep ':<PORT> '` or `lsof -i :<PORT>` |

No output for that port = free.

## 2. Host capacity before a fan-out

| Measurement | Command | Reading it |
|---|---|---|
| Logical CPU count | `nproc` | a plain integer |
| Current load | `cat /proc/loadavg` | first three fields are the 1/5/15-minute load averages; divide the one you use by `nproc` to get the load factor the `codex-playbook-subagents` skill's formula wants |
| Free memory | `free -m` | read the `available` column, not `free` — it already accounts for reclaimable cache/buffers |

## 3. Hash a file

- Digest: `sha256sum <file>` — the first field of the output is the hex digest.
- Size and modification time: `stat -c '%s %Y %y' <file>` — `%s` is bytes, `%Y` is the epoch mtime, `%y` is the human-readable mtime.

## 4. A private directory only I can read (the quarantine root)

- Create it owner-only: `mkdir -p -m 700 <dir>`
- Verify afterward: `stat -c '%a %U' <dir>` should print `700 <your-username>`; `ls -ld <dir>` shows the same thing as `drwx------`.

## 5. Process holding a port / still alive / stop it

Inspect before you terminate:

1. Who holds the port: `ss -tlnp | grep ':<PORT> '` (PID and process name are in the last column) or `lsof -i :<PORT>`
2. Is it still alive: `kill -0 <PID>` — exit status `0` with no output means alive; "No such process" means it's already gone. `ps -p <PID>` works too and shows the command line.
3. Stop it: `kill <PID>` first (SIGTERM, lets it clean up); only if it doesn't exit, `kill -9 <PID>` or `pkill -9 -f <pattern>` for a name-matched kill.

## 6. Conventional paths on this OS

| Purpose | Path |
|---|---|
| Per-user config directory | `~/.config/` |
| Quarantine root | `~/.quarantine/` (per the `codex-playbook-quarantine` skill) |

## 7. Atomic move

`mv <src> <dst>` is atomic when both paths sit on the same filesystem — it's a single `rename(2)` syscall, so there's no window where the file is half-written or missing.

**Caveat:** across filesystems (a different mount point, a bind-mounted volume, an overlay boundary) the kernel can't rename across devices, so `mv` silently falls back to copy-then-delete — no longer atomic, and a crash mid-copy can leave a partial file at the destination. Check first with `stat -c %d <src>` and `stat -c %d <dst-dir>` — if the device IDs differ, you're not getting atomicity. Keep the quarantine root on the same filesystem as anything you intend to move into it.
