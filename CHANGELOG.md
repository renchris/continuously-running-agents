# continuously-running-agents

## 2.1.0

### Minor Changes

- [`1205413`](https://github.com/renchris/continuously-running-agents/commit/120541382da7e79674d1abd773aa41c89a3c048a) Thanks [@renchris](https://github.com/renchris)! - Complete Hetzner Cloud deployment guide with real-world validation

  This release adds comprehensive documentation and automation for deploying Claude Code agents on Hetzner Cloud infrastructure, validated through actual CPX21 deployment in Hillsboro, OR.

  **New Documentation:**

  - **IMPLEMENTATION.md**: Complete deployment guide with real-world insights, tmux-based Max Plan authentication for headless servers, actual resource usage (800MB RAM, <5% CPU), and measured setup timeline (25-30 minutes)
  - **11-hetzner-instance-types.md**: Complete CPX/CCX/CX series specifications with US vs EU pricing
  - **12-provider-comparison.md**: Data-driven OVHCloud vs Hetzner analysis showing CPX21 saves $37.92/year
  - **13-latency-test-guide.md**: $2 empirical testing methodology for EU vs US location decision
  - **10-location-latency-analysis.md**: Technical analysis proving location doesn't matter for API-bound agents
  - **09-scaling-metrics.md**: Resource consumption patterns and scaling decision matrices
  - **TROUBLESHOOTING.md**: Comprehensive solutions for common deployment issues

  **New Automation:**

  - Server setup scripts (01-server-setup.sh, 02-install-claude.sh) for Ubuntu 24.04
  - Monitoring suite (resource-stats.sh, dashboard.sh, analyze-usage.sh)
  - Multi-agent coordination system (agent-coordination.sh, spawn-agents.sh)
  - Production configurations (tmux, systemd service)

  **Key Findings:**

  - Hetzner CPX21 optimal at $119.88/year (vs $157.80 OVHCloud D2-4)
  - Location proximity irrelevant: API latency (200-2000ms) >> network latency (30ms)
  - CPX21 correctly sized for 3-5 agents: 3.2GB free RAM, <5% CPU idle
  - Max Plan authentication works on headless servers via tmux workaround

  All tested on Hetzner Cloud CPX21, Ubuntu 24.04.1 LTS, Node.js 20.19.5, Claude Code 2.0.22.

## 2.0.0

### Major Changes

- [`1fb79c9`](https://github.com/renchris/continuously-running-agents/commit/1fb79c94f788ff389ebc1c4999d7f2057d74f631) Thanks [@renchris](https://github.com/renchris)! - comprehensive knowledge base for continuously running AI agents

  Initial release of the knowledge base including:

  - 9 comprehensive markdown documents (6,699 lines)
  - 5 structured learning paths from beginner to enterprise
  - 150+ production-ready scripts and examples
  - 13 detailed real-world setups including Claude Squad, Agent Farm, Docker, and more
  - Complete guides covering infrastructure, TMUX, remote access, configuration, cost optimization, security
  - Tool comparison matrix and recommendation guide
  - Semantic commit conventions and changesets workflow
  - All cross-references verified and markdownlint compliant

  Based on research from @levelsio and @ericzakariasson, compiled March-October 2025.

### Minor Changes

- [`3837673`](https://github.com/renchris/continuously-running-agents/commit/3837673d634c2061c6b5a3c1f3af804aa67b5b9d) Thanks [@renchris](https://github.com/renchris)! - LLM provider setup with OVHCloud integration

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

### Patch Changes

- [`1aba5af`](https://github.com/renchris/continuously-running-agents/commit/1aba5af2ed0d0e92c5463df91afd7e514eda9b09) Thanks [@renchris](https://github.com/renchris)! - Changeset workflow with GitHub Actions integration

  Implements automated versioning and changelog generation following changesets best practices:

  - **Automated releases**: GitHub Actions creates "Version Packages" PR automatically
  - **PR validation**: All PRs must include changeset (enforced by CI)
  - **Rich changelogs**: Uses @changesets/changelog-github for links to PRs/issues
  - **Zero-touch versioning**: No manual version bumps needed
  - **Enhanced documentation**: Comprehensive changeset workflow in CONTRIBUTING.md

## 1.0.0

### Major Changes

- Initial release of Continuously Running AI Agents knowledge base
- Comprehensive documentation across 9 guides (~9,500+ lines)
- 160+ production-ready code examples
- 5 structured learning paths
- 13 real-world setup examples

### Features

- **Getting Started Guide**: 5 learning paths from beginner to production
- **Infrastructure Setup**: VPS providers (Hetzner, DigitalOcean, OVHCloud)
- **TMUX Coordination**: Multi-agent orchestration protocol for 20-50+ agents
- **Remote Access**: Mobile coding with Tailscale, Mosh, web terminals
- **Claude Configuration**: Autonomous operation patterns, Pieter Levels' /workers/ pattern
- **Cost Optimization**: Pricing strategies, prompt caching (90% savings)
- **Security**: Server hardening, isolation, monitoring checklists
- **Examples**: Claude Squad, Agent Farm, Docker isolation, self-healing systems
- **LLM Provider Setup**: API key architecture, subscription tiers, OVHCloud integration

### Documentation

- 00-getting-started.md: Structured learning paths
- 01-infrastructure.md: Cloud VPS setup
- 02-tmux-setup.md: Session persistence and coordination
- 03-remote-access.md: Mobile and remote workflows
- 04-claude-configuration.md: Autonomous agent configuration
- 05-cost-optimization.md: Cost management strategies
- 06-security.md: Security best practices
- 07-examples.md: Real-world implementations
- 08-llm-provider-setup.md: API and subscription management

### Contributors

- Research compiled from @levelsio, @ericzakariasson, and community (March-October 2025)
- Built with Claude Code
