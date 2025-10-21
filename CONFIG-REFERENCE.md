# Configuration Reference - Claude Code Autonomous Agents

Complete reference for all configuration options used in continuously-running-agents deployments.

---

## Table of Contents

1. [Claude Code Configuration (.claude/config.json)](#1-claude-code-configuration)
2. [Claude Code Settings (.claude/settings.json)](#2-claude-code-settings)
3. [Environment Variables](#3-environment-variables)
4. [Resource Limits (ulimit)](#4-resource-limits-ulimit)
5. [Systemd Service Configuration](#5-systemd-service-configuration)
6. [Tmux Configuration](#6-tmux-configuration)
7. [Quick Reference Tables](#7-quick-reference-tables)

---

## 1. Claude Code Configuration

### 1.1 .claude/config.json

Configuration file for Claude Code project-level settings.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `model` | string | `"claude-sonnet-4-5"` | AI model to use for agents |
| `maxTurns` | number | `100` | Maximum conversation turns before auto-stop |
| `temperature` | number | `0.7` | Model creativity (0.0-1.0, higher = more creative) |
| `checkpointingEnabled` | boolean | `true` | Enable automatic checkpointing |
| `allowedTools` | array | `[]` | Tools agent can use without approval |
| `requireApprovalFor` | array | `[]` | Commands requiring explicit approval |
| `restrictedCommands` | object | `{}` | Blocked bash commands |
| `autoCommit` | boolean | `false` | Automatically commit changes |
| `requireApprovalForGitPush` | boolean | `true` | Require approval before git push |

### 1.2 Example: Recommended Configuration

```json
{
  "model": "claude-sonnet-4-5",
  "maxTurns": 100,
  "temperature": 0.7,
  "checkpointingEnabled": true,
  "allowedTools": [
    "read",
    "write",
    "edit",
    "grep",
    "glob"
  ],
  "restrictedCommands": {
    "bash": {
      "blocklist": [
        "rm -rf /",
        ":(){ :|:& };:",
        "dd if=/dev/zero"
      ]
    }
  },
  "autoCommit": false,
  "requireApprovalForGitPush": true
}
```

### 1.3 Example: Cost-Optimized Configuration

```json
{
  "model": "claude-haiku-3-5",
  "maxTurns": 50,
  "temperature": 0.5,
  "allowedTools": ["read", "grep", "glob"]
}
```

### 1.4 Model Options

| Model | Use Case | Cost | Performance |
|-------|----------|------|-------------|
| `claude-sonnet-4-5` | Best for complex coding tasks | Medium | Best |
| `claude-opus-4` | Critical reasoning tasks | High | Excellent |
| `claude-sonnet-4` | Standard development tasks | Medium | Very Good |
| `claude-haiku-3-5` | Simple/routine tasks | Low | Good |

---

## 2. Claude Code Settings

### 2.1 .claude/settings.json

Project-specific settings for Claude Code behavior and system prompts.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `systemPrompt` | string | `""` | Custom system prompt for project context |
| `hooks` | object | `{}` | Event hooks configuration |

### 2.2 Example: Project System Prompt

```json
{
  "systemPrompt": "You are working on the 'continuously-running-agents' repository.\n\n## Commit Message Conventions\n\nWhen creating commits, follow these strict rules:\n\n1. **Lowercase** - Use lowercase for everything except proper nouns, titles, and acronyms\n2. **No redundant verbs** - Don't repeat what the type already implies:\n   - ❌ `feat: add user authentication` → ✅ `feat: user authentication`\n   - ❌ `fix: adjust login error` → ✅ `fix: login error handling`\n   - ❌ `docs: update README` → ✅ `docs: README improvements`\n3. **Imperative mood** - Write as if giving a command\n4. **No period** at end of subject line\n5. **Max 50 characters** for subject line\n\nSee CONTRIBUTING.md for complete conventions.",
  "hooks": {}
}
```

### 2.3 .claude/settings.local.json (Wildcard Permissions)

Local overrides for permission settings (not checked into git).

| Pattern | Description |
|---------|-------------|
| `**/test/**` | Allow all operations in test directories |
| `**/*.test.js` | Allow operations on test files |
| `**/scripts/**` | Allow operations in scripts directory |

**Example:**

```json
{
  "autoApprove": {
    "write": ["**/test/**", "**/*.md"],
    "bash": ["scripts/**/*.sh"],
    "edit": ["**/*.json", "**/*.md"]
  }
}
```

---

## 3. Environment Variables

### 3.1 Core Claude Code Variables

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `ANTHROPIC_API_KEY` | string | Yes | - | API key for Claude Code |
| `ANTHROPIC_BASE_URL` | string | No | `https://api.anthropic.com` | API endpoint URL |
| `CLAUDE_MODEL` | string | No | `claude-sonnet-4-5` | Default model to use |
| `HOME` | string | Yes | - | User home directory |
| `PATH` | string | Yes | - | Executable search path |

### 3.2 Agent Runtime Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `MAX_RUNTIME_HOURS` | number | `8` | Maximum hours before auto-kill |
| `MAX_CPU_PERCENT` | number | `80` | Maximum CPU usage per agent |
| `MAX_MEMORY_MB` | number | `2048` | Maximum memory per agent (MB) |
| `MAX_PROCESSES` | number | `200` | Maximum processes per agent |
| `MAX_DISK_MB` | number | `5120` | Maximum disk writes per session (MB) |

### 3.3 Monitoring Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `MAX_AGENT_RUNTIME_HOURS` | number | `8` | Alert threshold for runtime |
| `MIN_ACTIVITY_MINUTES` | number | `30` | Alert if idle longer than this |
| `MAX_MEMORY_PERCENT` | number | `85` | Alert threshold for memory usage |

### 3.4 Example: Setting Environment Variables

```bash
# In ~/.bashrc or ~/.zshrc
export ANTHROPIC_API_KEY="sk-ant-..."
export MAX_RUNTIME_HOURS=12
export MAX_MEMORY_MB=3072

# Or for single session
MAX_RUNTIME_HOURS=4 bash ~/scripts/start-agent-yolo.sh 1 "Task"
```

---

## 4. Resource Limits (ulimit)

### 4.1 Process-Level Limits

Applied via `ulimit` in start scripts.

| Limit | Flag | Type | Default | Description |
|-------|------|------|---------|-------------|
| Memory (Virtual) | `-v` | bytes | Not set* | Max virtual memory (disabled for Claude Code) |
| Processes | `-u` | count | `200` | Max user processes |
| File Size | `-f` | blocks | `5242880` | Max file size (5GB in 1KB blocks) |
| Open Files | `-n` | count | `1024` | Max open file descriptors |
| CPU Time | `-t` | seconds | unlimited | Max CPU time per process |
| Core Dump Size | `-c` | blocks | `0` | Max core dump size (disabled) |

**Note:** Memory limit via `ulimit -v` is not used due to Claude Code's WebAssembly requirements. Use systemd `MemoryMax` instead for hard limits.

### 4.2 Example: Setting Resource Limits

```bash
#!/bin/bash
# In start-agent-yolo.sh

# Set soft limits
ulimit -u 200                    # Max 200 processes
ulimit -f $((5120 * 1024))      # Max 5GB file size
ulimit -n 1024                   # Max 1024 open files

# Note: ulimit -v not used for Claude Code
```

### 4.3 Viewing Current Limits

```bash
# Show all limits
ulimit -a

# Show specific limit
ulimit -n  # Open files
ulimit -u  # Processes
```

---

## 5. Systemd Service Configuration

### 5.1 Service Unit Options

For production deployments with kernel-level resource enforcement.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `CPUQuota` | percentage | `80%` | Max CPU usage (e.g., 80% = 0.8 cores) |
| `MemoryMax` | bytes | `800M` | Hard memory limit |
| `MemoryHigh` | bytes | `700M` | Soft memory limit (throttle at this) |
| `TasksMax` | count | `100` | Max processes/threads |
| `LimitNOFILE` | count | `1024` | Max open files |
| `LimitNPROC` | count | `100` | Max processes |
| `RuntimeMaxSec` | seconds | `28800` | Max runtime (8 hours) |
| `TimeoutStartSec` | seconds | `60` | Max startup time |
| `Restart` | string | `on-failure` | Restart policy |
| `RestartSec` | seconds | `30` | Wait time before restart |

### 5.2 Disk I/O Limits

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `IOWeight` | number | `100` | I/O priority (1-10000) |
| `IOReadBandwidthMax` | string | `10M` | Max read speed (e.g., `/dev/sda 10M`) |
| `IOWriteBandwidthMax` | string | `5M` | Max write speed (e.g., `/dev/sda 5M`) |

### 5.3 Security Hardening Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `PrivateTmp` | boolean | `true` | Isolated /tmp directory |
| `NoNewPrivileges` | boolean | `true` | Cannot gain new privileges |
| `ProtectSystem` | string | `strict` | Read-only /usr, /boot, /etc |
| `ProtectHome` | string | `read-only` | Protect other home directories |
| `ReadWritePaths` | array | `[...]` | Paths with write access |
| `ProtectKernelTunables` | boolean | `true` | Protect /proc/sys, /sys |
| `ProtectKernelModules` | boolean | `true` | Cannot load kernel modules |
| `ProtectControlGroups` | boolean | `true` | Protect cgroup filesystem |
| `RestrictRealtime` | boolean | `true` | No realtime scheduling |
| `RestrictSUIDSGID` | boolean | `true` | No SUID/SGID bits |

### 5.4 Example: Systemd Service File

```ini
[Unit]
Description=Claude Code Agent %i (YOLO Mode)
After=network.target

[Service]
Type=simple
User=claude-agent
Group=claude-agent
WorkingDirectory=/home/claude-agent/projects/continuously-running-agents

# Resource Limits
CPUQuota=80%
MemoryMax=800M
MemoryHigh=700M
TasksMax=100
LimitNOFILE=1024
LimitNPROC=100

# Disk I/O limits
IOWeight=100
IOReadBandwidthMax=/dev/sda 10M
IOWriteBandwidthMax=/dev/sda 5M

# Security hardening
PrivateTmp=true
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=read-only
ReadWritePaths=/home/claude-agent/projects /home/claude-agent/agents
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
RestrictRealtime=true
RestrictSUIDSGID=true

# Automatic restart on failure
Restart=on-failure
RestartSec=30
StartLimitBurst=3
StartLimitIntervalSec=600

# Timeout
TimeoutStartSec=60
RuntimeMaxSec=28800  # 8 hours

# Environment
Environment="HOME=/home/claude-agent"
Environment="PATH=/home/claude-agent/.nvm/versions/node/v22.11.0/bin:/usr/local/bin:/usr/bin:/bin"

# Command
ExecStart=/usr/bin/tmux new-session -d -s agent-%i 'claude --dangerously-skip-permissions -p "Please wait for instructions"'

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=claude-agent-%i

[Install]
WantedBy=multi-user.target
```

### 5.5 Managing Systemd Services

```bash
# Install service
sudo cp scripts/systemd/claude-agent@.service /etc/systemd/system/
sudo systemctl daemon-reload

# Start/stop/restart
sudo systemctl start claude-agent@1
sudo systemctl stop claude-agent@1
sudo systemctl restart claude-agent@1

# Enable/disable auto-start
sudo systemctl enable claude-agent@1
sudo systemctl disable claude-agent@1

# View status and logs
sudo systemctl status claude-agent@1
sudo journalctl -u claude-agent@1 -f
```

---

## 6. Tmux Configuration

### 6.1 Session Options

| Option | Description | Example |
|--------|-------------|---------|
| Session Name | Unique identifier for tmux session | `prod-agent-1` |
| Working Directory | Initial directory for session | `~/projects/continuously-running-agents` |
| Detached | Start session in background | `-d` flag |

### 6.2 Example: Creating Tmux Session

```bash
# Basic session
tmux new-session -d -s prod-agent-1

# With working directory
tmux new-session -d -s prod-agent-1 -c ~/projects/continuously-running-agents

# With command
tmux new-session -d -s prod-agent-1 "bash script.sh"
```

### 6.3 Tmux Management Commands

```bash
# List sessions
tmux list-sessions
tmux ls

# Attach to session
tmux attach -t prod-agent-1
tmux a -t prod-agent-1

# Detach from session
# Press: Ctrl+B, then D

# Kill session
tmux kill-session -t prod-agent-1

# Check if session exists
tmux has-session -t prod-agent-1 2>/dev/null
```

---

## 7. Quick Reference Tables

### 7.1 Agent Startup Configuration

| Setting | Interactive | YOLO Mode | Production |
|---------|-------------|-----------|------------|
| Permissions | Manual approval | `--dangerously-skip-permissions` | `--dangerously-skip-permissions` |
| Max Runtime | N/A | 8 hours | 8 hours |
| Memory Limit | N/A | 2GB (ulimit disabled) | 800MB (systemd) |
| CPU Limit | N/A | 80% (monitoring only) | 80% (systemd enforced) |
| Auto-restart | No | No | Yes (systemd) |
| Logging | Terminal | File | systemd journal |

### 7.2 Model Selection by Task Type

| Task Type | Recommended Model | Cost | Speed |
|-----------|------------------|------|-------|
| Simple queries | `claude-haiku-3-5` | Low | Fast |
| Routine tasks | `claude-haiku-3-5` | Low | Fast |
| Standard dev work | `claude-sonnet-4` | Medium | Medium |
| Complex coding | `claude-sonnet-4-5` | Medium | Medium |
| Critical reasoning | `claude-opus-4` | High | Slower |
| Planning/architecture | `claude-opus-4` | High | Slower |

### 7.3 Resource Limits by Deployment Size

| Deployment | Agents | Memory/Agent | CPU/Agent | Total RAM | Total CPU |
|------------|--------|--------------|-----------|-----------|-----------|
| Minimal | 1 | 2GB | 80% | 2GB | 0.8 cores |
| Standard | 2-3 | 1.5GB | 60% | 3-4.5GB | 1.2-1.8 cores |
| Production | 5 | 800MB | 40% | 4GB | 2 cores |

**Recommended VPS:**
- Minimal: 2GB RAM, 1 CPU (Hetzner CX22: $5.83/mo)
- Standard: 4GB RAM, 2 CPU (Hetzner CPX21: $10.52/mo)
- Production: 8GB RAM, 4 CPU (Hetzner CPX31: $21.04/mo)

### 7.4 Common Configuration Patterns

#### Pattern 1: Development Agent (Interactive)

```bash
# No special configuration needed
claude
```

#### Pattern 2: Autonomous Agent (YOLO Mode)

```bash
# Resource-limited, time-limited
MAX_RUNTIME_HOURS=8 bash ~/scripts/start-agent-yolo.sh 1 "Task description"
```

#### Pattern 3: Production Agent (Systemd)

```bash
# Kernel-enforced limits, auto-restart, logging
sudo systemctl start claude-agent@1
```

#### Pattern 4: Cost-Optimized Multi-Agent

```bash
# Use Haiku for simple tasks
claude --model claude-haiku-3-5 -p "Simple task"

# Use Sonnet for complex tasks
claude --model claude-sonnet-4-5 -p "Complex task"
```

---

## 8. Configuration File Locations

### 8.1 Standard Paths

| File | Location | Purpose |
|------|----------|---------|
| Project config | `.claude/config.json` | Project-level settings |
| Project settings | `.claude/settings.json` | System prompt, hooks |
| Local settings | `.claude/settings.local.json` | Wildcard permissions (gitignored) |
| Global config | `~/.claude/config.json` | User-level defaults |
| Systemd service | `/etc/systemd/system/claude-agent@.service` | Production service |
| Agent logs | `~/agents/logs/agent-*.log` | Runtime logs |
| Resource logs | `~/agents/logs/resource-usage.log` | Monitoring data |

### 8.2 Configuration Priority

1. Command-line flags (highest priority)
2. `.claude/settings.local.json` (local overrides)
3. `.claude/settings.json` (project settings)
4. `.claude/config.json` (project config)
5. `~/.claude/config.json` (user defaults)
6. Built-in defaults (lowest priority)

---

## 9. Security Considerations

### 9.1 Permission Modes

| Mode | Safety | Use Case |
|------|--------|----------|
| Manual approval | Highest | Local development |
| `allowedTools` list | High | Controlled automation |
| `--dangerously-skip-permissions` | Medium | Isolated environments |
| No restrictions | Lowest | Never recommended |

### 9.2 Recommended Security Layers

1. **Isolated Environment**: Dedicated VPS/VM
2. **Limited Permissions**: Machine user with write-only access
3. **Branch Protection**: Prevent direct pushes to main
4. **Resource Limits**: Prevent runaway processes
5. **Logging**: Audit trail for all operations
6. **Monitoring**: Alerts for unusual behavior

### 9.3 Security Checklist

- [ ] API key stored securely (not in code)
- [ ] Machine user has minimal permissions
- [ ] Branch protection enabled on repository
- [ ] Resource limits configured (ulimit or systemd)
- [ ] Logging enabled and monitored
- [ ] Backup/checkpoint strategy in place
- [ ] Alert thresholds configured
- [ ] Emergency stop procedure documented

---

## 10. Troubleshooting

### 10.1 Common Issues

| Issue | Likely Cause | Solution |
|-------|--------------|----------|
| Out of memory | Memory limit too low | Increase `MAX_MEMORY_MB` or systemd `MemoryMax` |
| Agent won't start | Session already exists | Kill existing: `tmux kill-session -t prod-agent-1` |
| API errors | Invalid API key | Check `ANTHROPIC_API_KEY` environment variable |
| High CPU usage | Complex task or loop | Check logs, consider killing and restarting |
| Agent stuck | Infinite loop | Use `--max-turns` flag or timeout |
| Permission denied | Missing `--dangerously-skip-permissions` | Add flag or configure `allowedTools` |

### 10.2 Diagnostic Commands

```bash
# Check environment variables
env | grep ANTHROPIC
env | grep MAX_

# Check ulimit settings
ulimit -a

# Check systemd resource usage
systemctl show claude-agent@1 | grep -E "Memory|CPU|Tasks"

# Check process resource usage
ps aux | grep claude
top -p $(pgrep -f "claude")

# Check logs
tail -f ~/agents/logs/agent-1-*.log
sudo journalctl -u claude-agent@1 -f
```

---

## 11. Advanced Configurations

### 11.1 Multi-Model Strategy

```json
// .claude/config.json
{
  "agents": {
    "planner": {
      "model": "claude-opus-4",
      "maxTurns": 30,
      "temperature": 0.8
    },
    "worker": {
      "model": "claude-sonnet-4",
      "maxTurns": 100,
      "temperature": 0.7
    },
    "reviewer": {
      "model": "claude-haiku-3-5",
      "maxTurns": 20,
      "temperature": 0.5
    }
  }
}
```

### 11.2 Dynamic Resource Allocation

```bash
#!/bin/bash
# Adjust resources based on available system memory

AVAILABLE_RAM=$(free -m | awk 'NR==2{print $7}')
AGENT_COUNT=3

if [ $AVAILABLE_RAM -gt 6000 ]; then
    MAX_MEMORY_MB=2048
elif [ $AVAILABLE_RAM -gt 3000 ]; then
    MAX_MEMORY_MB=1024
else
    MAX_MEMORY_MB=512
fi

export MAX_MEMORY_MB
bash ~/scripts/start-agent-yolo.sh 1 "Task"
```

### 11.3 Conditional Tool Permissions

```json
// .claude/settings.local.json
{
  "autoApprove": {
    "write": [
      "docs/**/*.md",
      "tests/**/*.test.js",
      "!**/production/**"
    ],
    "bash": [
      "scripts/dev/**",
      "!scripts/production/**"
    ],
    "edit": [
      "**/*.json",
      "**/*.md",
      "!package.json",
      "!package-lock.json"
    ]
  }
}
```

---

## 12. Best Practices

### 12.1 Configuration Management

1. **Version Control**: Check in `.claude/config.json` and `.claude/settings.json`
2. **Gitignore**: Exclude `.claude/settings.local.json` (contains local overrides)
3. **Documentation**: Document any non-standard configurations in project README
4. **Testing**: Test configuration changes in isolated environment first
5. **Rollback**: Keep previous working configurations as backups

### 12.2 Resource Planning

1. **Start Small**: Begin with 1-2 agents, monitor resource usage
2. **Scale Gradually**: Add agents based on actual needs and capacity
3. **Monitor Trends**: Track resource usage over time
4. **Set Alerts**: Configure alerts before hitting limits
5. **Plan Headroom**: Keep 20-30% resources free for spikes

### 12.3 Security Hardening

1. **Principle of Least Privilege**: Only grant necessary permissions
2. **Defense in Depth**: Multiple security layers (isolation + permissions + limits)
3. **Regular Audits**: Review logs and permissions periodically
4. **Incident Response**: Have rollback and recovery procedures documented
5. **Secret Management**: Never commit API keys, use environment variables

---

## Related Documentation

- [04-claude-configuration.md](04-claude-configuration.md) - Detailed configuration examples
- [YOLO-MODE-GUIDE.md](YOLO-MODE-GUIDE.md) - Autonomous operation guide
- [06-security.md](06-security.md) - Security best practices
- [scripts/start-agent-yolo.sh](scripts/start-agent-yolo.sh) - Start script with limits
- [scripts/systemd/README.md](scripts/systemd/README.md) - Systemd deployment

---

**Last Updated**: 2025-10-21
**Addresses**: GAP-021 (Configuration Reference Documentation)
