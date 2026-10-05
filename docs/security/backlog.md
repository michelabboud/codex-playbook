# Security backlog

## DASH-H1 — private filesystem ancestor substitution

- Date: 2026-10-05; review: independent deep dashboard source review.
- Found on: 264c4b15c5a2c604e3882b2542680c00ef99e613.
- Story: a process with the same OS identity and private filesystem write
  access could swap state ancestors between checks and I/O to redirect it.
- Missing prerequisite at the supported trust boundary: access to the
  operator's private identity/parent tree; session IDs do not authenticate
  against that same OS user.
- Severity: low; likelihood: requires that existing write access.
- Due: hardening. Status: unverified, no reproduction or exploit established.
- Original note and classification retained in the dashboard close-out record
  and the sealed review evidence. No security floor bypass is claimed.


## DASH-MEC02 — overwritten interleaved unrecognized HTML — closed

- Date: 2026-10-05; found on bb2271fa471c9023254ce0201265766dd7cf788e.
- Story: a same-user process inserts user-authored HTML after registry
  publication; a removed ownership check lets the next generated write replace
  that file. This is a data preservation failure, without a network attacker.
- Severity: medium; likelihood: requires that narrow local interleaving.
- Due: now. Status: fixed in 1378f4f5a310b4e8891993d5e81c10feb8112bdd.
- The original source preserved the file; the first repair regressed it.
  A baseline comparison reproduced the regression, and the restored check
  passed independent mechanical/deep fixtures and the 24-test helper suite.
- Original blocked reports, seals and fixtures remain retained; no history was
  rewritten. Final package verification and source push are separate gates.
