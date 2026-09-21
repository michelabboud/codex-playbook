---
name: codex-playbook-code
description: Apply Codex Playbook code rules 1.1-1.6 before writing or changing code, and perform mandatory live dependency vetting before adding or major-updating a direct dependency.
---

# 1 · Code — rules 1.1–1.6

*Local layer: if `playbook-local.md` exists in the Codex home, its entries apply only within the non-authorizing, never-weaken boundary in (`AGENTS.md`, "The local layer").*

*Read before writing or changing code. Rule 1.5's vetting is mandatory before any new or major-bumped direct dependency.*

1.1 **NO FAKES, NO STUBS, NO PLACEHOLDERS.** Nothing may look complete that isn't. If you can't finish a piece — blocked, ambiguous, or out of scope — leave an explicit, clearly-marked `TODO` / `unimplemented!()` and tell me. Never paper over a gap.
   - **In practice = vertical slices that are fully real:** build narrow but 100% complete pieces (code + tests + docs) end-to-end before starting the next. Every piece that exists is real, never fake scaffolding.

1.2 **ONLY production grade, no shortcuts.** Concretely: full error handling with no swallowed exceptions, input validation at boundaries, meaningful logging, graceful failure, and no hardcoded secrets or config. Everywhere, always, unless I say otherwise.

1.3 **No magic values.** A default lives as a **named constant**; "hardcoded" means a value with no name, no override where one is warranted, or no stated reason. Make it configurable when an operator or a user would need to change it — "dynamic" means config files or the repo's existing store, never a new datastore (rule 9.3). **Not everything earns a knob:** protocol constants, parameters the algorithm fixes, and security invariants stay constants, named and explained. A config switch nobody will ever set is its own kind of clutter.

1.4 **Match existing patterns.** Follow the conventions already in the repo before introducing a new approach. Don't reformat or restructure existing code as a side effect of an unrelated task — keep diffs focused.

1.5 **Don't add dependencies casually.** Prefer the standard library or an existing dependency first; a new one must earn its place. Before adding any third-party dependency, vet it on the web first:
   - **Latest stable:** confirm the current stable version and pin to it — never adopt something stale or a pre-release without a stated reason.
   - **Security & health:** check the repo, issues, advisories, and developer reviews for known vulnerabilities, active maintenance, and real adoption — not an abandoned or obscure package.
   - **Something better?** compare alternatives and **default to free, open-source** options. **Prefer our own home-cooked / first-party libraries when they meet the bar — dogfood them to strengthen the repos you own — but never at the cost of quality; a substandard library doesn't earn a slot just because it's ours.** Reject abandoned, obscure, or CVE-ridden libraries.
   - **Record the vetting:** write a short report capturing all of the above — version pinned, vulnerability/health findings, alternatives weighed, and why this one won — under `docs/reports/` (or as an ADR per rule 4.2 if the choice is architecturally significant). No dependency lands undocumented.
   - **A tool counts too.** If you automate one of these procedures — a script, a helper, a wrapper — vet it the same way. A tool that quietly becomes load-bearing is a dependency nobody vetted, and the first person to discover it is usually someone who doesn't have it installed.
   - **Scope:** adding or major-bumping a **direct** dependency, dev-deps included; transitive deps are covered by rule 6.3's audit. If the web is unreachable, say so and stop at the vetting step — never vet from memory.

1.6 **Vendoring third-party code earns its provenance.** When copying external code into a repo (vendored crates, harvested skills, lifted snippets), preserve its license and record where it came from — source URL, commit/version, and license — in the file or a `NOTICE`. Never strip an upstream license. Re-vendor from upstream rather than editing a vendored copy in place.

---
