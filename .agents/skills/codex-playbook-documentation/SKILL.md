---
name: codex-playbook-documentation
description: Apply Codex Playbook documentation rules 4.1-4.3 when documenting a feature, updating project records, or deciding whether an architectural decision record is required.
---

# 4 · Documentation & ADRs — rules 4.1–4.3

*Local layer: if `playbook-local.md` exists in the Codex home, its entries apply only within the non-authorizing, never-weaken boundary in (`AGENTS.md`, "The local layer").*

*Read when documenting a feature, and before writing an ADR.*

*Maximum documentation of everything that isn't obvious from the code — the why, the decisions, the gotchas — kept current. Stale docs are worse than none.*

4.1 **Document sufficiently for a new contributor** to understand each feature. Capture reasoning, not narration of obvious code.

4.2 **No undocumented decisions — keep an ADR log** under `docs/adr/` for every decision that passes ANY of: (a) ≥2 viable options with genuine trade-offs; (b) reversing it later would touch multiple modules or cost more than a day; (c) a new contributor would ask "why is it done this way?"; (d) it rejects an obvious or popular alternative. Skip ADRs for choices with one reasonable answer — and for routine naming, local helpers, and ordinary implementation calls. The log is worth reading only if everything in it earned its place.
    - **Write it at decision time, not close-out.**
    - **Format:** numbered (`NNNN-slug.md`), with Context / Decision / Alternatives rejected (and why) / Consequences / Status. Index in `docs/adr/README.md`.
    - **Never edit or delete an old ADR** — supersede it. **Check the ADR log before changing architecture.**

4.3 **After each task and feature, update the affected docs:** `CHANGELOG.md`, `PROGRESS.md`, `PLAN.md` (status and dates of the plan the task belongs to), `BACKLOG.md` (anything deferred or spotted), and `README.md`/`ARCHITECTURE.md` if anything they describe changed. Create new guides/docs for new features.

---
