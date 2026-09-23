# GPT-6 Astra, Sol, and Luna: dated operator guidance

Checked 2026-09-23 against OpenAI's [Astra](https://developers.openai.com/api/docs/models/gpt-6-astra), [Sol](https://developers.openai.com/api/docs/models/gpt-6-sol), [Luna](https://developers.openai.com/api/docs/models/gpt-6-luna), and [pricing](https://developers.openai.com/api/docs/pricing) pages. This is guidance, not an installed binding or a change to the review rules. Confirm the models and efforts your runtime actually exposes before dispatch.

| Candidate | Listed Standard API text price per 1M tokens, short context up to 272K (input/output) | Suggested trial |
|---|---:|---|
| GPT-6 Astra | $10 / $50 | Top planning, architecture, and highest-risk review |
| GPT-6 Sol | $2 / $10 | Standard complex coding at medium effort; Strong deep review at high or maximum effort when measured |
| GPT-6 Luna | $0.10 / $0.50 | Fast, bounded mechanical implementation with a clear spec |

The model-family mapping is **GPT-5.6 Sol → GPT-6 Astra** (flagship), **GPT-5.6 Terra → GPT-6 Sol** (value mid-tier), and **GPT-5.6 Luna → GPT-6 Luna** (light). There is no GPT-6 Terra. This is a product-positioning map, not a claim that Sol is weak: Sol is explicitly aimed at complex coding and agentic tasks and may fill Strong with enough effort and evidence. A model-and-effort pair defines a tier, so one model can fill more than one row when the configurations are genuinely different.

Luna's listed token rates are 20 times lower than Sol's, and Astra's are five times higher than Sol's at short context. Above 272K tokens, the GPT-6 models have higher long-context rates; consult the live price pages. Token-price ratios do not establish end-to-end savings or review quality: retries, reasoning tokens, orchestration, and review misses can erase the saving. None of these model pages is a head-to-head evaluation of this playbook's tasks.

Recommendation: trial Luna on deterministic, low-risk implementation work and record acceptance rate, correction effort, elapsed time, and total tokens. Do not assign mechanical review to Fast without a comparative defect-finding measurement; retain the Standard floor. Use Sol as the value workhorse, including Strong-tier deep review at high effort where the runtime and evidence support it; use Astra for Top work. Retain independent reviewer/session requirements. Bind exact model IDs *and* reasoning effort in the owner's dated file outside the managed packages, as the [roster](../../.agents/skills/codex-playbook-subagents/references/roster.md) requires. Recheck prices before relying on this note.
