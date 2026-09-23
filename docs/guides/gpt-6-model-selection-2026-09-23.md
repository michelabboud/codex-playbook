# GPT-6 Sol and Luna: dated operator guidance

Checked 2026-09-23 against OpenAI's [Sol model page](https://developers.openai.com/api/docs/models/gpt-6-sol), [Luna model page](https://developers.openai.com/api/docs/models/gpt-6-luna), and [pricing](https://developers.openai.com/api/docs/pricing). This is guidance, not an installed binding or a change to the review rules. Confirm the models and efforts your runtime actually exposes before dispatch.

| Candidate | Listed Standard API text price per 1M tokens (input/output) | Suggested trial |
|---|---:|---|
| GPT-6 Sol | $2 / $10 | Strong deep review or complex coding at high or maximum available effort |
| GPT-6 Luna | $0.10 / $0.50 | Fast, bounded mechanical implementation with a clear spec |

Luna's listed token rates are 20 times lower than Sol's. That does not establish lower total task cost or sufficient review quality: retries, extra tokens, failed changes, and review misses can erase the saving. Sol's positioning fits complex coding and agentic work; Luna's fits focused, high-volume work. Neither product page is a head-to-head evaluation of this playbook's tasks.

Recommendation: trial Luna on deterministic, low-risk implementation work and record acceptance rate, correction effort, elapsed time, and total tokens. Do not assign mechanical review to Fast without a comparative defect-finding measurement; retain the Standard floor. Use Sol for Strong-tier deep review where the runtime and budget permit, while retaining independent reviewer/session requirements. Bind exact model IDs *and* reasoning effort in the owner's dated file outside the managed packages, as the [roster](../../.agents/skills/codex-playbook-subagents/references/roster.md) requires. Recheck prices before relying on this note.
