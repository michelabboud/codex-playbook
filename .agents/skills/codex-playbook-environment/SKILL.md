---
name: codex-playbook-environment
description: Apply Codex Playbook environment rules 9.1-9.6 before claiming ports, touching containers, adding datastores, handling logs or secrets, or leaving processes running.
---

# 9 · Environment & operations — rules 9.1–9.6

*Local layer: if `playbook-local.md` exists in the Codex home, its entries apply only within the non-authorizing, never-weaken boundary in (`AGENTS.md`, "The local layer").*

*Read before claiming a port, touching a container, adding a datastore, handling logs or secrets, or leaving anything running.*

9.1 **Ports:** before assigning a port, verify it's free — on the machine (the matching platform skill gives the command) *and* against the claims registry at **`~/.config/fleet/ports/`** (one file per project). Claim your port by writing or updating the project's file there; also note it in the project README. Never reuse a conflicting port. The `fleet` path is the Codex owner's explicit override of the Claude source's older `agent-rules` path.

9.2 **Docker:** name every container/volume/network with the project prefix (e.g. `myapp-api`, `myapp-db`), and give a throwaway test resource a run id you can recognise later. **A prefix is naming, not permission.** Anything without the prefix you do not stop, remove, restart, or modify unless I tell you to — and a matching prefix still isn't enough on its own: check that the thing is yours, from *this* task, before you touch it. Another run's container, an operator's, or a shared one can carry a familiar name. Export the logs you need before removing anything, and never remove data that isn't disposable.

9.3 **Datastores:** never introduce a native datastore — PostgreSQL, MySQL, Redis, etc. — unless I explicitly say so. Default to file/embedded options (config files, SQLite).

9.4 **Logs and durable evidence:** never delete, truncate, or wholesale replace log files unless I explicitly consent to the exact targets. Rotate logs without losing entries; compress only rotated or inactive logs after checking no process writes them, verify the compressed copy, and keep the original unless I explicitly consent to its deletion. Never compress an actively written log. Save logs, reports, documents, and guides as they are produced; never silently remove any of them during cleanup. Log files are preserved and `.gitignore`d by default, not auto-committed; commit a log only if I decide otherwise and its contents are reviewed for secrets and PII. Save and commit repository reports, documents, and guides in the normal close-out chain. If a log is retained outside the repository, report where it is. Rule 9.5 still forbids committing secrets or logging credentials/PII.

9.5 **Secrets:** never commit secrets, keys, or tokens. Secrets come from environment variables or a secrets store, never source. Never log credentials or PII. **Never print or echo a secret's value into the conversation — not even "just to look"; transcripts are archived.** Inspect secrets by name and presence. A length or a hash is a last resort, not a habit — a hash of a short or guessable secret is a lookup away from the secret. Never put one on a message bus or through a collaboration tool.

9.6 **Long-running processes: nothing keeps running silently.** Anything started that outlives the task — containers, soak tests, watchers, dev servers — is either stopped at close-out or explicitly reported as left running, with the reason and the exact teardown command.
