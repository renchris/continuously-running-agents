# Monitoring System Guide: Resume Monitoring Across Conversations

**Problem Solved**: Claude Code only exists during active conversations. How do you monitor long-running agents that complete after the conversation ends?

**Solution**: Server-side monitoring that persists status to files, which can be read in new conversations.

---

## System Architecture

### **Layer 1: Continuous Monitoring** (Server-Side)

**Script**: `scripts/monitoring/agent-completion-watcher.sh`

**What it does**:
- Runs continuously in tmux session `agent-watcher`
- Checks every 60 seconds for agent status changes
- Detects completion via multiple signals:
  - tmux session exit
  - Expected files created
  - PRs created via GitHub API
  - Log file completion messages
- Tracks resource usage (CPU, RAM) and duration
- Writes JSON status files that persist indefinitely

**Status Files**:
```
~/agents/status/
├── agent-1-status.json    # Detailed status for agent 1
├── agent-2-status.json    # Detailed status for agent 2
├── agent-3-status.json    # Detailed status for agent 3
└── LATEST-RUN.json        # Summary of all agents
```

**Example agent-1-status.json**:
```json
{
  "agent_number": 1,
  "session": "prod-agent-1",
  "status": "completed",
  "started": "2025-10-21T17:40:58Z",
  "completed": "2025-10-21T17:43:15Z",
  "duration_seconds": 137,
  "pr_created": ["#8"],
  "files_created": ["DOCUMENTATION-GAPS.md"],
  "exit_code": 0,
  "errors": [],
  "resources": {
    "cpu_percent": 6.2,
    "ram_mb": 215,
    "peak_cpu": 8.5,
    "peak_ram_mb": 235
  }
}
```

---

### **Layer 2: Resume Helper** (For New Conversations)

**Script**: `scripts/resume-monitoring.sh`

**What it does**:
- Reads all agent status JSON files
- Generates formatted, human-readable report
- Shows completion status, duration, resources, PRs, files
- Suggests next actions based on current state
- Output is designed to be pasted into Claude Code

**Usage**:
```bash
# On the server
ssh -i ~/.ssh/hetzner_claude_agent claude-agent@5.78.152.238 "bash ~/scripts/resume-monitoring.sh"

# Copy the output
# Paste into new Claude Code conversation
```

**Example Output**:
```
╔════════════════════════════════════════════════════════════════╗
║          Agent Monitoring Status Report                        ║
╠════════════════════════════════════════════════════════════════╣

Last Updated: 2025-10-21T17:50:00Z
Total Agents: 3

Status Summary:
  ✅ 2 completed
  ❌ 1 with errors

╠════════════════════════════════════════════════════════════════╣
║ Agent Details                                                  ║
╠════════════════════════════════════════════════════════════════╣

Agent 1: ✅ COMPLETED
  Duration:  3 minutes (137s)
  Peak:      8.5% CPU, 235 MB RAM
  Files:     DOCUMENTATION-GAPS.md

Agent 2: ✅ COMPLETED
  Duration:  4 minutes (240s)
  Peak:      7.2% CPU, 220 MB RAM
  PRs:       #8
  Files:     scripts/monitoring/production-dashboard.sh

Agent 3: ✅ COMPLETED
  Duration:  9 minutes (540s)
  Peak:      9.1% CPU, 245 MB RAM
  PRs:       #9
  Files:     WILDCARD-VALIDATION-REPORT.md, .claude/settings.local.json.example

╠════════════════════════════════════════════════════════════════╣
║ Suggested Next Actions                                        ║
╠════════════════════════════════════════════════════════════════╣

✓ Review and merge completed agent PRs
  cd ~/projects/continuously-running-agents && gh pr list

╠════════════════════════════════════════════════════════════════╣
║ System Resources                                              ║
╠════════════════════════════════════════════════════════════════╣

  RAM:  485Mi / 3.7Gi (12.7%)
  Disk: 2.4G / 75G (4%)

✓ Capacity for approximately 13 more agents

╚════════════════════════════════════════════════════════════════╝
```

---

## Workflow: Complete Cycle

### **1. Deploy Agents** (Any Conversation)

```bash
# Deploy 3 agents with tasks
bash ~/scripts/start-agent-yolo.sh 1 "Create DOCUMENTATION-GAPS.md..."
bash ~/scripts/start-agent-yolo.sh 2 "Create monitoring dashboard..."
bash ~/scripts/start-agent-yolo.sh 3 "Validate wildcard patterns..."
```

### **2. Monitoring Starts Automatically**

The `agent-watcher` tmux session:
- Detects the 3 new sessions
- Initializes status files for each
- Updates status every 60 seconds
- Tracks resources, duration, completion

### **3. Walk Away** (Conversation Ends)

- Agents continue running autonomously
- Watcher continues monitoring
- Status files keep updating
- You can close your terminal, laptop, etc.

### **4. Come Back Later** (New Conversation)

```bash
# Start new SSH session
ssh -i ~/.ssh/hetzner_claude_agent claude-agent@5.78.152.238

# Run resume script
bash ~/scripts/resume-monitoring.sh

# Copy entire output
# Paste into new Claude Code conversation
```

### **5. Claude Sees What Happened**

When you paste the status report into a new conversation:
- I can immediately see all 3 agents completed
- I can see PRs #8 and #9 were created
- I can see what files were created
- I can suggest: "Review PR #8 and #9, then merge them"

### **6. Take Action**

Based on the status, I can:
- Review and merge PRs
- Investigate errors in failed agents
- Deploy new agents for next phase
- Scale up to more agents

---

## Setup (One-Time)

### **Deploy the Monitoring System**

```bash
# 1. Copy scripts to server (already done if you're reading this)
scp scripts/agent-completion-watcher.sh claude-agent@server:~/scripts/monitoring/
scp scripts/resume-monitoring.sh claude-agent@server:~/scripts/

# 2. Make executable
ssh claude-agent@server "chmod +x ~/scripts/monitoring/agent-completion-watcher.sh"
ssh claude-agent@server "chmod +x ~/scripts/resume-monitoring.sh"

# 3. Create status directory
ssh claude-agent@server "mkdir -p ~/agents/status"

# 4. Start watcher in tmux (runs forever)
ssh claude-agent@server 'tmux new-session -d -s agent-watcher "bash ~/scripts/monitoring/agent-completion-watcher.sh"'

# 5. Verify it's running
ssh claude-agent@server "tmux list-sessions | grep agent-watcher"
```

**Status**: ✅ Already deployed on Hetzner server

---

## How To Use

### **Quick Check** (Any Time)

```bash
# Check agent status
ssh server "bash ~/scripts/resume-monitoring.sh"
```

### **Machine-Readable Format**

```bash
# Get JSON for automation
ssh server "cat ~/agents/status/LATEST-RUN.json | jq"

# Get specific agent
ssh server "cat ~/agents/status/agent-1-status.json | jq"
```

### **Check Watcher Health**

```bash
# View watcher logs (last 20 lines)
ssh server "tmux capture-pane -t agent-watcher -p | tail -20"

# Attach to watcher session
ssh server -t "tmux attach -t agent-watcher"
```

### **Restart Watcher** (If Needed)

```bash
# Kill old session
ssh server "tmux kill-session -t agent-watcher"

# Start new one
ssh server 'tmux new-session -d -s agent-watcher "bash ~/scripts/monitoring/agent-completion-watcher.sh"'
```

---

## Real-World Example: v2.2.0 Validation

### **What Happened**:

1. **17:40 UTC** - Deployed 3 agents in one conversation
2. **17:43 UTC** - Agent 1 completed (3 min)
3. **17:44 UTC** - Agent 2 completed, created PR #8 (4 min)
4. **17:49 UTC** - Agent 3 completed, created PR #9 (9 min)
5. **18:00 UTC** - Started new conversation, ran `resume-monitoring.sh`
6. **Result**: Claude immediately saw all completions and suggested merging PRs

### **Without This System**:
- Would have to manually check tmux sessions
- Would have to manually check GitHub for PRs
- Would have to parse log files
- Would lose context across conversations
- Would waste time figuring out what happened

### **With This System**:
- One command: `bash ~/scripts/resume-monitoring.sh`
- Paste output to Claude
- Instant context, immediate action

---

## Advanced Options

### **GitHub PR Notifications** (Future Enhancement)

Create `scripts/notifications/github-pr-notifier.sh`:

```bash
# Polls for new PRs every 60s
# Posts comment on PR with agent summary
# Uses existing GitHub notification system
```

### **Discord/Telegram Webhooks** (Future)

```bash
# POST to webhook when agents complete
# Instant mobile notifications
```

### **Custom Dashboard** (Future)

```bash
# Web interface showing real-time agent status
# Accessible from phone/tablet
```

---

## Troubleshooting

### **Watcher Not Detecting Agents**

```bash
# Check if watcher is running
ssh server "tmux list-sessions | grep agent-watcher"

# Check watcher logs
ssh server "tmux capture-pane -t agent-watcher -p"

# Verify agent sessions use correct naming (prod-agent-N)
ssh server "tmux list-sessions | grep prod-agent"
```

### **Status Files Not Updating**

```bash
# Check file permissions
ssh server "ls -la ~/agents/status/"

# Check watcher errors
ssh server "tmux capture-pane -t agent-watcher -p | grep -i error"

# Restart watcher
ssh server "tmux kill-session -t agent-watcher && tmux new-session -d -s agent-watcher 'bash ~/scripts/monitoring/agent-completion-watcher.sh'"
```

### **Resume Script Shows Old Data**

```bash
# Clear old status files
ssh server "rm ~/agents/status/agent-*-status.json"

# LATEST-RUN.json will update on next watcher cycle (60s)
```

---

## Files Created

### **Server-Side Scripts**:
- `~/scripts/monitoring/agent-completion-watcher.sh` (300 lines)
- `~/scripts/resume-monitoring.sh` (200 lines)

### **Status Files** (Auto-Generated):
- `~/agents/status/agent-N-status.json` (per agent)
- `~/agents/status/LATEST-RUN.json` (summary)

### **Sessions**:
- `agent-watcher` - Continuous monitoring (runs forever)
- `prod-agent-N` - Individual agents (temporary)

---

## Summary

**Problem**: How do I monitor agents across conversation boundaries?

**Solution**:
1. Server-side watcher writes status to JSON files
2. Resume script reads files and formats for Claude
3. Paste output into new conversation
4. Claude has full context and can act immediately

**Benefits**:
- ✅ Works across hours, days, weeks
- ✅ No manual checking required
- ✅ Persistent status across conversations
- ✅ Immediate context restoration
- ✅ Automated monitoring with minimal overhead

**Status**: ✅ **Deployed and Validated** on Hetzner CPX21 server

---

**Last Updated**: 2025-10-21
**System**: Hetzner CPX21 (5.78.152.238)
**Version**: 1.0
