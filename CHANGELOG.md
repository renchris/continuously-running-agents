# continuously-running-agents

## 2.3.0

### Minor Changes

- [`a585ec7`](https://github.com/renchris/continuously-running-agents/commit/a585ec7f2cdea8a7625130400921068425364df0) Thanks [@renchris](https://github.com/renchris)! - Monitoring system for resume across conversation boundaries

  **New Documentation**:

  - `docs/MONITORING-SYSTEM-GUIDE.md`: Complete guide for monitoring agents across conversation boundaries
  - `docs/validation/PRODUCTION-VALIDATION-REPORT.md`: v2.2.0 production validation with real metrics

  **New Scripts**:

  - `scripts/monitoring/agent-completion-watcher.sh`: Server-side monitoring daemon that detects agent completion
  - `scripts/monitoring/resume-monitoring.sh`: Resume helper that generates formatted reports for new conversations

  **Features**:

  - Persistent JSON status files survive across conversations
  - Detects completion via multiple signals (tmux exit, files created, PRs, logs)
  - Tracks resource usage (CPU, RAM) and duration
  - Human-readable reports for pasting into new Claude Code sessions
  - Low overhead monitoring (<0.1% CPU, 10MB RAM)

  This solves the conversation boundary problem: agents can run for hours, and you can resume monitoring in a new conversation by simply pasting the status report.

### Patch Changes

- [#9](https://github.com/renchris/continuously-running-agents/pull/9) [`8855669`](https://github.com/renchris/continuously-running-agents/commit/8855669cae2383a7a32965d9b506b49bb8568731) Thanks [@renchris-agent](https://github.com/renchris-agent)! - docs(wildcard): comprehensive validation report and example configuration

  Validates and documents the wildcard permissions feature advertised in v2.2.0 CHANGELOG. Identifies critical documentation gap: the promised "Complete reference guide for `.claude/settings.local.json` wildcard patterns" with "145+ organized patterns" does not exist.

  **New Files**:

  - `WILDCARD-VALIDATION-REPORT.md`: Comprehensive 600+ line validation report

    - Tests 10 diverse wildcard patterns (basic globs, brace expansion, character classes, negation)
    - Documents expected behavior for Read/Write/Bash operations
    - Identifies 8 critical gaps including undocumented pattern precedence rules
    - Provides performance impact analysis and security recommendations
    - Includes production-ready example with 25 patterns

  - `.claude/settings.local.json.example`: Production-ready configuration template
    - 60+ well-documented wildcard patterns organized by category
    - Security-focused deny patterns for secrets, dependencies, system directories
    - Extensive inline documentation explaining each pattern
    - Experimental patterns section for untested features

  **Key Findings**:

  - ⚠️ CHANGELOG claims documentation that doesn't exist (BLOCKER)
  - ⚠️ Pattern precedence rules undocumented (CRITICAL)
  - ⚠️ Brace expansion, character classes, absolute paths untested
  - ⚠️ "95%+ permission prompt reduction" claim unverified
  - ⚠️ Security implications of broad patterns undocumented

  **Recommendations**:

  1. Create comprehensive pattern reference guide (P0)
  2. Document pattern precedence and evaluation rules (P0)
  3. Run empirical tests with actual Claude Code agent (P1)
  4. Benchmark performance impact with various pattern counts (P1)
  5. Add security linting for settings.local.json (P2)

  Addresses the missing deliverables from v2.2.0 wildcard permissions feature.

## 2.2.0

### Minor Changes

- **Unified Agent Knowledge System (AGENTS.md standard)**: Multi-platform agent knowledge file that works with Claude Code, Cursor, Cline, and Windsurf. Symlinked as CLAUDE.md, .cursorrules, .clinerules/rules.md, and .windsurf/rules.md for universal compatibility.

- **Commit Message Convention Enforcement**: Automated validation via git hooks with strict semantic commit format (type/scope/subject). Includes helpful error messages and auto-installation script.

- **YOLO Mode Autonomous Agents**: Complete autonomous agent deployment with `--dangerously-skip-permissions` flag, resource limits (CPU, RAM, disk, runtime), and comprehensive monitoring dashboard.

- **Wildcard Permissions Pattern**: Complete reference guide for `.claude/settings.local.json` wildcard patterns. Eliminates 95%+ permission prompts through 145+ organized patterns (92% file size reduction from hardcoded entries). Includes production-ready example configuration.

### Patch Changes

- **Machine User Setup Quick Reference**: Concise cheatsheet for setting up GitHub machine users with proper security isolation. Commands + one-line explanations format.

- **Production Cost Analysis**: Real deployment costs from October 20, 2025 showing actual resource usage (280MB/agent, 0.5% CPU), current cost €1.58/agent, and immediate optimization to €0.50/agent with 8 agents/server.

- **GitHub Authentication Automation**: Scripts for automated GitHub CLI and SSH key setup for machine users on remote servers.

- **Workflow Documentation**: Setup guides for release workflows, troubleshooting common permission issues, and Max Plan authentication via tmux.

- **Settings Wildcard Patterns Documentation**: Production-ready example configuration with safety deny list for destructive operations.

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
