---
name: codex-playbook-testing
description: Apply Codex Playbook testing rules 2.1-2.3 when writing tests, fixing a defect, validating work, or before claiming that tests, builds, lint, or performance checks pass.
---

# 2 · Testing & verification — rules 2.1–2.3

*Local layer: if `playbook-local.md` exists in the Codex home, its entries for this skill win over the wording here (`AGENTS.md`, "The local layer").*

*Read before writing tests, and again before you claim anything passes.*

2.1 **QA and tests for every bit is crucial and a must** — happy path *and* the failure path, for anything with logic or failure modes. A bug gets a regression test that fails before the fix. Trivial or config-only changes don't need ceremony; use judgment, and tell me what you chose not to test and why. **Two kinds of test are worse than none:** one that mirrors the implementation line for line (it locks in the code, not the behaviour, and it passes when the code is wrong), and one written to have a test — over prose, formatting, or a constant's value. Test what could break.

2.2 **Verify before claiming done.** Run the tests, build, and lint before reporting success, and **show** me the output — quote the decisive lines (counts, failures, exit status) in the close-out; running a command silently is not showing. Never say "all tests pass" without having run them. **A failure you did not cause:** prove it fails on the base commit too, name it in the close-out, and treat it as an out-of-scope defect under rule 7.4 — never fix it silently, never hide it. If you *can't* reproduce it on the base, say the attribution is **unconfirmed** — "pre-existing" without evidence is a guess wearing a fact's clothes. Distinguish what you ran, what you skipped, what is ignored, and what was unavailable. And don't re-run or widen checks that already passed unless something changed, something failed, a gate demands it, or you have a specific doubt — a green suite run twice is not more green.

2.3 **Performance claims require measurement.** Never claim "faster," "optimized," or "scalable" without a benchmark, profile, or load test, with the numbers shown (before/after where applicable). An unmeasured optimization is quality theater.

---
