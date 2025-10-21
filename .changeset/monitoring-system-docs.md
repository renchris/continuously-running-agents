---
"continuously-running-agents": minor
---

Monitoring system for resume across conversation boundaries

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
