---
"continuously-running-agents": minor
---

LLM provider setup with OVHCloud integration

Adds comprehensive guide for setting up LLM provider (Anthropic API) for continuous agents:

- **New document**: 08-llm-provider-setup.md (~1,050 lines)
  - API key architecture (one key serves unlimited agents)
  - Subscription tiers decision matrix (Pro vs Max vs pay-per-use)
  - Single VM vs multiple VMs guidance
  - Resource requirements for 1-50+ agents
  - Cost calculators and break-even analysis
  - Rate limit management strategies

- **OVHCloud integration**:
  - Added OVHCloud to infrastructure providers (01-infrastructure.md)
  - Detailed OVHCloud setup instructions
  - Instance type recommendations for different agent counts
  - Cost comparison with other providers

- **Enhanced cost optimization** (05-cost-optimization.md):
  - Max plan advantages and best practices
  - API key management section
  - Clarified when multiple API keys are/aren't needed
  - Common misconceptions addressed

- **Navigation updates** (README.md):
  - Added 08-llm-provider-setup.md to core guides
  - Updated navigation by topic
  - Updated knowledge base stats
