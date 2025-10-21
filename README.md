# Continuously Running AI Agents - Knowledge Base

> Comprehensive guide to building and running autonomous Claude Code agents 24/7, based on research and best practices from the community (March-October 2025).

**Research Period**: March 2025 - October 2025
**Date Compiled**: October 15, 2025

## Overview

This knowledge base consolidates information from industry leaders like **Pieter Levels (@levelsio)** and **Eric Zakariasson (@ericzakariasson)**, along with proven community patterns for running Claude Code agents continuously.

## 🚀 Start Here

**New to continuously running agents?** Begin with our structured learning paths:

→ **[00-getting-started.md](00-getting-started.md)** - Choose your path based on skill level and goals

### Quick Path Selection

- **Complete Beginner?** → [Path 1: Absolute Beginner (1-2 hours)](00-getting-started.md#path-1-absolute-beginner-1-2-hours)
- **Need Cloud Deployment?** → [Path 2: Cloud Deployment (2-3 hours)](00-getting-started.md#path-2-cloud-deployment-2-3-hours)
- **Multiple Agents?** → [Path 3: Multi-Agent System (4-6 hours)](00-getting-started.md#path-3-multi-agent-system-4-6-hours)
- **Production System?** → [Path 4: Production Grade (1-2 days)](00-getting-started.md#path-4-production-grade-system-1-2-days)
- **Indie Hacker?** → [Path 5: Pieter Levels Style (2-3 hours)](00-getting-started.md#path-5-pieter-levels-style-2-3-hours)

## Research Sources

- **X/Twitter**: Posts from @levelsio, @ericzakariasson, and community (March 2025+)
- **GitHub Projects**: Tmux Orchestrator, Claude Squad, tmux-mcp, VibeTunnel
- **Official Docs**: Anthropic Claude Code documentation, API references
- **Community Blogs**: Mobile setups, cost optimization, security guides
- **Open Source Projects**: Working implementations and patterns

## Documentation Structure

### Navigation Guide

**[00-getting-started.md](00-getting-started.md)** - 🎯 **START HERE** - Structured learning paths for all skill levels

### Core Guides (Read in Order)

1. **[01-infrastructure.md](01-infrastructure.md)** - Cloud VPS setup, providers, server configuration
2. **[02-tmux-setup.md](02-tmux-setup.md)** - Session persistence, multi-agent orchestration
3. **[03-remote-access.md](03-remote-access.md)** - Mobile access, Tailscale, Mosh, web terminals
4. **[04-claude-configuration.md](04-claude-configuration.md)** - Autonomous operation, loops, models
5. **[05-cost-optimization.md](05-cost-optimization.md)** - Pricing strategies, caching, budgeting
6. **[06-security.md](06-security.md)** - Server hardening, isolation, monitoring
7. **[07-examples.md](07-examples.md)** - Real-world setups and working patterns
8. **[08-llm-provider-setup.md](08-llm-provider-setup.md)** - API keys, subscriptions, OVHCloud integration

### Navigation by Topic

**Infrastructure & Deployment**
- VPS providers and setup → [01-infrastructure.md](01-infrastructure.md)
- Server sizing and selection → [01-infrastructure.md](01-infrastructure.md#server-sizing-guidelines)
- OVHCloud setup → [01-infrastructure.md](01-infrastructure.md#ovhcloud), [08-llm-provider-setup.md](08-llm-provider-setup.md#ovhcloud-integration)
- API key management → [08-llm-provider-setup.md](08-llm-provider-setup.md#api-key-architecture)
- Security hardening → [06-security.md](06-security.md)

**Agent Management**
- TMUX basics and persistence → [02-tmux-setup.md](02-tmux-setup.md)
- Multi-agent coordination → [02-tmux-setup.md](02-tmux-setup.md#multi-agent-coordination-protocol)
- Pieter Levels' /workers/ pattern → [04-claude-configuration.md](04-claude-configuration.md#pieter-levels-workers-folder-pattern)

**Remote Access**
- Mobile coding setup → [03-remote-access.md](03-remote-access.md)
- Tailscale configuration → [03-remote-access.md](03-remote-access.md#method-3-tailscale-private-network---most-secure)
- Web terminal access → [03-remote-access.md](03-remote-access.md#method-5-gotty--ttyd-web-terminal)

**Tools & Examples**
- Claude Squad (5-10 agents) → [07-examples.md](07-examples.md#example-4-claude-squad-parallel-task-execution)
- Agent Farm (50+ agents) → [07-examples.md](07-examples.md#example-9-agent-farm-50-parallel-agents)
- Docker setup → [07-examples.md](07-examples.md#example-10-docker--claude-code-isolated-agents)
- Tool comparison matrix → [07-examples.md](07-examples.md#tool-comparison-matrix)

**Cost & Security**
- Pricing breakdown → [05-cost-optimization.md](05-cost-optimization.md)
- Subscription vs API pricing → [08-llm-provider-setup.md](08-llm-provider-setup.md#subscription-vs-pay-per-use-decision-matrix)
- Prompt caching → [05-cost-optimization.md](05-cost-optimization.md#1-prompt-caching-critical)
- Security checklist → [06-security.md](06-security.md)

## Quick Start

### For the Impatient

```bash
# 1. Get a cheap VPS (Hetzner €4.99/mo or DigitalOcean $5/mo)

# 2. Install essentials
ssh root@your-vps
apt update && apt install -y nodejs npm tmux mosh
npm install -g @anthropic-ai/claude-code

# 3. Set API key
export ANTHROPIC_API_KEY="sk-ant-..."

# 4. Start agent in tmux
tmux new -s agent
claude

# 5. Detach (Ctrl+b, d) - Agent keeps running!

# 6. Reconnect anytime
tmux attach -t agent
```

### For the Thorough

Follow the guides in order for a complete understanding.

## Use Cases

| Use Case | Monthly Cost | Guide |
|----------|-------------|-------|
| Solo dev - mobile coding | ~$10 | [03-remote-access.md](03-remote-access.md) + [07-examples.md](07-examples.md#example-2-mobile-claude-code-setup) |
| Rapid prototyping | $5 | [01-infrastructure.md](01-infrastructure.md#the-rawdog-dev-on-the-server-approach) |
| Multi-agent orchestration | $15-30 | [02-tmux-setup.md](02-tmux-setup.md#advanced-multi-agent-orchestration) |
| 24/7 autonomous development | $20-100 | [04-claude-configuration.md](04-claude-configuration.md#infinite-agent-loops) |
| Cost-optimized continuous | $10-20 | [05-cost-optimization.md](05-cost-optimization.md) |

## Key Technologies

- **Claude Code CLI**: Official Anthropic agentic coding tool
- **tmux**: Terminal multiplexer for session persistence
- **Mosh**: Mobile shell that survives network changes
- **Tailscale**: Zero-config private VPN using WireGuard

## Key Insights

### What Works Well

- **tmux + Mosh + Tailscale**: Universal combination for persistence and remote access
- **Prompt Caching**: Essential for cost control (90% savings)
- **Model Selection**: Haiku for routine, Sonnet for standard, Opus for critical
- **Checkpointing**: Git commits or Claude's checkpoint feature
- **Monitoring**: Log aggregation, alert on anomalies

### Common Pitfalls

- No loop detection → agents get stuck repeating failed actions
- Unconstrained costs → Opus 24/7 with no caching = expensive
- No rollback plan → agent breaks something, no easy recovery
- Public SSH exposure → use Tailscale + fail2ban
- Shared credentials → isolate agent access

## Security Warnings

⚠️ **Before You Start**:

1. Never commit API keys to git
2. Always use SSH key authentication
3. Enable fail2ban on exposed servers
4. Use Tailscale for private networking
5. Run `--dangerously-skip-permissions` only in isolated environments
6. Monitor agent activity
7. Set up backups and checkpoints

## Community & Resources

### Follow These People

- **@levelsio**: Pioneer of "rawdog vibecoding", shares VPS setups
- **@ericzakariasson**: Cursor team, explains subagent patterns

### GitHub Projects

- **Tmux Orchestrator**: Autonomous multi-agent system
- **Claude Squad**: Manage multiple agents in tmux
- **tmux-mcp**: Claude integration with tmux sessions
- **VibeTunnel**: Web-based terminal access

### Recommended Providers

- **Hetzner**: €4.99/mo, excellent performance, community favorite
- **DigitalOcean**: $5-8/mo, good docs, official MCP server
- **Tailscale**: Free tier, zero-config VPN

## Quick Reference

### Common Commands

```bash
# Start agent in tmux
tmux new -s agent "claude -p 'Your task'"

# Detach from tmux
Ctrl+b, then d

# Reattach to agent
tmux attach -t agent

# List all sessions
tmux ls

# Kill session
tmux kill-session -t agent

# Connect via Mosh (survives network changes)
mosh user@server

# Check agent cost today
bash ~/scripts/cost-tracker.sh
```

### Common Tasks

| Task | Command/Guide |
|------|--------------|
| Install Claude Code | `npm install -g @anthropic-ai/claude-code` |
| Deploy to VPS | [Path 2 Tutorial](00-getting-started.md#path-2-cloud-deployment-2-3-hours) |
| Setup mobile access | [03-remote-access.md](03-remote-access.md) |
| Run multiple agents | [Claude Squad Guide](07-examples.md#example-4-claude-squad-parallel-task-execution) |
| Setup cron automation | [Pieter Levels Pattern](04-claude-configuration.md#pieter-levels-workers-folder-pattern) |
| Reduce costs | [Cost Optimization Guide](05-cost-optimization.md) |
| Secure setup | [Security Checklist](06-security.md) |

### Troubleshooting

**Agent won't start?**
→ See [00-getting-started.md#troubleshooting-guide](00-getting-started.md#troubleshooting-guide)

**Costs too high?**
→ See [05-cost-optimization.md](05-cost-optimization.md)

**Can't connect remotely?**
→ See [03-remote-access.md](03-remote-access.md)

**Agent keeps crashing?**
→ See [Self-Healing Agent](07-examples.md#example-11-self-healing-agent-system)

## Next Steps

### Recommended Path

1. **Choose your learning path** → [00-getting-started.md](00-getting-started.md) 🎯 **START HERE**
2. **Follow the tutorials** → Step-by-step guides for your chosen path
3. **Study real examples** → [07-examples.md](07-examples.md)
4. **Join the community** → Share your setup and learn from others

### Progressive Enhancement

The knowledge base supports progressive enhancement:

- **Week 1**: Basic VPS + Claude in tmux ([Path 1](00-getting-started.md#path-1-absolute-beginner-1-2-hours))
- **Week 2**: Add Tailscale for secure access ([Path 2](00-getting-started.md#path-2-cloud-deployment-2-3-hours))
- **Week 3**: Add Mosh for mobile access ([03-remote-access.md](03-remote-access.md))
- **Week 4**: Enable autonomous mode with safeguards ([04-claude-configuration.md](04-claude-configuration.md))
- **Week 5**: Add monitoring and cost optimization ([05-cost-optimization.md](05-cost-optimization.md))
- **Week 6**: Experiment with multi-agent setups ([Path 3](00-getting-started.md#path-3-multi-agent-system-4-6-hours))

### By Use Case

| Your Situation | Recommended Starting Point |
|----------------|---------------------------|
| Complete beginner | [Path 1: Absolute Beginner](00-getting-started.md#path-1-absolute-beginner-1-2-hours) |
| Solo developer | [Path 2](00-getting-started.md#path-2-cloud-deployment-2-3-hours) → [Path 5](00-getting-started.md#path-5-pieter-levels-style-2-3-hours) |
| Small team (2-5 people) | [Path 2](00-getting-started.md#path-2-cloud-deployment-2-3-hours) → [Path 3](00-getting-started.md#path-3-multi-agent-system-4-6-hours) |
| Production deployment | [Path 2](00-getting-started.md#path-2-cloud-deployment-2-3-hours) → [Path 4](00-getting-started.md#path-4-production-grade-system-1-2-days) |
| Large codebase (20+ repos) | [Path 3](00-getting-started.md#path-3-multi-agent-system-4-6-hours) → [Agent Farm](07-examples.md#example-9-agent-farm-50-parallel-agents) |
| Mobile developer | [Path 2](00-getting-started.md#path-2-cloud-deployment-2-3-hours) + [Mobile Setup](07-examples.md#example-2-mobile-claude-code-setup) |
| Indie hacker | [Path 5: Pieter Levels Style](00-getting-started.md#path-5-pieter-levels-style-2-3-hours) |

## Knowledge Base Stats

- **Total Content**: ~9,500+ lines across 9 documents
- **Code Examples**: 160+ production-ready scripts
- **Real-world Examples**: 13 detailed setups
- **Learning Paths**: 5 structured tutorials
- **Reading Time**: ~7 hours for complete knowledge base

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for:

- **Semantic commit conventions** - How to write clear, consistent commits
- **Changesets workflow** - Automated versioning and changelog generation
- **Pull request guidelines** - Best practices for PRs
- **Documentation standards** - Style guide for adding content

### Quick Contribution Flow

```bash
# 1. Fork and clone
git clone https://github.com/yourusername/continuously-running-agents.git

# 2. Create feature branch
git checkout -b feat/your-feature

# 3. Make changes and create changeset
bun changeset
# Select: minor/patch/major
# Summary: "clear description of your changes"

# 4. Commit using semantic format
git commit -m "feat: your feature description"

# 5. Push and create PR
git push origin feat/your-feature
```

### Automated Release Process

When your PR is merged:
1. GitHub Actions detects changeset
2. Creates "Version Packages" PR automatically
3. When merged, updates `CHANGELOG.md` and creates GitHub release
4. No manual version management needed!

### Commit Format

We follow semantic commits with specific rules:

- **Lowercase** (except proper nouns, titles, acronyms)
- **Present tense** (imperative mood)
- **No redundant verbs** (e.g., "feat: user auth" not "feat: add user auth")

See [CONTRIBUTING.md](CONTRIBUTING.md) for complete guidelines.

## License

MIT License - See LICENSE file for details

---

**Built with**: Claude Code (recursively!)
**Last Updated**: October 20, 2025
Test owner bypass - Mon Oct 20 12:14:35 PDT 2025
