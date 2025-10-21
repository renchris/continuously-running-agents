---
"continuously-running-agents": minor
---

feat: comprehensive agent startup failure prevention and detection

**New Documentation**:
- **AGENT-STARTUP-FAILURES.md** (411 lines): Complete troubleshooting guide
  - Quick diagnosis decision tree
  - 4 common failure modes with real examples and fixes
  - Pre-flight validation checklist  
  - Debugging commands
  - Case study: October 21, 2025 mass failures (agents 6/7/11/12)
  - Prevention strategies for dev and production

**Script Improvements**:
- **start-agent-yolo.sh**:
  - Pre-flight authentication checks (Claude binary, auth test, API connectivity)
  - System resource validation (free RAM warning)
  - Startup health check (warns if log <10 lines or <500 bytes after 10s)
  - Better error messages with fix commands
  
- **agent-completion-watcher.sh**:
  - Auto-detect startup failures (log <500 bytes after 30+ seconds)
  - Mark failed agents as "error" status (prevents ghost "running" state)
  - Automatic completion timestamps for failed agents

**Testing**:
- **test-agent-startup.sh**: Automated validation suite (6 tests)
  - Validates all improvements exist and work correctly

**Impact**:
- **Prevents**: Silent authentication failures (90%+ of Oct 21 failure mode)
- **Detects**: Startup failures within 10-60 seconds (vs hours of ghost agents)
- **Documents**: Complete troubleshooting guide for future failures

Based on investigation of October 21, 2025 agent failures (authentication issues after 5th agent spawn).
