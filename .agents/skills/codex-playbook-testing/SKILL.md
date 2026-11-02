---
name: codex-playbook-testing
description: Apply Codex Playbook testing rules 2.1-2.3 when writing tests, fixing a defect, validating work, or before claiming that tests, builds, lint, or performance checks pass.
---

# 2 · Testing & verification — rules 2.1–2.3

*Local layer: if `playbook-local.md` exists in the Codex home, its entries apply only within the non-authorizing, never-weaken boundary in (`AGENTS.md`, "The local layer").*

*Read before writing tests, and again before you claim anything passes.*

2.1 **QA and tests for every bit is crucial and a must** — happy path *and* the failure path, for anything with logic or failure modes. A bug gets a regression test that fails before the fix. Trivial or config-only changes don't need ceremony; use judgment, and tell me what you chose not to test and why. **Two kinds of test are worse than none:** one that mirrors the implementation line for line (it locks in the code, not the behaviour, and it passes when the code is wrong), and one written to have a test — over prose, formatting, or a constant's value. Test what could break.

2.2 **Verify before claiming done.** Run the tests, build, and lint before reporting success, and **show** me the output — quote the decisive lines (counts, failures, exit status) in the close-out; running a command silently is not showing. Never say "all tests pass" without having run them. **A failure you did not cause:** prove it fails on the base commit too, name it in the close-out, and treat it as an out-of-scope defect under rule 7.4 — never fix it silently, never hide it. If you *can't* reproduce it on the base, say the attribution is **unconfirmed** — "pre-existing" without evidence is a guess wearing a fact's clothes. Distinguish what you ran, what you skipped, what is ignored, and what was unavailable. And don't re-run or widen checks that already passed unless something changed, something failed, a gate demands it, or you have a specific doubt — a green suite run twice is not more green.

    **Keep evidence deliberately, not every working copy.** Before tests create substantial data, apply rule 13.4's separate evidence and scratch layout and rule 13.5's measured retention budget. Preserve exact-candidate receipts, raw failure output and necessary reproduction inputs, including interrupted or inconclusive attempts; keep successful-run records too. At completion, classify generated fixtures individually and apply the existing cleanup checks. A new green result never erases an earlier red result, and neither status grants permission to remove protected files.

    **Batch expensive checks, keep feedback local.** At task grain, run the focused tests, lint/type checks and build checks needed for the changed behavior and its immediate consumers. Run broad expensive suites once on the frozen integrated candidate at a coherent batch boundary, rather than after every small task. Record a compact check matrix: changed area, focused checks, broad checks due, candidate and result. For independent low-risk work, use the existing 5–15-task or roughly 2,000-line batch bound; close earlier for risk, dependency, accumulated uncertainty or a required repository gate. The count is a ceiling, not a quota. A focused check does not establish a full-suite pass: each task receipt names exactly what ran and which broad gates remain pending. A failed focused check is fixed before that task closes. Required batch, milestone and release gates must pass on the exact candidate being accepted before their acceptance is claimed. After an integrated candidate changes, rerun impacted checks; rerun a full gate when required, or when impact cannot be bounded. Do not transfer an old pass to changed bytes without a recorded scope justification. Required independent checks and accepted-prerequisite constraints still apply.

2.3 **Performance claims require measurement.** Never claim "faster," "optimized," or "scalable" without a benchmark, profile, or load test, with the numbers shown (before/after where applicable). An unmeasured optimization is quality theater.

---
