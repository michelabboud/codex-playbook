# Compile-lease removal: independent deep review

Date: 2026-10-25. Base `abe48b61c41b2c0ff4d77f8da1e015e0e7aa09b8`;
target `e15f1c99b55d37abbd0e79c7a9e8401b155ee9d0`.
Reviewer: fresh native Codex context, requested GPT-6.1 Sol at xhigh.
Git objects only; no inherited conversation, source writes, tests, installation
or publication. Same-family review; no provider model attestation claimed.

**Cold-read verdict: ACCEPT. No actionable security, quality or performance findings.**

- Environment rule 9.7 explicitly removes compile-lease admission for
  single-crate and workspace-wide commands. Fresh measurements, load bands
  and the memory floor remain intact.
- Hygiene ownership, disk and memory-backed-filesystem protections are unchanged.
- The regression checks require the new scope-explicit wording and reject the
  retired requirement across the router and skills; historical documents do
  not cause a false failure.
- All six public version carriers agree on 0.1.20, and the site matches.

Limitations: source inspection only. The reviewer did not run tests, inspect
Root's verification output, or verify publication or installation.

Root validation: CONFIRMED against the pinned diff and existing guard clauses.
No finding required a repair. Automated verification is retained separately at
`/home/michel/.local/state/codex-playbook/2026-10-25-no-lease/verify-02.log`:
244 rulebook checks, 217 local-layer assertions, 789 installer lifecycle
assertions and 24 dashboard tests, full verifier exit 0.
