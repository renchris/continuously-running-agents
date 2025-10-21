# Getting Started - Your Path to Continuously Running Agents

## 🚀 5-Minute Quick Start for Complete Beginners

**Never deployed an AI agent before? Start here!** This guide gets you from zero to a running agent in 5 minutes with copy-paste commands.

### Prerequisites Check (2 minutes)

Before starting, validate your environment with these commands:

```bash
# 1. Check if you have Node.js (v18.0 or higher required)
node --version
# Expected: v18.0.0 or higher
# If missing: curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - && sudo apt-get install -y nodejs

# 2. Check if you have npm
npm --version
# Expected: 9.0.0 or higher
# If missing: sudo apt-get install -y npm

# 3. Check if you have tmux
tmux -V
# Expected: tmux 3.0 or higher
# If missing: sudo apt-get install -y tmux

# 4. Check if you have git
git --version
# Expected: git version 2.30.0 or higher
# If missing: sudo apt-get install -y git

# 5. Verify you have an Anthropic API key
echo $ANTHROPIC_API_KEY | wc -c
# Expected: ~108 characters (if set)
# If missing: Get one at https://console.anthropic.com/settings/keys
```

**Don't have a VPS (cloud server)?** See [Getting a $5/month VPS](#getting-your-first-vps-5-minutes) below.

### First-Time Setup (2 minutes)

Copy and paste these commands one at a time:

```bash
# 1. Install Claude Code CLI globally
npm install -g @anthropic-ai/claude-code

# Validate installation
claude --version
# Expected output: @anthropic-ai/claude-code/2.x.x

# 2. Set your API key (replace with your actual key)
export ANTHROPIC_API_KEY="sk-ant-api03-your-key-here"

# Add to bashrc for persistence
echo 'export ANTHROPIC_API_KEY="sk-ant-api03-your-key-here"' >> ~/.bashrc
source ~/.bashrc

# 3. Validate API key works
curl -X POST https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{"model":"claude-3-5-sonnet-20241022","max_tokens":10,"messages":[{"role":"user","content":"test"}]}'
# Expected: JSON response with "content" field
# If you see "authentication_error", your API key is invalid

# 4. Create a project directory
mkdir -p ~/my-first-agent && cd ~/my-first-agent
git init
echo "# My First Agent Project" > README.md
git add . && git commit -m "Initial commit"
```

**Expected state after setup:**
- ✅ Claude Code installed and working
- ✅ API key validated and saved
- ✅ Project directory created with git
- ✅ Ready to launch your first agent

### Your First Agent Deployment (1 minute)

Launch your first continuously running agent:

```bash
# Start a new tmux session with your agent
tmux new-session -s my-first-agent

# Inside tmux, start Claude Code with a simple task
claude -p "Help me create a simple Node.js web server that responds 'Hello World' on port 3000"

# Watch as Claude creates the server!
# When done, press Ctrl+b, then d to detach (agent keeps running)
```

**What just happened?**
1. You created a persistent tmux session named "my-first-agent"
2. Claude Code started working on your task autonomously
3. You detached from the session - the agent continues working in the background
4. You can reconnect anytime to see progress

**Reconnect to your running agent:**
```bash
# Reattach to see what your agent is doing
tmux attach -t my-first-agent

# Detach again: Ctrl+b, then d
```

**Check all running sessions:**
```bash
tmux ls
# Expected: my-first-agent: 1 windows (created Wed Oct 21 10:15:30 2025)
```

**Stop your agent:**
```bash
# Kill the tmux session
tmux kill-session -t my-first-agent
```

### Validate Your Setup

Run these commands to confirm everything works:

```bash
# 1. Claude Code is installed
which claude
# Expected: /usr/local/bin/claude or ~/.npm-global/bin/claude

# 2. Tmux is working
tmux ls 2>/dev/null && echo "✅ Tmux working" || echo "❌ No sessions running"

# 3. Git is initialized
git status
# Expected: "On branch main" or "On branch master"

# 4. API key is set
[ -n "$ANTHROPIC_API_KEY" ] && echo "✅ API key set" || echo "❌ API key missing"

# 5. Test agent can run
echo "Testing Claude Code..."
claude -p "Print 'Hello from Claude!' and exit" --max-turns 1
# Expected: Agent should respond and complete
```

**All checks passed?** 🎉 Congratulations! You've successfully deployed your first continuously running agent!

### Getting Your First VPS (5 minutes)

**Don't have a server?** Here's how to get a $5/month VPS:

**Option 1: Hetzner (Recommended - €4.99/month)**

1. Go to [hetzner.com](https://www.hetzner.com/)
2. Create account (requires ID verification in EU)
3. Choose **CX22** instance:
   - 2 vCPU cores
   - 4GB RAM
   - 40GB SSD
   - €4.99/month (~$5.30/month)
4. Select **Ubuntu 22.04 LTS**
5. Add your SSH key (or create one: `ssh-keygen -t ed25519`)
6. Launch server - you'll get an IP address

**Option 2: DigitalOcean ($6/month)**

1. Go to [digitalocean.com](https://www.digitalocean.com/)
2. Create account (credit card required)
3. Choose **Basic Droplet**:
   - 1 vCPU
   - 2GB RAM
   - 50GB SSD
   - $6/month
4. Select **Ubuntu 22.04 LTS**
5. Add SSH key
6. Create droplet - you'll get an IP address

**Option 3: Vultr ($5/month)**

1. Go to [vultr.com](https://www.vultr.com/)
2. Create account
3. Choose **Cloud Compute**:
   - 1 vCPU
   - 1GB RAM
   - 25GB SSD
   - $5/month
4. Select **Ubuntu 22.04 LTS**
5. Add SSH key
6. Deploy - you'll get an IP address

**Connect to your new VPS:**
```bash
# Replace YOUR_VPS_IP with your server's IP address
ssh root@YOUR_VPS_IP

# If using SSH key:
ssh -i ~/.ssh/id_ed25519 root@YOUR_VPS_IP

# First time? You'll see a fingerprint prompt - type 'yes'
```

**Once connected, run the setup commands from "First-Time Setup" above!**

### Quick Troubleshooting

**Problem: `claude: command not found`**
```bash
# Fix: Add npm global bin to PATH
echo 'export PATH=$PATH:~/.npm-global/bin' >> ~/.bashrc
source ~/.bashrc
npm config set prefix ~/.npm-global
npm install -g @anthropic-ai/claude-code
```

**Problem: `authentication_error` from API**
```bash
# Fix: Check your API key
echo $ANTHROPIC_API_KEY
# Should output: sk-ant-api03-...
# If empty, set it again: export ANTHROPIC_API_KEY="sk-ant-api03-your-key-here"
```

**Problem: `tmux: command not found`**
```bash
# Fix: Install tmux
sudo apt-get update && sudo apt-get install -y tmux
```

**Problem: Agent keeps asking for approval**
```bash
# Fix: Use autonomous mode (be careful!)
claude -p "Your task" --dangerously-skip-permissions
# WARNING: Only use in isolated environments - agent can modify files freely
```

**Problem: Connection lost, agent stopped**
```bash
# Fix: That's what tmux prevents! Always run Claude inside tmux:
tmux new -s agent-name "claude -p 'Your task'"
# Now disconnecting won't stop the agent
```

### What's Next?

**You've successfully:**
- ✅ Installed Claude Code
- ✅ Validated your API key
- ✅ Deployed your first agent
- ✅ Learned tmux basics (attach, detach, kill)
- ✅ Understood session persistence

**Next steps:**

1. **Learn the paths** → See [Which Path Is Right For You?](#which-path-is-right-for-you) below
2. **Deploy to cloud** → Follow [Path 2: Cloud Deployment](#path-2-cloud-deployment-2-3-hours)
3. **Add mobile access** → See [03-remote-access.md](03-remote-access.md)
4. **Run multiple agents** → Follow [Path 3: Multi-Agent System](#path-3-multi-agent-system-4-6-hours)
5. **Optimize costs** → Read [05-cost-optimization.md](05-cost-optimization.md)

---

## Overview

This guide helps you navigate the knowledge base based on your skill level, use case, and goals. Whether you're a complete beginner or looking to scale to production, there's a path for you.

## Which Path Is Right For You?

**Answer these 3 questions to find your learning path:**

### Question 1: Have you used tmux before?

- **YES** → Continue to Question 2
- **NO** → Start with **Path 1** (Absolute Beginner)

### Question 2: Do you have a VPS (cloud server) already?

- **YES** → Continue to Question 3
- **NO** → Start with **Path 2** (Cloud Deployment)

### Question 3: What's your primary goal?

- **Run a single agent 24/7** → **Path 2** (Cloud Deployment)
- **Run multiple agents on different tasks** → **Path 3** (Multi-Agent System)
- **Production-ready setup with monitoring** → **Path 4** (Production Grade)
- **Maximum efficiency, minimum complexity** → **Path 5** (Pieter Levels Style)

### Quick Decision Tree

```
START
  |
  ├─ Never used tmux? ──────────────────────────────> Path 1 (Beginner)
  |
  ├─ No VPS yet? ───────────────────────────────────> Path 2 (Cloud Deploy)
  |
  ├─ Want simple automation? ───────────────────────> Path 5 (Pieter Levels)
  |
  ├─ Need multiple agents? ─────────────────────────> Path 3 (Multi-Agent)
  |
  └─ Building production system? ───────────────────> Path 4 (Production)
```

### Still Not Sure? Use This Guide

| Your Situation | Recommended Path | Time Investment |
|----------------|------------------|----------------|
| Complete beginner, never used Claude Code | Path 1 → Path 2 | 3-4 hours |
| Have experience, want quick setup | Path 2 → Path 5 | 2-3 hours |
| Team environment, need reliability | Path 2 → Path 4 | 1-2 days |
| Solo indie hacker, love automation | Path 5 only | 2-3 hours |
| Large codebase, need parallel work | Path 3 → Path 4 | 1-2 days |
| Mobile developer, need remote access | Path 2 + 03-remote-access.md | 3-4 hours |

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
