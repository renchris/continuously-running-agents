# Quick Start Guide - Get Your First Agent Running in 20 Minutes

> **Complete beginner's guide** to deploying a continuously running Claude Code agent. No assumptions made - we'll check everything step by step.

**Time Required**: 20 minutes (5 min setup check + 10 min installation + 5 min first agent)

**Last Updated**: 2025-10-21

---

## Step 0: Prerequisites Check (5 minutes)

Before we start, let's verify you have everything you need. Answer these questions:

### Question 1: Do you have an Anthropic API key or Max Plan subscription?

**Check if you have one**:
- Visit https://console.anthropic.com/settings/keys
- OR visit https://claude.ai/settings/billing

**What you need**:
- **Option A**: API Key starting with `sk-ant-...` (pay-per-use)
- **Option B**: Claude Max Plan subscription ($100/month, ~225 messages per 5 hours)

**Don't have either?**

1. Create account at https://console.anthropic.com
2. Add payment method
3. Generate an API key (Settings → API Keys → Create Key)
4. Copy the key - you'll need it in Step 3

**Which should I choose?**
- **API Key**: Best for getting started, pay only for what you use (~$1-5 for testing)
- **Max Plan**: Best if you already have a subscription, share limit across agents

---

### Question 2: Do you have SSH access to a server?

**Check if you have SSH access**:
```bash
# On your local machine, try:
ssh username@your-server-ip

# If this works, you have SSH access!
```

**Expected output** (success):
```
Welcome to Ubuntu 24.04 LTS
username@server:~$
```

**Don't have a server yet?** → See "Get a $5/month VPS" section below

---

### Question 3: Is Node.js installed on your server?

**Check Node.js version**:
```bash
# SSH into your server, then run:
node --version

# Need version 18.0 or higher
```

**Expected output**:
```
v20.11.0
```

**If you see "command not found"** → Don't worry, we'll install it in Step 2

---

### Question 4: Is tmux installed on your server?

**Check tmux installation**:
```bash
tmux -V
```

**Expected output**:
```
tmux 3.3a
```

**If you see "command not found"** → Don't worry, we'll install it in Step 2

---

## Get a $5/month VPS (Skip if you have a server)

If you answered "NO" to Question 2, follow these steps to get a cheap cloud server:

### Option A: Hetzner (Recommended - €4.99/month)

1. **Create account**: Visit https://accounts.hetzner.com/signUp
2. **Add payment method**: Credit card or PayPal
3. **Create server**:
   - Go to Cloud Console
   - Click "Add Server"
   - Location: Choose closest to you
   - Image: **Ubuntu 24.04**
   - Type: **CPX11** (2 vCPU, 2GB RAM, €4.99/mo)
   - SSH Key: Add your public key (see below)
   - Name: `claude-agent-1`
   - Click "Create & Buy Now"

4. **Wait 1 minute** for server to provision
5. **Note your server IP address** (shown in dashboard)

### Option B: DigitalOcean ($6/month)

1. **Create account**: Visit https://cloud.digitalocean.com/registrations/new
2. **Add payment method**: Credit card (get $200 free credit with referral)
3. **Create Droplet**:
   - Click "Create" → "Droplets"
   - Image: **Ubuntu 24.04 LTS**
   - Plan: **Basic** → **Regular** ($6/mo, 1GB RAM)
   - Add SSH key (see below)
   - Hostname: `claude-agent-1`
   - Click "Create Droplet"

4. **Wait 1 minute** for droplet to provision
5. **Note your droplet IP address** (shown in dashboard)

### Option C: OVHCloud ($5-8/month)

1. **Create account**: Visit https://us.ovhcloud.com/manager/
2. **Create Public Cloud project**
3. **Create instance**:
   - Go to "Instances" → "Create an instance"
   - Select: **s1-4** (1 vCPU, 4GB RAM, ~$8/mo)
   - Image: **Ubuntu 24.04**
   - Add SSH key (see below)
   - Name: `claude-agent-1`

4. **Note your instance IP address**

---

### Generate SSH Key (If you don't have one)

**On your local machine** (Mac/Linux):
```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "your-email@example.com"

# Press Enter for all prompts (use defaults)

# Copy your public key
cat ~/.ssh/id_ed25519.pub
```

**Expected output** (copy this entire line):
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGqW... your-email@example.com
```

**Paste this public key** when creating your VPS server.

---

## Step 1: Connect to Your Server

**Connect via SSH**:
```bash
# Replace with your actual server IP
ssh root@YOUR_SERVER_IP
```

**Expected output**:
```
Welcome to Ubuntu 24.04 LTS (GNU/Linux 6.8.0-40-generic x86_64)
root@server:~#
```

**If you get "Permission denied"**:
- Check that your SSH key was added during server creation
- Try: `ssh -i ~/.ssh/id_ed25519 root@YOUR_SERVER_IP`

---

## Step 2: Install Dependencies (10 minutes)

Now we'll install everything needed to run Claude Code agents. Copy and paste each command block.

### 2.1: Update System (2 minutes)

```bash
# Update package lists and upgrade existing packages
apt update && apt upgrade -y
```

**Expected output** (last few lines):
```
Reading package lists... Done
Building dependency tree... Done
0 upgraded, 0 newly installed, 0 to remove and 0 not upgraded.
```

---

### 2.2: Install Essential Tools (3 minutes)

```bash
# Install tmux (session persistence), git, and other essentials
apt install -y tmux git curl wget vim htop
```

**Expected output** (last few lines):
```
Setting up tmux (3.3a-3ubuntu1) ...
Processing triggers for man-db (2.12.0-3) ...
```

**Verify installation**:
```bash
tmux -V
git --version
```

**Expected output**:
```
tmux 3.3a
git version 2.43.0
```

---

### 2.3: Install Node.js 20.x (3 minutes)

```bash
# Add NodeSource repository for Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -

# Install Node.js and npm
apt install -y nodejs
```

**Expected output** (last few lines):
```
Setting up nodejs (20.11.0-1nodesource1) ...
```

**Verify installation**:
```bash
node --version
npm --version
```

**Expected output**:
```
v20.11.0
10.2.4
```

---

### 2.4: Install Claude Code CLI (2 minutes)

```bash
# Install Claude Code globally
npm install -g @anthropic-ai/claude-code
```

**Expected output** (last few lines):
```
added 145 packages in 8s
```

**Verify installation**:
```bash
claude --version
```

**Expected output**:
```
2.5.0
```

**If you see "command not found"**:
```bash
# Add npm global binaries to PATH
export PATH="/usr/local/bin:$PATH"
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Try again
claude --version
```

---

## Step 3: Configure Authentication (2 minutes)

Choose one method based on what you have:

### Method A: API Key (Recommended for beginners)

**Set your API key**:
```bash
# Replace with your actual API key from console.anthropic.com
export ANTHROPIC_API_KEY="sk-ant-your-key-here"

# Make it permanent (survives reboots)
echo 'export ANTHROPIC_API_KEY="sk-ant-your-key-here"' >> ~/.bashrc
```

**Verify it's set**:
```bash
echo $ANTHROPIC_API_KEY | wc -c
```

**Expected output** (should be around 108 characters):
```
108
```

**Test API key**:
```bash
# Send a test request
curl -X POST https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{"model":"claude-3-5-sonnet-20241022","max_tokens":10,"messages":[{"role":"user","content":"test"}]}'
```

**Expected output** (success):
```json
{"id":"msg_...","type":"message","role":"assistant","content":[{"type":"text","text":"Test"}],...}
```

**If you see authentication_error**:
- Double-check your API key at https://console.anthropic.com/settings/keys
- Make sure you copied the entire key including `sk-ant-`
- Verify billing is set up in your Anthropic account

---

### Method B: Max Plan Login (If you have a subscription)

**Login to Claude**:
```bash
claude login
```

**Expected output**:
```
Opening browser to authenticate...
Paste the URL in your browser: https://...
```

1. Open the URL in your browser
2. Login with your claude.ai credentials
3. Authorize the CLI
4. Return to terminal

**Verify authentication**:
```bash
claude -p "Hello, Claude! Can you confirm you're working?"
```

---

## Step 4: Create Your First Project (1 minute)

**Set up project directory**:
```bash
# Create a project folder
mkdir -p ~/projects/my-first-agent
cd ~/projects/my-first-agent

# Initialize git (Claude Code requires git)
git config --global user.email "you@example.com"
git config --global user.name "Your Name"
git init
```

**Expected output**:
```
Initialized empty Git repository in /root/projects/my-first-agent/.git/
```

---

## Step 5: Launch Your First Agent (5 minutes)

Now for the exciting part - let's launch your first autonomous agent!

### 5.1: Start Agent in tmux

**Launch agent**:
```bash
# Start a new tmux session with an agent
tmux new -s my-first-agent

# Inside tmux, start Claude Code
claude -p "Create a simple Node.js web server that responds with 'Hello from Claude!' on port 3000. Write the code, create package.json, and explain how to run it."
```

**What you'll see**:
```
Claude Code Agent - Interactive Mode
Working directory: /root/projects/my-first-agent
Model: claude-sonnet-4-5

Task: Create a simple Node.js web server...

[Agent will start working on the task]
```

**The agent will**:
1. Create `server.js` with the web server code
2. Create `package.json` with dependencies
3. Explain how to run the server

**Let it work for 2-3 minutes**. You'll see it thinking, writing code, and testing.

---

### 5.2: Detach from Session (Agent Keeps Running!)

This is the magic of tmux - you can disconnect and the agent keeps working!

**To detach** (leave agent running):
```
Press: Ctrl+b, then press: d
```

**Expected output**:
```
[detached (from session my-first-agent)]
root@server:~#
```

**Your agent is now running in the background!** You can disconnect from SSH and it continues working.

---

### 5.3: Reconnect to Your Agent

**List active sessions**:
```bash
tmux ls
```

**Expected output**:
```
my-first-agent: 1 windows (created Wed Oct 21 14:30:15 2025)
```

**Reattach to agent**:
```bash
tmux attach -t my-first-agent
```

**You're back!** You'll see everything the agent has done while you were away.

**To detach again**: Press `Ctrl+b` then `d`

---

### 5.4: Test Your Web Server

Once the agent finishes, test the web server it created:

**Run the server**:
```bash
# First, detach from the Claude session (Ctrl+b, d)
# Then run the server
cd ~/projects/my-first-agent
node server.js
```

**Expected output**:
```
Server running on http://localhost:3000
```

**Test it** (in another terminal or SSH session):
```bash
curl http://localhost:3000
```

**Expected output**:
```
Hello from Claude!
```

**Congratulations!** You just ran your first autonomous agent that built a working application!

---

## Step 6: Advanced - Run Agent 24/7

Want your agent to run continuously, even after you disconnect from SSH?

### 6.1: Create a Long-Running Task

**Create a new session**:
```bash
tmux new -s continuous-agent
```

**Start agent with continuous task**:
```bash
claude -p "Monitor this project and suggest improvements. Check for code quality issues, missing tests, documentation gaps, and security concerns. Provide actionable suggestions."
```

**Detach**: Press `Ctrl+b` then `d`

**Your agent now runs 24/7!**

---

### 6.2: Monitor Your Agent

**Check agent status**:
```bash
# List all running sessions
tmux ls

# View agent output without attaching
tmux capture-pane -pt continuous-agent | tail -20
```

**Monitor system resources**:
```bash
# Check CPU and memory usage
htop
```

**Expected to see**:
- Node processes running
- 1-2 CPU cores being used
- 1-1.5GB RAM per agent

---

## Common Issues & Solutions

### Issue 1: "command not found: claude"

**Solution**:
```bash
# Ensure npm global binaries are in PATH
export PATH="/usr/local/bin:$PATH"
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Verify
which claude
```

**Expected**: `/usr/local/bin/claude`

---

### Issue 2: "authentication_error" from API

**Solution**:
```bash
# Check API key is set
echo $ANTHROPIC_API_KEY

# If empty, set it again
export ANTHROPIC_API_KEY="sk-ant-your-key-here"
echo 'export ANTHROPIC_API_KEY="sk-ant-your-key-here"' >> ~/.bashrc

# Verify it works
curl -X POST https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{"model":"claude-3-5-sonnet-20241022","max_tokens":10,"messages":[{"role":"user","content":"hi"}]}'
```

---

### Issue 3: Agent Crashes or Exits

**Check what happened**:
```bash
# Reattach to see error
tmux attach -t my-first-agent

# Check system resources
free -h
df -h
```

**Common causes**:
- Out of memory (upgrade to 2GB+ VPS)
- Out of disk space (clean up with `apt clean`)
- API rate limit hit (wait 1 minute, try again)

---

### Issue 4: Can't Detach from tmux

**Correct detach sequence**:
1. Press and hold `Ctrl`
2. While holding `Ctrl`, press `b`
3. Release both keys
4. Press `d`

**Alternative**: Type `Ctrl+b` then `:` then type `detach` and press Enter

---

### Issue 5: Lost tmux Session After Reboot

**Check if running**:
```bash
tmux ls
```

**If no sessions**:
- Sessions are lost on server reboot
- See "Advanced Topics" below for auto-restart setup

---

## Quick Reference

### Essential tmux Commands

```bash
# Create new session
tmux new -s session-name

# Detach from session
Ctrl+b, then d

# List sessions
tmux ls

# Attach to session
tmux attach -t session-name

# Kill session
tmux kill-session -t session-name

# Rename current session
Ctrl+b, then :rename-session new-name
```

---

### Essential Claude Commands

```bash
# Start interactive agent
claude

# Start with prompt
claude -p "Your task here"

# Check version
claude --version

# View help
claude --help

# Login (for Max Plan)
claude login
```

---

## What's Next?

### Learn More

Now that you have a working agent, explore these guides:

1. **[00-getting-started.md](00-getting-started.md)** - Choose a learning path
2. **[02-tmux-setup.md](02-tmux-setup.md)** - Master tmux for agent management
3. **[04-claude-configuration.md](04-claude-configuration.md)** - Configure autonomous behavior
4. **[05-cost-optimization.md](05-cost-optimization.md)** - Reduce API costs by 90%
5. **[06-security.md](06-security.md)** - Secure your server

---

### Try These Next

**Run multiple agents in parallel**:
```bash
# Agent 1: Frontend work
tmux new -d -s frontend "cd ~/projects/frontend && claude -p 'Build a React dashboard'"

# Agent 2: Backend work
tmux new -d -s backend "cd ~/projects/backend && claude -p 'Create REST API'"

# Agent 3: Testing
tmux new -d -s tests "cd ~/projects/tests && claude -p 'Write comprehensive tests'"

# View all agents
tmux ls
```

**Setup mobile access** (code from your phone):
- See [03-remote-access.md](03-remote-access.md) for Tailscale + Mosh setup

**Reduce costs by 90%**:
- Enable prompt caching
- Use Haiku for simple tasks
- See [05-cost-optimization.md](05-cost-optimization.md)

---

## Cost Tracking

### Estimate Your Costs

**API Key (Pay-per-use)**:
- Simple task (5 min): ~$0.10-0.30
- Medium task (30 min): ~$0.50-1.50
- Complex task (2 hours): ~$2-5
- 24/7 agent (continuous): ~$10-50/day

**Max Plan Subscription**:
- $100/month flat rate
- ~225 messages per 5 hours
- Shared across all agents
- Best for: 5-10 agents with moderate usage

**Check your usage**:
- API Key: https://console.anthropic.com/settings/usage
- Max Plan: Monitor message counts in terminal output

---

## Success Checklist

After completing this guide, you should have:

- [ ] VPS server running (Hetzner/DigitalOcean/OVHCloud)
- [ ] SSH access working
- [ ] Node.js 20.x installed
- [ ] tmux installed and working
- [ ] Claude Code CLI installed
- [ ] API key or Max Plan authentication configured
- [ ] First agent successfully ran a task
- [ ] Can detach/reattach to tmux sessions
- [ ] Understand basic tmux commands
- [ ] Web server example working

**All checked?** You're ready to build autonomous agent systems!

---

## Support & Resources

### Documentation
- **Main guide**: [README.md](README.md)
- **Learning paths**: [00-getting-started.md](00-getting-started.md)
- **Troubleshooting**: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

### Get Help
- Claude Code issues: https://github.com/anthropics/claude-code/issues
- Community: Twitter/X #ClaudeCode #vibecoding

### Cost Calculators
- Anthropic pricing: https://www.anthropic.com/pricing
- Token calculator: Track tokens in agent output

---

## Advanced Topics (Optional)

### Auto-Restart Agents on Reboot

**Create systemd service**:
```bash
# Create service file
sudo nano /etc/systemd/system/claude-agent.service
```

**Add this content**:
```ini
[Unit]
Description=Claude Code Continuous Agent
After=network.target

[Service]
Type=forking
User=root
WorkingDirectory=/root/projects/my-first-agent
Environment="ANTHROPIC_API_KEY=sk-ant-your-key"
ExecStart=/usr/bin/tmux new-session -d -s claude-agent "claude -p 'Your continuous task'"
ExecStop=/usr/bin/tmux kill-session -t claude-agent
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

**Enable and start**:
```bash
sudo systemctl daemon-reload
sudo systemctl enable claude-agent
sudo systemctl start claude-agent

# Check status
sudo systemctl status claude-agent
```

---

### Monitor Costs in Real-Time

**Create cost monitoring script**:
```bash
cat > ~/monitor-costs.sh <<'EOF'
#!/bin/bash
while true; do
    echo "=== Cost Estimate ==="
    echo "Check actual usage: https://console.anthropic.com/settings/usage"
    echo "Current time: $(date)"
    echo ""
    sleep 300  # Check every 5 minutes
done
EOF

chmod +x ~/monitor-costs.sh

# Run in tmux
tmux new -d -s cost-monitor "~/monitor-costs.sh"
```

---

### Setup Automatic Backups

**Create backup script**:
```bash
cat > ~/backup.sh <<'EOF'
#!/bin/bash
BACKUP_DIR=~/backups
DATE=$(date +%Y%m%d-%H%M%S)
mkdir -p $BACKUP_DIR

# Backup projects
tar -czf "$BACKUP_DIR/projects-$DATE.tar.gz" ~/projects/

# Keep only last 7 days
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "Backup completed: $DATE"
EOF

chmod +x ~/backup.sh

# Run daily at 3 AM
(crontab -l 2>/dev/null; echo "0 3 * * * ~/backup.sh") | crontab -
```

---

## Congratulations!

You now have a continuously running Claude Code agent on a cloud server!

**What you learned**:
- How to provision a cheap VPS ($5/month)
- Installing Node.js and Claude Code CLI
- Configuring authentication (API key or Max Plan)
- Using tmux for session persistence
- Running autonomous agents 24/7
- Detaching and reattaching to sessions
- Basic troubleshooting

**Time to build**: Start with simple tasks and gradually increase complexity. Your agents can now work for you 24/7!

---

**Ready for more?** → [00-getting-started.md](00-getting-started.md) - Choose your learning path

**Questions?** → [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues and solutions