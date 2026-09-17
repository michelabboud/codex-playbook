# GitHub Pages runbook

## Service

The visual playbook is the dependency-free `docs/index.html` site published by
GitHub Pages from the canonical repository's `main` branch and `/docs` folder.
There is no application server, database, container, port, or background
process.

## Publish

1. Run `./scripts/verify.sh` on the exact candidate commit.
2. Inspect `docs/index.html` at desktop and mobile widths, exercise search and
   keyboard navigation, and confirm the browser console is clean.
3. Merge the approved pull request into `main` without rewriting history.
4. Confirm the Pages deployment resolves the expected commit and the public URL
   serves the new version marker.

## Stop or roll back

GitHub Pages configuration is repository-owner infrastructure and is not
changed by this playbook. To roll back site content, revert the faulty commit
through a new pull request; never force-push `main` or move a published tag.

## After a platform incident

Check GitHub Pages status and the repository's deployment view. If the exact
commit passed local verification but Pages is stale or unavailable, record the
external incident rather than modifying unrelated repository content.
