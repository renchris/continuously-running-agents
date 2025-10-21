# YOLO Mode Guide - Autonomous Claude Code Agents

**YOLO Mode** = "You Only Live Once" mode = Fully autonomous execution with `--dangerously-skip-permissions`

This guide covers how to run Claude Code agents in fully autonomous mode without permission prompts.

---

## 🎯 Quick Start

### Start a YOLO Agent

```bash
# On Hetzner server
bash ~/scripts/start-agent-yolo.sh 1 "Your task description here"
```

### Monitor Agents

```bash
# Enhanced YOLO monitoring (local machine)
bash scripts/monitor-agents-yolo.sh

# Continuous monitoring
bash scripts/monitor-agents-yolo.sh --watch

# Show only alerts
bash scripts/monitor-agents-yolo.sh --alerts
```

---

## ✅ What is YOLO Mode?

**YOLO Mode** uses the `--dangerously-skip-permissions` flag to bypass ALL permission prompts:

- ✅ No file write confirmations
- ✅ No bash command approvals
- ✅ No git operation prompts
- ✅ Fully autonomous execution
- ✅ Agent runs until task complete or timeout

**When to use:**
- Trusted, isolated environments
- Production automated workflows
- Long-running unattended tasks
- CI/CD pipelines
- Development servers (like our Hetzner setup)

**When NOT to use:**
- Local development machine
- Production codebases with sensitive data
- Untrusted code repositories
- Shared developer machines

---

## 🔒 Security Analysis

### Our Security Posture

**Environment**: Hetzner CPX21 server (`claude-agent@5.78.152.238`)

**Machine User**: @renchris-agent

**Permissions**:
- ✅ `write` access to 1 repository only
- ❌ **NO** admin access
- ❌ **NO** access to other 81 repos
- ❌ **CANNOT** push to main branch (branch protection)
- ❌ **CANNOT** delete repository
- ❌ **CANNOT** modify repository settings

**Isolation**:
- Dedicated server (not local machine)
- Separate user account (`claude-agent`)
- No production workloads on server
- Easy to rebuild ($10/month server)

### Risk Assessment

| Risk | Level | Mitigation |
|------|-------|------------|
| File system access | LOW | Limited to `/home/claude-agent/projects/` |
| Git push to main | **NONE** | Branch protection blocks |
| Repository deletion | **NONE** | No admin permissions |
| Secret exposure | LOW | No secrets in repo |
| Arbitrary bash commands | MEDIUM | Isolated server, resource limits |
| Resource exhaustion | LOW | ulimit + optional systemd limits |
| Network abuse | MEDIUM | Could make API calls, download files |

**Overall Risk**: **LOW** for our use case

---

##  Configuration

### Resource Limits (Default)

```bash
MAX_CPU_PERCENT=80        # Max 80% of one CPU core
MAX_MEMORY_MB=2048        # Max 2GB RAM per agent
MAX_PROCESSES=200         # Max 200 processes
MAX_DISK_MB=5120          # Max 5GB disk writes
MAX_RUNTIME_HOURS=8       # Auto-kill after 8 hours
```

### Customizing Limits

Edit `scripts/start-agent-yolo.sh`:

```bash
# Environment variables override defaults
export MAX_RUNTIME_HOURS=4
export MAX_MEMORY_MB=3072  # 3GB

bash ~/scripts/start-agent-yolo.sh 1 "Task description"
```

### Advanced: Systemd Service (Optional)

For production deployment with kernel-level resource enforcement:

```bash
# Copy service file
sudo cp scripts/systemd/claude-agent@.service /etc/systemd/system/
sudo systemctl daemon-reload

# Start agent 1
sudo systemctl start claude-agent@1

# Enable auto-start on boot
sudo systemctl enable claude-agent@1

# View logs
sudo journalctl -u claude-agent@1 -f
```

See `scripts/systemd/README.md` for full documentation.

---

## 📊 Monitoring

### Non-Intrusive Monitoring

The enhanced monitoring script tracks:

- ✅ Runtime for each agent
- ✅ Last activity timestamp
- ✅ CPU and memory usage per agent
- ✅ System resource utilization
- ✅ Work output (PRs, commits)
- ✅ Safety alerts (high CPU/RAM, stale agents, etc.)

### Safety Alert Thresholds

```bash
MAX_CPU_PERCENT=75           # Alert if >75% CPU
MAX_MEMORY_PERCENT=85        # Alert if >85% memory
MAX_AGENT_RUNTIME_HOURS=8    # Alert if running >8 hours
MIN_ACTIVITY_MINUTES=30      # Alert if idle >30 minutes
```

### Viewing Agent Logs

```bash
# On Hetzner server
tail -f ~/agents/logs/agent-1-*.log

# Or via SSH (from local machine)
ssh -i ~/.ssh/hetzner_claude_agent claude-agent@5.78.152.238 \
  "tail -f ~/agents/logs/agent-1-*.log"
```

---

## 🚀 Usage Examples

### Example 1: Simple Task

```bash
bash ~/scripts/start-agent-yolo.sh 1 "Calculate 5 + 7"

# Output: Agent completes in ~4 seconds
# Log shows: "12"
```

### Example 2: Documentation Update

```bash
bash ~/scripts/start-agent-yolo.sh 2 \
  "Read IMPLEMENTATION.md and add a troubleshooting section for YOLO mode"

# Agent autonomously:
# 1. Reads file
# 2. Creates new section
# 3. Commits changes
# 4. Creates pull request
# No prompts required!
```

### Example 3: Multiple Agents

```bash
# Start 5 agents in parallel (on Hetzner server)
for i in {1..5}; do
    bash ~/scripts/start-agent-yolo.sh $i \
        "Work on issue #$i from GitHub issues"
done

# Monitor them all
bash ~/scripts/monitor-agents-yolo.sh --watch
```

### Example 4: Long-Running Research Task

```bash
# Custom 12-hour timeout for deep research
MAX_RUNTIME_HOURS=12 bash ~/scripts/start-agent-yolo.sh 1 \
  "Research best practices for Claude Code agent orchestration and create comprehensive guide"
```

---

## 🛡️ Safety Features

### 1. Automatic Timeout

Every agent auto-terminates after MAX_RUNTIME_HOURS (default: 8 hours):

```bash
# Agent log shows:
Agent 1 completed at Tue Oct 21 10:22:57 AM UTC 2025
Exit code: 124  # 124 = timeout signal
```

### 2. Resource Limits

Enforced via `ulimit`:
- Process count limit
- File size limit
- Open file descriptors limit

Optional systemd limits (kernel-level):
- CPU quota
- Memory hard limit
- Disk I/O limits

### 3. Comprehensive Logging

Every command and output logged to:
```
~/agents/logs/agent-{NUM}-{TIMESTAMP}.log
```

### 4. GitHub Branch Protection

Even in YOLO mode, the machine user cannot:
- Push to main branch
- Delete repository
- Modify settings

All work goes through pull requests.

---

## 🔧 Troubleshooting

### Agent Won't Start

```bash
# Check if session already exists
tmux list-sessions | grep prod-agent

# Kill if needed
tmux kill-session -t prod-agent-1

# Check logs
tail -50 ~/agents/logs/agent-1-*.log
```

### Out of Memory Errors

The script no longer uses `ulimit -v` for memory due to Claude Code's WebAssembly requirements. If you need hard memory limits, use systemd:

```bash
# Edit service file
sudo vim /etc/systemd/system/claude-agent@.service

# Change MemoryMax
[Service]
MemoryMax=3G  # Instead of 800M

sudo systemctl daemon-reload
sudo systemctl restart claude-agent@1
```

### Agent Appears Stuck

```bash
# Check if actually running
ssh -i ~/.ssh/hetzner_claude_agent claude-agent@5.78.152.238 \
  "ps aux | grep claude | grep -v grep"

# Attach to session to see what's happening
ssh -i ~/.ssh/hetzner_claude_agent claude-agent@5.78.152.238 \
  -t "tmux attach -t prod-agent-1"

# Press Ctrl+B then D to detach
```

### High CPU Usage

```bash
# Check monitoring dashboard
bash scripts/monitor-agents-yolo.sh --alerts

# If sustained high CPU (>80%):
# Option 1: Wait for task to complete
# Option 2: Kill and restart with different task
tmux kill-session -t prod-agent-1
```

---

## 📝 Best Practices

### 1. Task Design

**Good tasks**:
- ✅ Clear, specific objectives
- ✅ Well-defined completion criteria
- ✅ Limited scope
- ✅ Include "create PR when done"

**Bad tasks**:
- ❌ Open-ended ("improve everything")
- ❌ No completion signal ("keep monitoring")
- ❌ Requires external input

### 2. Monitoring Cadence

```bash
# During development: Watch mode
bash scripts/monitor-agents-yolo.sh --watch

# Production: Scheduled checks
# Add to crontab (every 15 minutes):
*/15 * * * * bash ~/scripts/monitor-agents-yolo.sh --alerts >> ~/agents/monitoring.log
```

### 3. Agent Lifecycle

```
START → WORK → COMPLETE → EXIT
  ↓                         ↑
TIMEOUT (8h) ---------------┘
```

- Agents should complete within 8 hours
- If task needs longer, increase MAX_RUNTIME_HOURS
- Clean up completed sessions regularly

### 4. Resource Management

On Hetzner CPX21 (4GB RAM):
- **Safe**: 2-3 concurrent agents
- **Optimal**: 1-2 agents
- **Max**: 5 agents (if tasks are lightweight)

---

## 🔄 Comparison: Manual vs YOLO Mode

| Aspect | Manual Approval | YOLO Mode |
|--------|----------------|-----------|
| Permission prompts | Every operation | None |
| Supervision required | Constant | None |
| Suitable for | Interactive dev | Automation |
| Speed | Slow (wait for approval) | Fast (autonomous) |
| Safety | High (human review) | Medium (automated limits) |
| Best for | Local machine | Isolated server |

---

## 📚 Related Documentation

- `scripts/start-agent-yolo.sh` - Main startup script
- `scripts/monitor-agents-yolo.sh` - Enhanced monitoring
- `scripts/systemd/README.md` - Systemd service setup
- `scripts/monitor-agents.sh` - Basic monitoring (non-YOLO)
- `MACHINE-USER-STATUS.md` - GitHub permissions details
- `SECURITY-MODEL.md` - Branch protection setup

---

## ⚙️ Technical Details

### Command Line Flag

```bash
claude --dangerously-skip-permissions -p "Task description"
```

### Alternative: Permission Mode

```bash
claude --permission-mode bypassPermissions -p "Task"
```

Both are equivalent. The script uses `--dangerously-skip-permissions` for clarity.

### Why "Dangerously"?

Anthropic named it "dangerously" because it:
1. Bypasses ALL safety checks
2. Could execute destructive commands
3. Could delete files or repositories
4. Could make API calls or network requests
5. Should only be used in trusted environments

**Our mitigation**: Isolated server + limited GitHub permissions + resource limits

---

## 🎓 Key Takeaways

1. ✅ **YOLO mode works** - Successfully tested with autonomous task completion
2. ✅ **Security is acceptable** - Machine user has limited permissions
3. ✅ **Resource limits enforced** - Process, file size, runtime limits
4. ✅ **Monitoring in place** - Enhanced dashboard with safety alerts
5. ✅ **Production ready** - Can deploy 5+ autonomous agents

**Bottom line**: YOLO mode is safe for our use case (isolated server + limited GitHub permissions).

---

**Last Updated**: October 21, 2025
**Tested On**: Hetzner CPX21, Claude Code v2.0.22, Ubuntu 24.04
**Status**: ✅ Production Ready
