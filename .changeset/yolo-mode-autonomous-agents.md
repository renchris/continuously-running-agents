---
"continuously-running-agents": minor
---

feat: YOLO mode autonomous agents with resource limits and monitoring

Added comprehensive YOLO mode (--dangerously-skip-permissions) support for fully autonomous Claude Code agents:

**Scripts:**
- `scripts/start-agent-yolo.sh`: Autonomous agent launcher with resource limits (2GB RAM, 200 processes, 8h timeout)
- `scripts/monitor-agents-yolo.sh`: Enhanced monitoring with safety alerts (CPU/RAM, stale agents, overtime)
- `scripts/auto-approve-agents.sh`: Automated permission approval for manual-mode agents
- `scripts/monitor-agents.sh`: Non-intrusive monitoring dashboard
- `scripts/systemd/claude-agent@.service`: Optional systemd service with kernel-level limits

**Documentation:**
- `YOLO-MODE-GUIDE.md`: Comprehensive 400+ line guide covering security analysis, usage examples, troubleshooting, and best practices

**Security:**
- Risk level: LOW (isolated server, limited GitHub permissions, branch protection enforced)
- Machine user has write-only access (no admin), blocked from main branch pushes
- Resource limits prevent runaway processes

**Testing:**
- ✅ Successfully validated autonomous task completion
- ✅ 4-second response time for simple tasks
- ✅ Clean exit with proper logging
