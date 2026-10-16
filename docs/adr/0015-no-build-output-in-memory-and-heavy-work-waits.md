# 0015 — Build output never lives in memory, and heavy work waits for a quiet host

- **Status:** accepted, 2026-10-16 (ports Claude Code Playbook 0.1.29, source ADR 0023; the owner: "check the codex-playbook repo and see if we can fix the hygiene protocol", "it did not check computer load as well, that alone should have caused a pause", "this playbook is public, so the formula should work for others with less cores as well").
- **Scope:** `codex-playbook-hygiene` rules 13.1, 13.4 and 13.5; `codex-playbook-environment` new rule 9.7; one clause in `codex-playbook-subagents` rule 8.1; one or two rows in each platform skill; the router row in `AGENTS.md`; the manifest, site and parity matrix.

## Context

On 2026-10-15 a Codex lane building a Rust project set its cargo target directory to `/dev/shm`.
The disk was at 96 % used with the owner's floor at 3 % free, so the one filesystem with room was
the memory-backed one, and nothing in the rules said it was off limits. The build finished, the
lane ended, and 44 GB stayed resident in RAM for 26 hours — invisible to every disk measurement
and never anyone's to remove, because a build target is "regenerable and idle" (rule 13.1), a
class with no owner and no close-out duty. On 2026-10-16 four Rust builds started at once on the
same machine; available memory was 2.8 GB of 94, swap was full, and the load reached 145 on 28
cores. None of the four lanes had measured the host: rule 8.1 measures only before a fan-out of
subagents, and a lane's own `cargo build` is not one.

## Decision

1. Rule 13.4: build output and large scratch never live on a memory-backed filesystem. A lane
   checks the filesystem type of a target path first; the platform skill gives the command. No
   room on disk means the disk needs the hygiene procedure, never that memory is the next disk.
2. Rule 13.1: a build target a lane created for itself outside the repository's own output folder
   is "disposable, created by this session" — removed at the lane's close-out.
3. Rule 13.5: hygiene also runs below a memory floor (the local layer's value, 10 % of the
   machine's memory otherwise) or when a memory-backed filesystem is more than a quarter full.
4. Rule 9.7, new: heavy work waits for a quiet host. Load is read as a factor, load ÷ cores, so
   the public text holds on any machine: green below 0.9 starts; orange, 0.9 to 1.8, starts
   nothing new and heavy; red, 1.8 and above or memory below the floor, pauses a running lane
   before its next heavy step too. The owner's absolute numbers for his 28-core box ("up to 25
   is green, up to 35 to orange, above 50 is red") belong in his local layer; the gap he left
   between 35 and 50 is read as the top of orange. Windows, which has no load average, reads
   the bands off its CPU counter at 0.60 and 0.85.

## Alternatives rejected

- **A rule against `/dev/shm` only.** The tell is the filesystem's nature, not its name; the
  platform skill gives the type check instead.
- **Leave removal to the regenerable-and-idle sweep.** That class has no owner by design, which
  is exactly why the target sat for 26 hours.
- **Fold the load check into rule 8.1.** That skill loads for subagent work and speaks of
  fan-outs; a lane mid-build needs the rule in the always-routed environment section.
- **Rule 8.1's four bands, reused as they stand.** They size a fan-out and say nothing about
  pausing work under way; "heavy, above 1.0" would halt a lane on a machine the owner calls
  orange. Rule 9.7 keeps three bands with a red line at 1.8 and points back at 8.1 for sizing.
- **Absolute load numbers in the public text.** They are one machine's; the factor is everyone's.

## Consequences

- A lane on a full disk now stalls and reports rather than building in memory; the disk
  hygiene pass is the fix, and the memory floor now triggers it too.
- The canonical rule set grows to 65; the manifest, the site, the parity matrix and the tests
  follow. No gate is added: rule 9.7 makes a step wait, never ask.
