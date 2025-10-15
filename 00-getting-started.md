# Getting Started - Your Path to Continuously Running Agents

## Overview

This guide helps you navigate the knowledge base based on your skill level, use case, and goals. Whether you're a complete beginner or looking to scale to production, there's a path for you.

## Quick Navigation

- **For the absolute beginner**: Follow **Path 1** below
- **For rapid prototyping**: See **Path 5** (Pieter Levels style)
- **For production deployment**: Follow **Path 2** then **Path 4**
- **For multi-agent systems**: Start with **Path 3**

## Learning Paths

### Path 1: Absolute Beginner (1-2 hours)

**Goal**: Get your first agent running locally and understand the basics

**Prerequisites**:

- Basic terminal/bash knowledge
- Claude API key
- Node.js installed

**Steps**:

1. Read: `README.md` (Quick Start section)
2. Read: `02-tmux-setup.md` (Basic TMUX Commands section)
3. Read: `04-claude-configuration.md` (Basic Claude Code Usage section)
4. **Hands-on**: Run your first agent locally

**Tutorial**:

```bash
# Install dependencies
brew install tmux node  # macOS
# or
sudo apt install tmux nodejs npm  # Ubuntu

# Install Claude Code
npm install -g @anthropic-ai/claude-code

# Create project
mkdir ~/my-first-agent && cd ~/my-first-agent
git init

# Start agent in tmux
tmux new-session -s my-agent
claude -p "Help me build a simple Node.js web server"

# Detach: Ctrl+b, then d
# Reattach later: tmux attach -t my-agent
```

**Success criteria**:

- [ ] Agent running in tmux session
- [ ] Can detach and reattach to session
- [ ] Understand basic tmux commands
- [ ] Agent completed a simple task

**Estimated time**: 1-2 hours

---

### Path 2: Cloud Deployment (2-3 hours)

**Goal**: Deploy agent to VPS with 24/7 uptime

**Prerequisites**:

- Completed Path 1 OR comfortable with terminal
- Credit card for VPS signup
- SSH key generated

**Steps**:

1. Read: `01-infrastructure.md` (complete)
2. Read: `06-security.md` (Server Hardening section)
3. Read: `02-tmux-setup.md` (Persistent Agent Session section)
4. **Hands-on**: Deploy to cloud

**Tutorial**:

```bash
# 1. Create VPS (Hetzner recommended: €4.99/mo)
#    - Ubuntu 22.04
#    - Add your SSH key
#    - Note the IP address

# 2. Connect and setup
ssh root@YOUR_VPS_IP

apt update && apt upgrade -y
apt install -y nodejs npm tmux git fail2ban

npm install -g @anthropic-ai/claude-code

# 3. Security
ufw allow OpenSSH
ufw allow 60000:61000/udp  # For Mosh
ufw enable

systemctl enable fail2ban

# 4. Create non-root user
adduser agent
usermod -aG sudo agent
su - agent

# 5. Setup project
mkdir ~/projects/main-agent && cd ~/projects/main-agent
git init
echo "export ANTHROPIC_API_KEY='your-key'" >> ~/.bashrc
source ~/.bashrc

# 6. Start persistent agent
tmux new -s agent "claude -p 'Your continuous task'"
```

**Success criteria**:

- [ ] Agent running on VPS
- [ ] Can reconnect via SSH
- [ ] Agent persists after disconnecting
- [ ] Basic security measures in place

**Estimated time**: 2-3 hours

---

### Path 3: Multi-Agent System (4-6 hours)

**Goal**: Run multiple specialized agents in parallel

**Prerequisites**:

- Completed Path 2 OR have VPS with Claude Code installed
- Understanding of git branches
- Comfortable with bash scripting

**Steps**:

1. Read: `02-tmux-setup.md` (Multi-Agent Orchestration section)
2. Read: `07-examples.md` (Example 4: Claude Squad)
3. Read: `04-claude-configuration.md` (Subagent Patterns section)
4. **Hands-on**: Set up multi-agent system

**Tutorial Option A: Claude Squad (Easy)**:

```bash
# Install Claude Squad
git clone https://github.com/smtg-ai/claude-squad.git
cd claude-squad
./install.sh

# Launch TUI
cs

# Inside TUI:
# Press 'n' to create new agent session
# Enter task description
# Repeat for multiple agents
# Switch between agents with arrow keys
```

**Tutorial Option B: Manual Setup**:

```bash
# Create multiple agent workspaces
for i in {1..3}; do
    mkdir -p ~/agents/agent-$i
    cd ~/agents/agent-$i
    git init
done

# Launch specialized agents
tmux new -d -s agent-frontend "cd ~/agents/agent-1 && claude -p 'Build React components'"
tmux new -d -s agent-backend "cd ~/agents/agent-2 && claude -p 'Build Express API'"
tmux new -d -s agent-tests "cd ~/agents/agent-3 && claude -p 'Write comprehensive tests'"

# Monitor all agents
tmux ls

# Attach to specific agent
tmux attach -t agent-frontend
```

**Success criteria**:

- [ ] Multiple agents running simultaneously
- [ ] Each agent working on separate task
- [ ] Can switch between agent sessions
- [ ] Agents don't conflict with each other

**Estimated time**: 4-6 hours

---

### Path 4: Production Grade System (1-2 days)

**Goal**: Enterprise-ready agent deployment with monitoring, security, and recovery

**Prerequisites**:

- Completed Path 2
- Comfortable with systemd
- Understanding of SSL/TLS
- Experience with production systems

**Steps**:

1. Read: `01-infrastructure.md` (complete, focus on monitoring)
2. Read: `06-security.md` (complete)
3. Read: `03-remote-access.md` (Tailscale + SSL sections)
4. Read: `05-cost-optimization.md` (complete)
5. **Hands-on**: Build production system

**Key Components to Implement**:

**A. systemd Service**:

```bash
# /etc/systemd/system/claude-agent.service
[Unit]
Description=Claude Code Continuous Agent
After=network.target

[Service]
Type=forking
User=agent
WorkingDirectory=/home/agent/projects/main-agent
Environment="ANTHROPIC_API_KEY=your-key"
ExecStart=/usr/bin/tmux new-session -d -s claude-agent "/usr/bin/claude -p 'Continuous task'"
ExecStop=/usr/bin/tmux kill-session -t claude-agent
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

**B. Monitoring**:

```bash
# Monitor resource usage
cat > ~/monitor-agents.sh <<'EOF'
#!/bin/bash
while true; do
    echo "=== Agent Status $(date) ==="
    tmux ls 2>/dev/null || echo "No sessions"
    echo ""
    echo "CPU: $(top -bn1 | grep Cpu | awk '{print $2}')"
    echo "Memory: $(free -h | awk '/Mem:/ {print $3 "/" $2}')"
    echo "Disk: $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 " used)"}')"
    echo ""
    sleep 60
done
EOF

chmod +x ~/monitor-agents.sh
```

**C. Automated Backups**:

```bash
# Backup script with rotation
cat > ~/backup-agent.sh <<'EOF'
#!/bin/bash
BACKUP_DIR=~/backups
DATE=$(date +%Y%m%d-%H%M%S)
mkdir -p $BACKUP_DIR

tar -czf "$BACKUP_DIR/projects-$DATE.tar.gz" ~/projects/
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "Backup completed: $DATE"
EOF

chmod +x ~/backup-agent.sh

# Add to crontab
(crontab -l 2>/dev/null; echo "0 3 * * * ~/backup-agent.sh") | crontab -
```

**D. SSL Web Access**:

```bash
# Install GoTTY with SSL
sudo apt install -y certbot
sudo certbot certonly --standalone -d agents.yourdomain.com

PASSWORD=$(openssl rand -base64 16)
echo "GoTTY password: $PASSWORD" > ~/gotty-creds.txt

gotty -p 443 \
  --tls \
  --tls-crt /etc/letsencrypt/live/agents.yourdomain.com/fullchain.pem \
  --tls-key /etc/letsencrypt/live/agents.yourdomain.com/privkey.pem \
  --credential "admin:$PASSWORD" \
  --random-url \
  tmux attach -t claude-agent
```

**Success criteria**:

- [ ] Agent runs as systemd service (auto-restart)
- [ ] Monitoring in place (resources + logs)
- [ ] Automated daily backups
- [ ] Secure web access with SSL
- [ ] Cost tracking implemented
- [ ] Incident response plan documented
- [ ] Tested recovery procedures

**Estimated time**: 1-2 days

---

### Path 5: Pieter Levels Style (2-3 hours)

**Goal**: Minimalist automation approach - maximum efficiency, minimum complexity

**Philosophy**: "Automate everything, hire no one" - $3M/year on single $40/mo VPS with 700+ cron jobs

**Prerequisites**:

- Comfortable with cron jobs
- Basic bash scripting
- Prefer simplicity over complexity

**Steps**:

1. Read: `04-claude-configuration.md` (Pieter Levels /workers/ pattern section)
2. Read: `07-examples.md` (Pieter Levels examples)
3. Read: `01-infrastructure.md` (Single VPS optimization)
4. **Hands-on**: Build worker-based automation

**Tutorial**:

```bash
# 1. Create /workers/ folder structure
mkdir -p ~/workers/{maintenance,tasks,monitoring}

# 2. Create workers (simple bash scripts)
cat > ~/workers/maintenance/cleanup.sh <<'EOF'
#!/bin/bash
# Clean old logs
find ~/logs -name "*.log" -mtime +7 -delete
# Clean temp files
find /tmp -name "agent-*" -mtime +1 -delete
echo "Cleanup completed: $(date)" >> ~/workers/logs/cleanup.log
EOF

cat > ~/workers/tasks/process-queue.sh <<'EOF'
#!/bin/bash
# Process one task from queue
TASK=$(head -n 1 ~/tasks/queue.txt 2>/dev/null)
if [ -n "$TASK" ]; then
    echo "Processing: $TASK"
    claude -p "$TASK" && sed -i '1d' ~/tasks/queue.txt
fi
EOF

cat > ~/workers/monitoring/check-health.sh <<'EOF'
#!/bin/bash
# Check if agent is running
if ! tmux has-session -t agent 2>/dev/null; then
    echo "Agent down, restarting: $(date)" >> ~/workers/logs/restarts.log
    tmux new -d -s agent "claude -p 'Resume work'"
fi
EOF

chmod +x ~/workers/**/*.sh

# 3. Schedule workers with cron
crontab -e
# Add:
# */15 * * * * ~/workers/tasks/process-queue.sh
# 0 3 * * * ~/workers/maintenance/cleanup.sh
# */5 * * * * ~/workers/monitoring/check-health.sh
```

**Key Principles**:

- Each worker does ONE thing well
- Workers are stateless (idempotent)
- Logs are simple (append to file)
- No complex orchestration
- Cron handles scheduling
- Scale by adding more workers, not complexity

**Success criteria**:

- [ ] /workers/ folder organized by category
- [ ] At least 5 working cron jobs
- [ ] Workers are simple and focused
- [ ] Logs track worker execution
- [ ] Agent auto-restarts if down

**Estimated time**: 2-3 hours

---

## Navigation by Use Case

### Solo Developer

**Recommendation**: Path 1 → Path 2 → Path 5

**Budget**: $15-30/month (VPS + API)

**Guides to focus on**:

- `01-infrastructure.md` - Budget VPS section
- `02-tmux-setup.md` - Single agent setup
- `05-cost-optimization.md` - Minimize API costs

### Startup/Small Team

**Recommendation**: Path 2 → Path 3 → Path 4

**Budget**: $75-150/month

**Guides to focus on**:

- `02-tmux-setup.md` - Multi-agent coordination
- `07-examples.md` - Claude Squad setup
- `06-security.md` - Team access

### Large Codebase

**Recommendation**: Path 3 → Path 4, consider Agent Farm

**Budget**: $300-1000/month

**Guides to focus on**:

- `07-examples.md` - Agent Farm (50+ agents)
- `02-tmux-setup.md` - Advanced orchestration
- `05-cost-optimization.md` - Cost at scale

### Indie Hacker

**Recommendation**: Path 5 exclusively

**Budget**: $40-80/month

**Guides to focus on**:

- `04-claude-configuration.md` - /workers/ pattern
- `01-infrastructure.md` - Single VPS setup
- `07-examples.md` - Pieter Levels examples

### Mobile Developer

**Recommendation**: Path 2 → Add Path for mobile access

**Budget**: $10-25/month

**Guides to focus on**:

- `03-remote-access.md` - Complete guide
- `07-examples.md` - Mobile setups
- `02-tmux-setup.md` - Mosh integration

## Quick Reference: Common Tasks

### Start Simple Agent

```bash
tmux new -s agent "claude -p 'Your task'"
```

→ See: `02-tmux-setup.md`

### Deploy to VPS

```bash
# Follow complete guide in:
```

→ See: `01-infrastructure.md` - Step-by-step

### Add Web Access

```bash
gotty -p 8080 --credential user:pass tmux attach -t agent
```

→ See: `03-remote-access.md` - GoTTY section

### Run Multiple Agents

```bash
cs  # Claude Squad TUI
```

→ See: `07-examples.md` - Claude Squad

### Setup Cron Automation

```bash
crontab -e
# */15 * * * * ~/workers/task.sh
```

→ See: `04-claude-configuration.md` - Pieter Levels pattern

### Secure Your Setup

```bash
# Follow security checklist:
```

→ See: `06-security.md` - Complete checklist

### Optimize Costs

```bash
# Enable prompt caching, use right models
```

→ See: `05-cost-optimization.md` - Strategies

## Document Reference Guide

| Document | Best For | Time to Read |
|----------|----------|--------------|
| `README.md` | Overview and orientation | 10 min |
| `00-getting-started.md` | Choosing your path | 15 min |
| `01-infrastructure.md` | VPS setup and providers | 30 min |
| `02-tmux-setup.md` | Session management | 45 min |
| `03-remote-access.md` | Mobile/remote access | 40 min |
| `04-claude-configuration.md` | Agent configuration | 50 min |
| `05-cost-optimization.md` | Reducing costs | 35 min |
| `06-security.md` | Hardening your setup | 45 min |
| `07-examples.md` | Real-world patterns | 50 min |

**Total reading time**: ~5 hours for complete knowledge base

## Recommended Reading Order

### For Beginners

1. README.md
2. This file (00-getting-started.md) - Pick a path
3. Follow your chosen path's reading list

### For Experienced Developers

1. README.md (skim)
2. Pick relevant documents based on your goal
3. Jump to examples in `07-examples.md`

### For Production Deployment

1. `01-infrastructure.md`
2. `06-security.md`
3. `05-cost-optimization.md`
4. `02-tmux-setup.md`
5. `03-remote-access.md`

## Troubleshooting Guide

### Agent Won't Start

**Check**:

- Claude Code installed: `which claude`
- API key set: `echo $ANTHROPIC_API_KEY`
- Try manually: `claude -p "test"`

**See**: `04-claude-configuration.md` - Installation section

### Agent Keeps Crashing

**Check**:

- System resources: `free -h`, `df -h`
- Error logs: `~/.claude/logs/`
- OOM kills: `dmesg | grep -i "out of memory"`

**See**: `01-infrastructure.md` - Server Sizing section

### Can't Connect Remotely

**Check**:

- Firewall: `sudo ufw status`
- SSH running: `sudo systemctl status sshd`
- Correct IP/port

**See**: `03-remote-access.md` - Troubleshooting section

### Costs Too High

**Solutions**:

1. Enable prompt caching
2. Use Haiku for routine tasks
3. Consider Max subscription

**See**: `05-cost-optimization.md` - Complete guide

## Next Steps After Your Path

1. **Document Your Setup**: Keep notes on what works
2. **Monitor Performance**: Track uptime and costs
3. **Iterate and Improve**: Add features gradually
4. **Share Your Experience**: Help the community
5. **Explore Advanced Topics**: Try new patterns

## Community Resources

- Follow @levelsio for automation insights
- Follow @ericzakariasson for Cursor/Claude updates
- Check GitHub repos in `07-examples.md`
- Join discussions on X/Twitter, Reddit r/ClaudeAI

## Getting Help

**Questions about**:

- Claude Code: <https://github.com/anthropics/claude-code/issues>
- Setup issues: Review relevant doc section first
- Best practices: See `07-examples.md` for proven patterns

---

**Ready to start?** Pick your path above and begin your journey to continuously running agents!
