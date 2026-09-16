---
name: codex-playbook-dependency-review
description: Vet a new or major-updated direct dependency before adding it, including current version, security, maintenance, adoption, alternatives, license, and a durable report.
---

# Dependency review

Use this procedure when work would add a new direct third-party dependency or
major-upgrade one. It implements the dependency rule in the installed
`AGENTS.md`; it does not create another approval gate.

## Procedure

1. State the capability the dependency must provide and why the standard
   library, existing dependencies, or a small first-party implementation do not
   meet it.
2. Use current primary sources to identify the latest stable version, supported
   runtimes, license, release cadence, maintainers, and official security
   advisories. Never vet from memory.
3. Compare at least two credible alternatives when they exist. Include the
   zero-dependency option.
4. Record the review in `docs/reports/YYYY-MM-DD-<dependency>-review.md` with:
   package and pinned version; source and license; health and adoption evidence;
   security findings; alternatives; decision; operational consequences; exact
   install and audit commands.
5. Add the dependency with the repository's package manager, update its lockfile,
   and run the narrow tests first.
6. Run the ecosystem audit and the repository's full required checks. A known,
   fixable vulnerability is fixed before the task closes. An unfixable finding
   is reported with its advisory identifier and blocks a release.

If current source access is unavailable, stop the dependency addition and report
the missing evidence. Do not substitute old knowledge for live vetting.
