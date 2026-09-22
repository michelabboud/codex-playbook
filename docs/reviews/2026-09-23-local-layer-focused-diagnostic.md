# Focused diagnostic — local-layer repair at `358ab65`

**Status:** FAIL, read-only pinned-object diagnostic; not a completed release gate.
**Target:** `358ab65cec2630a12214505870e05cd37d95899f`.
**Reviewer:** requested GPT-6 Sol; actual effort and token use were not exposed by the runner. The review used a fresh child context, but it was not a separate-process dual-blind gate. No tests were run by the reviewer because the brief confined it to Git objects.

## Findings and coordinator disposition

| Finding | Severity | Disposition |
|---|---|---|
| `scripts/restore.sh` checks quoted words and a section digest but can restore a pre-local-layer `AGENTS.md` that never loads a preserved local file. An unchanged `## Classify the Request Before Acting` section in historical `739921e` has the same digest as this target, so a valid Override can pass preflight while becoming inert. Fill/Add-only files have no quoted-word check at all. | Blocking | Confirmed against the pinned router and restore preflight. Repair and regression test required before publication. |
| A UTF-8 BOM before the first `**Override` is missed by the canonical parser and unrecognized-entry guard; a zero-search exit 0 is possible. | Blocking | Confirmed against scanner shape. Reject a BOM explicitly. |
| `parse_anchor` counts a raw heading before stripping CRLF, despite the normalized-section contract. | Major | Confirmed. Normalize before heading count. |
| `section_occurrences` advances by the entire needle, so overlapping occurrences are undercounted. | Major | Confirmed. Count each possible start position. |

The reviewer observed that the prior NUL, `-h`, whole-file line-bound, authority, and minimum-anchor repairs are present. That is not a final PASS on those repairs; a focused deep re-review of the fix commit and the original target is still owed.

## Evidence boundary

The reviewer used `git show`, `git diff`, and other read-only inspection. Exact test exits and runtime model effort were unavailable from that review. The coordinator's follow-up tests and fix commits are recorded separately in the batch ledger; they do not retroactively change this verdict.
