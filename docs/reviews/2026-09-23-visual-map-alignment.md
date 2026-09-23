# Visual rule map alignment — 2026-09-23

This is a documentation correction to the published 0.1.6 rule text. It does not change managed rules, the installer, or `checkpoint/0.1.6`.

The map now states the local layer's non-authorizing, never-weaken boundary and stale-Override behavior; makes plan task/communication records, next-task continuity, and scoped subagent mode visible; links the conditional communication and Herdr guide; and removes an obsolete router-size claim.

Read-only mechanical review of the visual diff against `checkpoint/0.1.6`: **PASS**, no blocking findings. The reviewer checked `AGENTS.md`, the collaboration and subagent skills, the communication guide, inline JavaScript syntax, and `git diff --check`. After a final wording refinement, `bash tests/rulebook_test.sh` and inline JavaScript syntax passed again. `bash scripts/verify.sh` exited 0 (56 rulebook, 217 local-layer, and 673 installer assertions); its raw ignored output is preserved at `logs/reviews/codex-visual-verify-20260923.log`.
