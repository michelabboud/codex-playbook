# 0006 — Bind local Overrides to a unique, digested rule section

- **Status:** accepted, 2026-09-21 (owner-approved repair to the local-layer trust boundary).
- **Supersedes:** the staleness-check portion of ADR 0005.

## Context

The first local-layer checker established only that an arbitrary quoted phrase
still appeared somewhere in a named managed file. A one-character phrase could
occur many times and still pass; a changed rule section could retain the phrase;
and a stale local Override could thereby keep apparent force. That is unsafe
because the local layer is a user-owned exception mechanism.

## Decision

Each live Override carries three adjacent verifier lines: `**Anchor:**` names a
literal Markdown heading and managed file, `**Rule digest:**` records the
SHA-256 of the normalized bounded section, and `**Dead words:**` supplies a
quote of at least 16 non-whitespace bytes that occurs exactly once in that
section, including overlapping occurrences. The checker refuses an ambiguous heading, a short or repeated quote,
or a malformed verifier; a missing quote or changed digest makes the Override
stale and therefore suspended. Normalization converts CRLF to LF and ignores
trailing blanks, so line-ending and editor-only whitespace changes do not create
false staleness.

Standalone Dead-words lines remain parsed as non-authorizing compatibility
probes. They cannot activate an Override.

## Alternatives rejected

- **A global phrase search.** It cannot identify the rule an Override relies on.
- **A quote-length threshold alone.** Longer text can still survive a material
  rewrite elsewhere in the rule.
- **A digest without a human quote.** It is opaque to the owner and offers no
  readable explanation of what changed.

## Consequences

- Existing Overrides need a deliberate one-time rewrite before they are usable.
- A source update that changes an anchored section pauses the affected action
  until the owner re-reads it and refreshes the local entry.
- The checker requires a standard SHA-256 command; absent tooling is a refusal,
  not a weaker check.
