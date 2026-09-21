---
name: codex-playbook-quarantine
description: Apply Codex Playbook quarantine rule 10.3 when deletion or overwrite is uncertain, preserving bytes, provenance, restoration instructions, database safety, and owner visibility.
---

# 10.3 · the `codex-playbook-quarantine` skill — the set-aside procedure

*Local layer: if `playbook-local.md` exists in the Codex home, its entries apply only within the non-authorizing, never-weaken boundary in (`AGENTS.md`, "The local layer").*

10.3 **Quarantine converts an uncertain destructive decision into a recoverable one.** If deletion or overwrite is in doubt, set the item aside with provenance and restoration instructions instead of destroying it.

*The HOW behind rule 10.2's calibration: "in doubt, quarantine, put aside."
Referenced from `DESTRUCTIVE.md`; binding for every agent and lane on this machine.*

**The principle: quarantine converts a destructive decision into a recoverable
one, without approval and without stopping work.** If you are wondering whether
you may delete or overwrite something — you may not; quarantine it instead, note
it, keep moving.

## 1. Laws

1. **Move, never copy-then-delete.** A move is atomic on the same filesystem and
   preserves the original bytes, timestamps, and permissions. **Your platform
   file** gives the command and its cross-volume caveat — across volumes a move
   silently degrades into copy-then-delete and is no longer atomic.
2. **Validate first, alone** (rule 10.2): the read-only inspection — size,
   modification time, hash, and whether the path is git-ignored — runs in its OWN
   tool call, its output evaluated, BEFORE the quarantine move, which then runs
   alone. **Your platform file** gives the hashing and stat commands.
3. **Provenance travels with the file**: every quarantine directory carries a
   MANIFEST recording what, from where, why, by whom, and the exact restore
   command.
4. **Quarantine is private**: the root is owner-only, never inside a repo (git
   would see it), never in a temporary directory the OS clears on reboot, and
   never in any synced or published path. Secret-bearing files stay secret in
   quarantine. **Your platform file** gives the command that creates an
   owner-only directory and the one that verifies it afterwards — on Windows this
   is an access-control entry, not a POSIX mode, and the difference matters.
5. **Quarantine is not a graveyard**: every quarantined item is listed in the
   task's close-out report. Final deletion out of quarantine still requires my
   specific approval (rule 10.2 protected classes) — restoration never requires
   anything.
6. **Exclusions**: transcripts and session records are NEVER quarantined or
   removed. Active log files are never moved (rule 9.4 — compress rotated logs
   instead). Secret VALUES are never printed while quarantining — name, length,
   hash only.

## 2. The vault & its hierarchy

The root lives outside any repo, owner-only. A conventional location per OS is in
the matching platform skill; `~/.quarantine/` is the default on Unix-like systems.

```
~/.quarantine/
├── README.md      # orientation for anyone landing here
├── INDEX.md       # the ledger — one appended line per item, status updated on review
├── inbox/         # ACTIVE quarantine — awaiting review at task close-out
├── held/          # reviewed, DELIBERATELY kept quarantined (still recoverable)
├── closed/        # finished — manifest dirs only, payload restored or
│                  # approval-deleted; the outcome lives in the manifest
└── db/            # database dumps/copies (big-file zone, §3) — same lifecycle
```

**The lifecycle IS the directory move**: review an `inbox/` item → move its
directory to `held/`, or restore its payload and move the (now payload-less)
directory to `closed/`. Manifests are never deleted — `closed/` is the audit trail.

One directory per quarantine act, named
`YYYY-MM-DD_<system-or-repo>_<task-slug>_<seq>`:

```
inbox/2026-01-15_my-service_gate-review_01/
├── MANIFEST.md
└── payload/                # the moved goods; multi-file acts mirror their
                            # original RELATIVE paths under payload/
```

**Procedure (files):**

1. Read-only validation call: size, modification time, and hash of the target
   (plus `git check-ignore -v <target>` if it sits in a repo). Evaluate the
   output before doing anything else.
2. Create the item directory and its `payload/` subdirectory, owner-only.
3. Move — alone in its own call, explicit literal path, no globs:
   the target into `payload/`.
4. Append the item's line to `INDEX.md` with status `inbox`.
5. Write `MANIFEST.md`:

```markdown
# Quarantine manifest
- when: <UTC timestamp>
- by: <agent/lane/session identity>
- original path: /abs/path/to/target
- sha256: <hash>  · size: <bytes>  · mtime: <original mtime>
- reason: <one honest sentence — what doubt triggered this>
- restore: <the exact move command that puts it back>
- notified: <where — see §4>
- outcome: <filled at review: restored YYYY-MM-DD | held | deleted with
  approval YYYY-MM-DD>
```

**If you ever automate this.** The five steps above are the whole procedure and need nothing but a shell — that is deliberate, so the file half never depends on something a colleague hasn't installed. If you do write a helper, it must honour three things or it is not doing this procedure: the validation runs and is evaluated **before** the move and in its own step; the manifest it writes is byte-compatible with a hand-written one, so a hand move between the state directories stays a first-class way to drive it; and final deletion still refuses without explicit approval. Judgment never moves into the tool — WHETHER to quarantine, and the honest one-line `reason`, stay yours.

## 3. Databases (never DROP under doubt — rename or copy-out)

- **A relational table or object in doubt:** rename it in place
  (`ALTER TABLE x RENAME TO zzq_YYYYMMDD_x;`) — same database, zero data movement,
  instantly reversible. For rows: `CREATE TABLE zzq_YYYYMMDD_x_rows AS SELECT …`
  and leave the originals in place. Schema-level: rename the schema.
- **A whole embedded database file** (SQLite and similar): it is a file — §2
  applies, destination `db/<item-dir>/payload/` — but ONLY with the owning service
  stopped. If the service must stay up, take a consistent copy into `db/` using the
  engine's own backup command and leave the original alone.
- **Key-value stores:** copy aside, don't delete — dump the key and store it, or
  copy it to a `quarantine:YYYYMMDD:<key>` name, then leave the original for the
  close-out decision.
- **Config lines / env entries:** comment out with a dated marker
  (`# QUARANTINED 2026-01-15 <task>: <line>`) — never delete the line.

**A live database you do not own is never quarantined on your own judgment.**
Taking a consistent copy and touching nothing is the most you may do without the
owner's explicit word in the current conversation.

## 4. Notification (quarantine is silent-failure-proof only if it is LOUD)

Always, in this order:

1. **MANIFEST.md** — the durable record, written at quarantine time.
2. **The close-out report** of the task or lane — a "Quarantined" section listing
   every item and its restore command. A lane's final message MUST carry it.
3. **The owner's channel, when the asset is shared or another actor's** — tell
   whoever owns the thing, through whatever channel you actually have. Tell me
   directly for anything that changes a LIVE system's behavior.
4. **Never notify by printing secret contents.** Name, path, hash, size.

## 5. Review & exit

At task close-out (or my review), each item goes ONE of three ways — and the
directory move IS the state change (update the manifest's `outcome:` and the
index status):

- **Restore** — the doubt resolved in the file's favor: run the manifest's restore
  line, then move the now-payload-less item directory to `closed/`.
- **Keep quarantined** — still uncertain: move the item directory to `held/`;
  listed in the close-out, disk-accounted (a large quarantine is itself a
  close-out line).
- **Final deletion** — ONLY with my specific approval per rule 10.2, run alone per
  rule 10.2; the emptied item directory (manifest intact, outcome recorded) moves
  to `closed/`.

Nothing in quarantine auto-expires. An item nobody can explain gets restored, not
deleted — the file was innocent until evidence, and absence of an explanation is
not evidence.
