# Root reasoning setting follow-through

The OpenAI Docs skill was used for the explicit user model/configuration requirement. Current official Astra documentation lists `max` among supported reasoning values. The App Server documentation permits model/effort overrides when starting a turn, while steering an active turn does not take turn-level overrides. [Astra model](https://developers.openai.com/api/docs/models/gpt-6-astra), [App Server](https://learn.chatgpt.com/docs/app-server).

Project defaults and all four workers already request Astra/max. To apply the same explicit user choice to continuation through a supported app surface, root called send_message_to_thread once for current thread01a06dfc-8a6b-7f12-bde6-895373e9a7a8 with `model=gpt-6-astra`, `thinking=max` and a cohesive continuation instruction preserving the active goal/role/resume protocol. The tool accepted and delivered the continuation instruction. This is not proof it changed the current in-flight inference.

Immediately reread scoped rollout turn_context fields: latest observed turn still says Astra/ultra. GOV-001 therefore remains open pending an actual new max turn. Do not loop self-messages, relabel previous turns, start another goal or mark the goal complete. All production/review work continues under the same durable goal.
