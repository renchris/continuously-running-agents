---
"continuously-running-agents": minor
---

Complete Hetzner Cloud deployment guide with real-world validation

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
