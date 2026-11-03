# Deep review — bounded execution and visibility

Target `f1eca0f38b8aa05861ee6cf3779246bcc56ff6c5`, base
`6e3b5c75db084d24d44eee905b7fa902902b39c7`. Independent GPT-6.1 Sol xhigh,
native agent `deep_review`, production mode. Git-object source review and direct
shared-receipt inspection; no broad tests repeated or source edits.

## Cold read and findings

CONFIRMED: dashboard.html lines 37/39 rewrite both polite live regions each second
even with unchanged text. The reviewer executed the actual function twice against
a fake DOM and observed two identical writes to each region. This risks repeated
screen-reader announcements; actual assistive-technology cadence is UNVERIFIED.
Required repair: change live-region text only when its value changes.

REFUTED: bounded investigation weakens acceptance. Rules 14.4 and 7.2 retain
confirmed floor defects, realistic harm and material unresolved acceptance evidence
as blockers. Destructive refusals cannot use the retry allowance.

REFUTED: cleanup authorizes deletion by age. Rule 13 retains ownership, liveness,
ignored-state, evidence and Git-removal checks; placement requires an explicit
destination instruction for another mount.

CONFIRMED: scope/orchestration changes are coherent. Failed attempts retain their
receipts across replacements; cloud-agent count and host load are distinct;
independent review floors remain. The board claims reported state only.

Shared receipt independently inspected: 244 rulebook, 217 local-layer, 789 installer
assertions and 25 dashboard tests passed. Candidate association and process exit
are coordinator provenance, not a second independent execution.

Verdict on original candidate: one focused dashboard repair required; no blocking
policy inconsistency. Installation remains separate and unaccepted. Successor
repair/review will be recorded without discarding this original finding.

## Focused successor review

PASS on `52f7cd0d64494837b54947347a8dbdcf7708b373`. The same independent
reviewer verified conditional live-region text/visibility updates and the actual
updater regression for unchanged ticks and stale transitions. Direct repair receipt
shows 26 tests passed. No new findings. Actual screen-reader output remains untested.
