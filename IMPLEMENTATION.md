# Implementation Guide: Continuous Claude Code Agent on Cloud VPS

> Step-by-step guide for deploying your continuously running Claude Code agent on cloud infrastructure.

**Recommended Platform**: Hetzner Cloud (best value, community-proven)
**Alternative**: OVHCloud Public Cloud
**OS**: Ubuntu 24.04 LTS
**Estimated Time**: 1-2 hours
**Difficulty**: Intermediate

**Why Hetzner?** Better price/performance, dedicated resources, 50% more CPU, community-proven (see `12-provider-comparison.md`)

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Phase 1: OVHCloud Instance Setup](#phase-1-ovhcloud-instance-setup)
3. [Phase 2: Server Configuration](#phase-2-server-configuration)
4. [Phase 3: Claude Code Installation](#phase-3-claude-code-installation)
5. [Phase 4: Agent Deployment](#phase-4-agent-deployment)
6. [Phase 5: Monitoring & Verification](#phase-5-monitoring--verification)
7. [Optional: Multi-Agent Setup](#optional-multi-agent-setup)
8. [Optional: Production Hardening](#optional-production-hardening)
9. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Local Machine

- SSH client installed
- SSH key pair generated (provider-specific naming recommended):
  ```bash
  # Generate Hetzner-specific key (recommended)
  ssh-keygen -t ed25519 -C "your_email@hetzner-claude-agent" -f ~/.ssh/hetzner_claude_agent -N ""

  # Or OVHCloud-specific key
  ssh-keygen -t ed25519 -C "your_email@ovhcloud-claude-agent" -f ~/.ssh/ovhcloud_claude_agent -N ""
  ```
  **Best Practice**: Use provider-specific key names to avoid confusion when managing multiple cloud providers
- Cloud provider account with payment method

### Cloud Provider Account

**Recommended: Hetzner Cloud**
- Create account at: https://www.hetzner.com/cloud
- Payment method required
- Recommended instance: CPX21 ($9.99/mo)
  - 3 vCPU (dedicated AMD)
  - 4 GB RAM
  - 80 GB SSD
  - 2 TB traffic
  - Available in: Hillsboro OR, Ashburn VA

**Alternative: OVHCloud**
- Create account at: https://us.ovhcloud.com/manager/
- Recommended if you need specific features
- See `12-provider-comparison.md` for detailed comparison

### Anthropic Account

**Choose ONE authentication method:**

**Option A: Max Plan Subscription (Recommended for cost savings)**
- Claude.ai account with Max Plan ($100/mo)
- Login at: https://claude.ai
- Uses subscription limits instead of pay-per-token billing
- Best for: 3-5 agents if usage is moderate

**Option B: API Key (Recommended for heavy usage)**
- Anthropic API key from: https://console.anthropic.com/settings/keys
- Pay-per-token billing (separate from claude.ai subscription)
- Best for: High-volume usage exceeding Max Plan limits

### Knowledge Requirements

- Basic terminal/command line usage
- SSH connection basics
- Basic understanding of tmux (optional but helpful)

---

## Phase 1: Cloud Instance Setup

### Option A: Hetzner Cloud (Recommended)

**1.1 Create Hetzner Account**
- Go to: https://www.hetzner.com/cloud
- Click **Sign Up** or **Console**
- Complete registration and add payment method

**1.2 Create Server**

1. In Hetzner Cloud Console, click **New Project** (or use existing)
2. Click **Add Server**
3. **Location**: Select **Hillsboro, OR** (us-west) or **Ashburn, VA** (us-east)
4. **Image**: Ubuntu → **Ubuntu 24.04 LTS**
5. **Type**:
   - **For 3-5 agents**: **CPX21** ⭐ **Recommended**
     - 3 vCPU (dedicated AMD)
     - 4 GB RAM
     - 80 GB SSD
     - $9.99/mo
   - **For 1-2 agents (budget)**: CPX11
     - 2 vCPU, 2GB RAM, 40GB SSD
     - $4.90/mo (⚠️ may be tight on RAM)
   - **For 5-10 agents (if switching to API key)**: CPX31
     - 4 vCPU, 8GB RAM, 160GB SSD
     - $17.99/mo
6. **SSH Keys**: Click **Add SSH key**
   ```bash
   # Display your Hetzner-specific public key
   cat ~/.ssh/hetzner_claude_agent.pub

   # The format is: ssh-ed25519 <long-string> <comment>
   # Example: ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEQtLIBe... chris@hetzner-claude-agent
   ```
   - Name: `hetzner-claude-agent`
   - Paste your **entire** public key (all three parts: algorithm, key, comment)
   - Note: Hetzner's UI auto-fills the Name field from the comment (last part)
7. **Server name**: Choose semantic name based on purpose
   - `claude-agents` - Generic, works for multiple agents ✅ **Recommended**
   - `claude-agent-primary` - Implies you'll have secondary servers
   - `claude-agent-4gb-hil-1` - Overly specific, harder to remember
   - Keep it simple and memorable
8. **Networking**: Leave default settings
   - ✅ Public IPv4: Enabled (automatic)
   - ❌ Private network: Not needed (uncheck if shown)
   - ❌ IPv6: Optional
9. **Volumes/Firewalls/Backups**: Skip these for now (default: none selected)
10. Click **Create & Buy Now**
11. **Note the IP address** once server is created (shown in dashboard within 30-60 seconds)

**Cost**: $9.99/mo (CPX21) + $100/mo (Max Plan) = **$109.99/mo total**

---

### Option B: OVHCloud (Alternative)

**Only choose OVHCloud if:**
- You need specific OVHCloud features
- You're already familiar with OVHCloud
- Hetzner is unavailable in your region

**See legacy instructions**: Originally documented for OVHCloud, but Hetzner offers better value (see `12-provider-comparison.md` for comparison)

**Quick OVHCloud Setup**:
1. Log in to: https://us.ovhcloud.com/manager/
2. **Public Cloud** → **Create instance**
3. Region: Oregon (Hillsboro)
4. Instance: **D2-4** (2 vCPU, 4GB, $13.15/mo) - Shared resources
5. OS: Ubuntu 24.04 LTS
6. Add SSH key
7. Create instance

**Note**: OVHCloud D2-4 is $3.16/mo more expensive and has shared resources vs Hetzner CPX21's dedicated resources

### 1.3 Initial Connection Test

**For Hetzner**:
```bash
# Test SSH connection with Hetzner-specific key (Hetzner uses root by default)
ssh -i ~/.ssh/hetzner_claude_agent root@YOUR_INSTANCE_IP

# If successful, you should see:
# - Ubuntu welcome message
# - System information (kernel version, packages to upgrade)
# - IP address and hostname confirmation

# Type 'exit' to disconnect for now
```

**Expected output example**:
```
Welcome to Ubuntu 24.04.1 LTS (GNU/Linux 6.8.0-71-generic x86_64)
...
System information as of Mon Oct 20 00:52:31 UTC 2025
...
root@claude-agents:~#
```

**For OVHCloud**:
```bash
# Test SSH connection (OVHCloud uses ubuntu user)
ssh ubuntu@YOUR_INSTANCE_IP

# If successful, you should see Ubuntu welcome message
# Type 'exit' to disconnect for now
```

**Troubleshooting connection issues**: See [Troubleshooting section](#troubleshooting)

---

## Phase 2: Server Configuration

### 2.1 Upload Setup Scripts

From your local machine, upload the setup scripts to your instance:

```bash
# Navigate to your project directory
cd /path/to/cloud-agent  # Or wherever you have the scripts

# For Hetzner (uses root):
scp -i ~/.ssh/hetzner_claude_agent -r knowledge-base/scripts root@YOUR_INSTANCE_IP:~/

# Note: We're uploading knowledge-base/scripts which contains:
# - scripts/setup/01-server-setup.sh
# - scripts/setup/02-install-claude.sh
# - scripts/monitoring/*
# - scripts/latency-test/*

# For OVHCloud (uses ubuntu):
scp -r scripts config ubuntu@YOUR_INSTANCE_IP:~/
```

**What gets uploaded**:
- `~/scripts/setup/` - Server and Claude Code setup scripts
- `~/scripts/monitoring/` - Resource monitoring tools
- `~/scripts/latency-test/` - Optional API latency testing tools

### 2.2 Run Server Setup Script

SSH into your instance and run the initial setup:

**For Hetzner**:
```bash
# Connect to instance with Hetzner-specific key (already root)
ssh -i ~/.ssh/hetzner_claude_agent root@YOUR_INSTANCE_IP

# Run setup script (automatically executable)
bash ~/scripts/setup/01-server-setup.sh
```

**During execution you'll see**:
- System package updates (apt update, apt upgrade)
- Installation of 50+ packages
- Kernel upgrade (6.8.0-71 → 6.8.0-85 or newer)
- User creation (`claude-agent`)
- Firewall configuration (UFW)
- fail2ban installation
- System optimization

**Note about kernel upgrade**:
```
Pending kernel upgrade
----------------------
Newer kernel available

The currently running kernel version is 6.8.0-71-generic which is not the
expected kernel version 6.8.0-85-generic.

Restarting the system to load the new kernel will not be handled automatically,
so you should consider rebooting.
```

**You can ignore this for now** - the server will work fine with the running kernel. Reboot later when convenient:
```bash
# Optional: Reboot to load new kernel
sudo reboot
# Wait 30 seconds, then reconnect
ssh -i ~/.ssh/hetzner_claude_agent root@YOUR_INSTANCE_IP
```

**For OVHCloud**:
```bash
# Connect to instance
ssh ubuntu@YOUR_INSTANCE_IP

# Switch to root (required for setup)
sudo -i

# Make script executable
chmod +x ~/scripts/setup/01-server-setup.sh

# Run setup script
bash ~/scripts/setup/01-server-setup.sh
```

**What this script does**:
- Updates system packages
- Creates `claude-agent` user
- Configures SSH security
- Sets up firewall (UFW)
- Installs essential tools (tmux, git, htop, etc.)
- Configures fail2ban
- Applies system optimizations

**Expected duration**: 5-10 minutes

### 2.3 Test New User Access

After setup completes, test login as the new agent user:

```bash
# Exit root session
exit

# Exit ubuntu session
exit

# From your local machine, connect as new user
ssh claude-agent@YOUR_INSTANCE_IP
```

✅ **Checkpoint**: You should be able to login as `claude-agent` user

---

## Phase 3: Claude Code Installation

### 3.1 Run Installation Script

**IMPORTANT**: This script must be run as `claude-agent` user, NOT root.

```bash
# If still logged in as root, first copy scripts to claude-agent home
cp -r ~/scripts /home/claude-agent/
chown -R claude-agent:claude-agent /home/claude-agent/scripts

# Then switch to claude-agent user
su - claude-agent

# Run installation
bash ~/scripts/setup/02-install-claude.sh
```

**OR reconnect as claude-agent from your local machine**:
```bash
# From your local machine
ssh -i ~/.ssh/hetzner_claude_agent claude-agent@YOUR_INSTANCE_IP

# Run installation
bash ~/scripts/setup/02-install-claude.sh
```

**What this script does**:
- Adds NodeSource repository for Node.js 20.x
- Installs Node.js 20.19.5 and npm 10.8.2
- Installs Claude Code CLI v2.0.22 globally via npm
- Prompts for authentication method choice (interactive)
- Sets up environment variables
- Creates convenience aliases

**Expected duration**: 5-10 minutes

**Expected versions**:
- Node.js: v20.19.5
- npm: 10.8.2
- Claude Code: 2.0.22

### 3.2 Choose Authentication Method

The installation script will prompt you to choose between:
1. Max Plan Login (Recommended) - Uses claude.ai subscription
2. API Key - Pay-per-use billing

**For headless servers (no GUI), Max Plan authentication requires special setup using tmux.**

#### Option A: Max Plan Login (Recommended - saves $25-50/mo)

**Challenge**: The `claude login` command opens an interactive OAuth flow that requires:
1. Browser authentication on your local machine
2. Copying an OAuth code back to the server terminal
3. Multiple interactive prompts (theme selection, security notes, directory trust)

**Solution**: Use tmux to manage the interactive session from your local machine.

**Step-by-step process**:

```bash
# 1. SSH into server as claude-agent
ssh -i ~/.ssh/hetzner_claude_agent claude-agent@YOUR_INSTANCE_IP

# 2. Start tmux session for login
tmux new-session -d -s claude-login 'claude login; echo AUTHENTICATION_COMPLETE; sleep 10'

# 3. Capture the OAuth URL from tmux
sleep 2
tmux capture-pane -t claude-login -p -S -100 > /tmp/claude-login.txt

# 4. Extract the full URL (it may be wrapped across multiple lines)
cat /tmp/claude-login.txt | sed -n "/https:\/\/claude.ai/,/Paste code/p" | \
  grep -v "Paste code" | grep -v "^$" | tr -d "\n"
```

This will output a URL like:
```
https://claude.ai/oauth/authorize?code=true&client_id=9d1c250a-e61b-44d9-88ed-5944d1962f5e&response_type=code&redirect_uri=https%3A%2F%2Fconsole.anthropic.com%2Foauth%2Fcode%2Fcallback&scope=org%3Acreate_api_key+user%3Aprofile+user%3Ainference&code_challenge=V8j-Z1Q41ydz1pOJZ657FIA1N8FwxI8CBxQ7slLcKGI&code_challenge_method=S256&state=2fJfir0QPpYW0GokjyV2EIVgLIglxkNfXK6lttR4m6U
```

**5. On your local machine**:
- Open the URL in your browser
- Authenticate with your claude.ai Max Plan account
- Copy the authentication code shown (format: `xxxxx#yyyyy`)

**6. Back on the server, paste the code**:
```bash
# Send the code to tmux session
tmux send-keys -t claude-login 'YOUR_CODE_HERE' Enter

# Watch the authentication progress
tmux attach -t claude-login
```

**7. Complete the setup prompts**:
- Theme selection: Press Enter (accepts default "Dark mode")
- Login method: Press Enter (selects "Claude account with subscription")
- Security notes: Press Enter to acknowledge
- Trust directory: Press Enter (selects "Yes, proceed")

**8. Verify authentication**:
```bash
# Test Claude Code
claude -p "What is 2+2? Answer in one word."
# Expected output: Four

# Clean up tmux session
tmux kill-session -t claude-login
```

**Authentication complete!** Your server is now authenticated with your Max Plan subscription.

**What just happened**:
- You authenticated using your claude.ai Max Plan account
- The authentication persists across sessions (saved to `~/.claude/`)
- All agents on this server will now use your Max Plan subscription
- Subscription limits (~225 messages/5hrs) are shared across all agents

**Rate Limits**: ~225 messages per 5 hours shared across all agents
**Best for**: 3-5 agents with moderate usage patterns

**Option B: API Key (For heavy usage)**

When prompted, enter your API key:

```bash
# Set environment variable
export ANTHROPIC_API_KEY="sk-ant-api03-..."

# Add to ~/.bashrc for persistence
echo 'export ANTHROPIC_API_KEY="sk-ant-api03-..."' >> ~/.bashrc
```

**Billing**: Pay-per-token (separate from subscription)
**Best for**: High-volume usage exceeding Max Plan limits

### 3.3 Verify Installation

```bash
# Reload environment
source ~/.bashrc

# Check Node.js
node --version
# Expected: v20.19.5

# Check npm
npm --version
# Expected: 10.8.2

# Check Claude Code CLI
claude --version
# Expected: 2.0.22 (Claude Code)

# Test authentication (already tested in step 3.2, but can verify again)
claude -p "Hello, Claude! Please respond briefly."
# Should get a response from Claude
```

**Troubleshooting OAuth URL Issues**:

If the URL gets corrupted when copying from terminal:
1. Save the URL to a file on the server first:
   ```bash
   # On server
   cat /tmp/claude-login.txt | sed -n "/https:\/\/claude.ai/,/Paste code/p" | \
     grep -v "Paste code" | grep -v "^$" | tr -d "\n" > ~/auth-url.txt

   # Verify it looks correct
   cat ~/auth-url.txt
   ```

2. Download the file to your local machine:
   ```bash
   # On local machine
   scp -i ~/.ssh/hetzner_claude_agent claude-agent@YOUR_IP:~/auth-url.txt ./
   cat auth-url.txt  # Copy from here
   ```

3. Common URL issues:
   - Missing hyphens in code_challenge value (should be `V8j-Z1Q4...` not `V8jZ1Q4...`)
   - Typo in parameter names (`code_challenge_method` not `code_challege_method`)
   - Line breaks in the middle of the URL
   - The URL must be one continuous line with no spaces or newlines

✅ **Checkpoint**: Claude Code CLI v2.0.22 installed and Max Plan authentication verified

**Important Notes**:
- Authentication is saved to `~/.claude/` and persists across sessions
- All agents on this VM will share your Max Plan subscription rate limits (~225 messages/5hrs)
- Monitor usage and consider API key if frequently hitting rate limits
- For 3-5 agents: ~75 messages/5hrs per agent
- For 5-10 agents: ~45-22 messages/5hrs per agent

---

## Phase 4: Agent Deployment

### 4.1 Configure tmux

```bash
# Copy tmux configuration
cp ~/config/.tmux.conf ~/.tmux.conf

# Test tmux
tmux new -s test
# Press Ctrl+b, then d to detach
# tmux attach -t test to reattach
# tmux kill-session -t test to kill
```

### 4.2 Prepare Project Directory

```bash
# Create project directory
mkdir -p ~/projects/main
cd ~/projects/main

# Initialize git repository (recommended)
git init
git config user.name "Claude Agent"
git config user.email "agent@yourdomain.com"

# Create initial README
echo "# Agent Project" > README.md
git add README.md
git commit -m "init: initial commit"
```

### 4.3 Start Your First Agent

**Option A: Interactive Mode** (recommended for first time):

```bash
cd ~
bash scripts/setup/start-agent.sh
```

Follow the prompts:
- **Session name**: `main-agent` (or your choice)
- **Project path**: `~/projects/main` (or your project)
- **Task description**: "Work on project tasks" (or specific task)
- **Attach now?**: `y` (to see it working)

**Option B: Command Line Mode**:

```bash
bash scripts/setup/start-agent.sh main-agent ~/projects/main "Work on project tasks"
```

### 4.4 Interact with Agent

Once attached to tmux session:

1. You'll see Claude Code interface
2. Type your instructions
3. Agent will respond and execute tasks
4. Press `Ctrl+b, then d` to detach (agent keeps running)
5. Press `Ctrl+b, then 1` to view logs
6. Press `Ctrl+b, then 2` to view system resources
7. Press `Ctrl+b, then 3` to view git status

### 4.5 Test Persistence

```bash
# Detach from session (Ctrl+b, d)
# Or if not attached: tmux list-sessions to see it's running

# Disconnect from server
exit

# Wait a few minutes

# Reconnect to server
ssh claude-agent@YOUR_INSTANCE_IP

# Reattach to agent
tmux attach -t main-agent

# Agent should still be running!
```

✅ **Checkpoint**: Agent running persistently in tmux

---

## Phase 5: Monitoring & Verification

### 5.1 Start Resource Monitoring (CRITICAL)

**Start this immediately to collect data for scaling decisions:**

```bash
# Start continuous resource monitoring (runs in background)
tmux new -d -s resource-monitor "bash ~/scripts/monitoring/resource-stats.sh"

# Verify it's running
tmux ls | grep resource-monitor
```

**What this does:**
- Logs CPU, RAM, Load, Swap, Disk every 5 minutes
- Creates `~/agents/logs/resource-usage.log`
- Provides data for scaling decisions after 7+ days
- Runs 24/7 in background tmux session

**View live dashboard:**
```bash
# Real-time monitoring dashboard
bash ~/scripts/monitoring/dashboard.sh

# After 7 days, analyze usage patterns
bash ~/scripts/monitoring/analyze-usage.sh 7
```

✅ **Critical**: Start this on Day 1 to inform future scaling decisions!

### 5.2 Start Agent Monitoring Dashboard

In a new terminal session:

```bash
ssh claude-agent@YOUR_INSTANCE_IP

# Run monitoring script
bash scripts/monitoring/monitor-agent.sh
```

You'll see:
- System resources (CPU, RAM, Disk)
- Active tmux sessions
- Recent log activity
- Health status

**Dashboard controls**:
- `q` - Quit
- `a` - Attach to session
- `l` - View logs
- `r` - Refresh now

### 5.3 Check Agent Logs

```bash
# View latest log file
tail -f ~/agents/logs/main-agent.log

# View all logs
ls -lh ~/agents/logs/

# Search for errors
grep -i error ~/agents/logs/*.log
```

### 5.4 Monitor System Resources

```bash
# CPU and Memory
htop

# Disk usage
df -h

# Network activity
sudo nethogs

# All tmux sessions
tmux ls

# View resource monitoring dashboard (with 7-day averages)
bash ~/scripts/monitoring/dashboard.sh
```

### 5.5 Test Agent Functionality

Give your agent some test tasks:

```bash
# Attach to agent
tmux attach -t main-agent

# Try these example tasks:
"Create a simple Python script that prints hello world"
"Explain the files in this project"
"Create a .gitignore file for a Node.js project"
```

### 5.6 Monitor Max Plan Rate Limits

Since you're using Max Plan authentication, monitor for rate limit warnings:

```bash
# Check agent logs for rate limit messages
grep -i "rate limit" ~/agents/logs/*.log

# If you see rate limits frequently:
# - Consider reducing agent count (5 → 3)
# - Switch to API key authentication for heavier usage
# - Stagger agent activity times
```

**Max Plan Limits**: ~225 messages per 5 hours (account-wide)
- 5 agents = ~45 msg/5hrs each
- 3 agents = ~75 msg/5hrs each

✅ **Checkpoint**: Agent working correctly and monitored

**Important**: Resource monitoring is now running in background. After 7 days, run:
```bash
bash ~/scripts/monitoring/analyze-usage.sh 7
```
This will tell you if s1-4 is sufficient or if you should scale to b2-7.

---

## Optional: Multi-Agent Setup

For running 5-50 parallel agents with coordination.

### Step 1: Initialize Coordination

```bash
# Source coordination functions
source ~/scripts/coordination/agent-coordination.sh

# Initialize coordination system
init_coordination

# Add some tasks
add_task "src/auth.ts" "Implement authentication" "high"
add_task "src/api.ts" "Add API endpoints" "medium"
add_task "tests/unit.test.ts" "Write unit tests" "medium"
add_task "docs/README.md" "Update documentation" "low"

# Verify tasks
check_planned_work
```

### Step 2: Spawn Multiple Agents

```bash
# Spawn 5 agents (adjust number as needed)
bash ~/scripts/coordination/spawn-agents.sh 5 ~/projects/main

# This will:
# - Create 5 agent tmux sessions (agent-1 through agent-5)
# - Create monitoring dashboard
# - Set up coordination system
# - Start all agents automatically pulling from task queue
```

### Step 3: Monitor Multi-Agent System

```bash
# View dashboard
tmux attach -t agent-dashboard

# View specific agent
tmux attach -t agent-1

# Check coordination stats
source ~/scripts/coordination/agent-coordination.sh
show_stats

# View active work
check_active_work

# View completed work
check_completed_work
```

### Step 4: Manage Tasks

```bash
# Add more tasks dynamically
source ~/scripts/coordination/agent-coordination.sh
add_task "src/newfile.ts" "Implement new feature" "high"

# Check for stale agents (stuck > 30 min)
check_stale_agents

# Clean up stale agents
cleanup_stale_agents
```

---

## Optional: Production Hardening

For 24/7 production use with auto-restart and monitoring.

### Step 1: Set up Systemd Service

```bash
# Edit service file with your details
nano ~/config/claude-agent.service

# Update these lines:
# - Environment="ANTHROPIC_API_KEY=your-actual-key"
# - WorkingDirectory=/home/claude-agent/projects/main
# - User=claude-agent

# Install service
sudo cp ~/config/claude-agent.service /etc/systemd/system/

# Reload systemd
sudo systemctl daemon-reload

# Enable service (start on boot)
sudo systemctl enable claude-agent

# Start service
sudo systemctl start claude-agent

# Check status
sudo systemctl status claude-agent
```

### Step 2: Configure Automatic Backups

```bash
# Create backup script
cat > ~/scripts/backup-agent.sh <<'EOF'
#!/bin/bash
BACKUP_DIR=~/backups
DATE=$(date +%Y%m%d-%H%M%S)
mkdir -p $BACKUP_DIR

# Backup projects
tar -czf "$BACKUP_DIR/projects-$DATE.tar.gz" ~/projects/

# Backup logs
tar -czf "$BACKUP_DIR/logs-$DATE.tar.gz" ~/agents/logs/

# Keep only last 7 days
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "Backup completed: $DATE"
EOF

chmod +x ~/scripts/backup-agent.sh

# Test backup
~/scripts/backup-agent.sh

# Schedule daily backups at 3 AM
(crontab -l 2>/dev/null; echo "0 3 * * * ~/scripts/backup-agent.sh") | crontab -
```

### Step 3: Set up Tailscale (Secure VPN)

For secure remote access:

```bash
# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Authenticate
sudo tailscale up

# Follow the link to authenticate in browser

# Get your Tailscale IP
tailscale ip -4

# Now you can access your instance securely via Tailscale IP
# ssh claude-agent@100.x.x.x
```

### Step 4: Configure Cost Monitoring

```bash
# Create cost tracking script
cat > ~/scripts/track-costs.sh <<'EOF'
#!/bin/bash
# Simple cost tracking placeholder
# TODO: Integrate with Anthropic API usage endpoint

echo "Cost Tracking - $(date)"
echo "Active sessions: $(tmux ls 2>/dev/null | wc -l)"
echo "Check Anthropic console for API usage: https://console.anthropic.com/settings/usage"
EOF

chmod +x ~/scripts/track-costs.sh

# Run weekly cost check
(crontab -l 2>/dev/null; echo "0 9 * * MON ~/scripts/track-costs.sh | mail -s 'Weekly Agent Cost Report' your@email.com") | crontab -
```

---

## Troubleshooting

### Cannot SSH to Instance

**Problem**: Connection refused or timeout

**Solutions**:
```bash
# Check instance is running in OVHCloud console
# Check security group allows SSH (port 22)
# Try with verbose output
ssh -v ubuntu@YOUR_INSTANCE_IP

# If firewall blocking, check UFW status
sudo ufw status

# Ensure SSH is allowed
sudo ufw allow ssh
```

### API Key Not Working

**Problem**: Authentication error from Claude Code

**Solutions**:
```bash
# Verify key is set
echo $ANTHROPIC_API_KEY

# If empty, set it
export ANTHROPIC_API_KEY="sk-ant-api03-..."

# Add to ~/.bashrc for persistence
echo 'export ANTHROPIC_API_KEY="sk-ant-..."' >> ~/.bashrc
source ~/.bashrc

# Test API directly
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{"model":"claude-3-5-sonnet-20241022","max_tokens":10,"messages":[{"role":"user","content":"Hi"}]}'
```

### Agent Not Persisting

**Problem**: Agent stops when SSH disconnects

**Solutions**:
```bash
# Ensure using tmux
tmux ls

# Verify agent is in tmux session
tmux attach -t main-agent

# Detach properly (don't use Ctrl+C or 'exit')
# Use: Ctrl+b, then d

# Check if session is still running
tmux has-session -t main-agent && echo "Running" || echo "Not running"
```

### High CPU/Memory Usage

**Problem**: System resources exhausted

**Solutions**:
```bash
# Check resource usage
htop

# Check per-agent usage
ps aux | grep claude

# Reduce number of parallel agents
# Or upgrade to larger instance (b2-15 or b2-30)

# Check for infinite loops in logs
tail -f ~/agents/logs/*.log | grep -i "error\|loop"

# Kill problematic agent
tmux kill-session -t agent-name
```

### Disk Space Full

**Problem**: No space left on device

**Solutions**:
```bash
# Check disk usage
df -h

# Find large files
du -h ~ | sort -rh | head -20

# Clean up old logs
find ~/agents/logs -name "*.log" -mtime +7 -delete

# Clean up old backups
find ~/backups -name "*.tar.gz" -mtime +30 -delete

# Clean package cache
sudo apt clean
```

### tmux Session Lost

**Problem**: Cannot find tmux session after reboot

**Solutions**:
```bash
# Check if tmux server is running
ps aux | grep tmux

# List sessions
tmux ls

# If no sessions, restart agent
bash ~/scripts/setup/start-agent.sh

# For auto-start on reboot, use systemd service (see Production Hardening)
sudo systemctl enable claude-agent
```

---

## Lessons Learned from Actual Deployment

This section documents insights from real-world Hetzner CPX21 deployment (October 2025).

### SSH Key Management

**Lesson**: Use provider-specific SSH key names to avoid confusion.

**Problem**: Initially used generic `id_ed25519` key, then realized naming becomes confusing when managing multiple cloud providers.

**Solution**: Generate provider-specific keys:
```bash
# Good naming convention
~/.ssh/hetzner_claude_agent       # For Hetzner
~/.ssh/ovhcloud_claude_agent      # For OVHCloud
~/.ssh/aws_claude_agent           # For AWS

# Avoid generic names
~/.ssh/id_ed25519                 # Which provider is this?
```

**Benefit**: Clear SSH commands, easier to manage multiple providers simultaneously.

### Server Naming Strategy

**Lesson**: Keep server names simple and purpose-focused.

**Options considered**:
- `claude-agent-primary` - Implies you'll have secondary/tertiary servers
- `claude-agent-4gb-hil-1` - Too specific, hard to remember, specs may change
- `claude-agents` ✅ - Simple, generic, works for single or multiple agents

**Recommendation**: Use semantic names that describe purpose, not implementation details.

### Kernel Upgrades During Setup

**Lesson**: Kernel upgrades happen during `apt upgrade` but don't require immediate reboot.

**What happens**:
```
Pending kernel upgrade
Newer kernel available: 6.8.0-85-generic
Currently running: 6.8.0-71-generic
```

**Action**: Ignore the warning during setup, reboot later when convenient. The server works fine with the older running kernel.

**When to reboot**:
- After completing full setup
- During scheduled maintenance window
- If you encounter kernel-specific issues

### Script Permissions and User Switching

**Lesson**: The `02-install-claude.sh` script must run as `claude-agent`, not `root`.

**Problem**: Initially tried running as root, got error:
```
[ERROR] This script should NOT be run as root
[ERROR] Please run as your agent user (e.g., claude-agent)
```

**Solution**:
```bash
# Option 1: Copy scripts and switch user
cp -r ~/scripts /home/claude-agent/
chown -R claude-agent:claude-agent /home/claude-agent/scripts
su - claude-agent
bash ~/scripts/setup/02-install-claude.sh

# Option 2: Reconnect as claude-agent (recommended)
exit  # Exit root session
ssh -i ~/.ssh/hetzner_claude_agent claude-agent@YOUR_IP
bash ~/scripts/setup/02-install-claude.sh
```

**Why**: npm global installs need proper user permissions, and Claude Code config should be in the agent user's home directory.

### Headless Max Plan Authentication

**Lesson**: Max Plan authentication on headless servers requires tmux-based workaround.

**Challenge**: `claude login` expects interactive terminal with browser access, but servers don't have GUI.

**Solution**: Use tmux to capture OAuth URL and send authentication code remotely.

**Key insights**:
1. OAuth URL often wraps across multiple terminal lines - need to reassemble
2. URL must be copied exactly (missing hyphens or typos break authentication)
3. Authentication code format is `long-string#state-hash` (includes # character)
4. Multiple interactive prompts (theme, login method, security, directory trust)
5. All can be automated by sending Enter keys via tmux

**Time saved**: Once you understand the pattern, authentication takes 2-3 minutes vs 15-20 minutes of troubleshooting.

### Resource Sizing Validation

**Lesson**: CPX21 (3 vCPU, 4GB RAM) is correctly sized for 3-5 agents with Max Plan.

**Actual resource usage after setup**:
```
CPU: <5% idle (spikes to 20-30% during package installs)
RAM: ~800MB used (out of 4GB) after OS + Claude Code installation
Disk: ~4GB used (out of 80GB) after all setup
```

**Headroom**:
- CPU: 3 dedicated vCPUs can easily handle 5-10 concurrent agents (I/O-bound workload)
- RAM: 3.2GB free = plenty for 3-5 agents (~500MB each)
- Disk: 76GB free = room for extensive logging and project files

**Validation**: CPX21 is not over-provisioned. CPX11 (2GB RAM) would be tight.

### Authentication Persistence

**Lesson**: Max Plan authentication survives SSH disconnection and server operations.

**What persists**:
- Authentication tokens saved to `~/.claude/`
- All future `claude` commands use saved auth
- No need to re-authenticate on reconnection
- Survives tmux detach/reattach cycles

**What doesn't persist**:
- Authentication won't survive if `~/.claude/` is deleted
- Server rebuild requires re-authentication
- Changing user accounts requires separate authentication

### Installation Script Idempotency

**Lesson**: The installation scripts handle re-runs gracefully.

**Behavior**:
- Node.js check: Prompts if already installed
- Claude Code check: Prompts to reinstall/upgrade if found
- Package installs: Skip if already at latest version

**Benefit**: Safe to re-run scripts if setup is interrupted.

### Actual Setup Timeline

**Measured times** (Hetzner CPX21, Hillsboro OR):
- Server provisioning: 30-60 seconds
- SSH key setup and first connection: 2-3 minutes
- Script upload (scp): <10 seconds
- `01-server-setup.sh`: 8-10 minutes
- `02-install-claude.sh`: 6-8 minutes
- Max Plan authentication (with tmux): 3-5 minutes
- Verification and testing: 2-3 minutes

**Total**: ~25-30 minutes from signup to working Claude Code agent

**Compared to docs estimate**: "1-2 hours" is conservative, actual time is closer to 30 minutes for experienced users.

---

## Next Steps

After successful deployment:

1. **Monitor for 24 hours** to ensure stability
2. **Set up cost alerts** in Anthropic console
3. **Configure backups** (automated daily)
4. **Add monitoring** (uptime checks, resource alerts)
5. **Scale up** to multi-agent if needed
6. **Join community** - share your setup and learn from others

## Additional Resources

- **Knowledge Base**: See other markdown files in this repository
- **Examples**: 07-examples.md for real-world setups
- **Security**: 06-security.md for hardening
- **Cost Optimization**: 05-cost-optimization.md
- **Remote Access**: 03-remote-access.md for mobile setup

---

**Need Help?**

- Check the [Troubleshooting Guide](TROUBLESHOOTING.md)
- Review the [Contributing Guide](CONTRIBUTING.md)
- Open an issue on GitHub
- Follow @levelsio and @ericzakariasson for community insights

---

**Document History**:
- **v1.0** (October 15, 2025): Initial version with OVHCloud focus
- **v1.1** (October 20, 2025): Updated with actual Hetzner deployment experience
  - Added provider-specific SSH key naming
  - Added server naming best practices
  - Documented kernel upgrade handling
  - Added detailed Max Plan authentication via tmux
  - Added "Lessons Learned" section from real deployment
  - Updated all version numbers (Node.js 20.19.5, Claude Code 2.0.22)
  - Added troubleshooting for OAuth URL formatting
  - Validated CPX21 resource sizing

**Tested On**:
- **Primary**: Hetzner Cloud CPX21 (3 vCPU, 4GB RAM, 80GB SSD, Hillsboro OR)
- **OS**: Ubuntu 24.04.1 LTS (kernel 6.8.0-71/6.8.0-85)
- **Node.js**: v20.19.5
- **npm**: 10.8.2
- **Claude Code**: 2.0.22
- **Authentication**: Max Plan subscription via tmux-based OAuth flow
- **Setup Time**: 25-30 minutes (vs 1-2 hours estimated)
- **Resource Usage**: ~800MB RAM, <5% CPU idle, 4GB disk after setup

**GitHub Security Model**:
- **Machine User**: @renchris-agent (collaborator, not admin)
- **Branch Protection**: `enforce_admins: false` enables owner bypass
- **Result**: Owner can `git push origin main`, agent cannot (blocked by protection)
- **Isolation**: Agent has access to 1 repo only, blocked from other 81 repos

**Author**: Chris Ren
**Last Updated**: October 20, 2025
