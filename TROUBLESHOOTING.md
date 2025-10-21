# Troubleshooting Guide: Continuous Claude Code Agents on OVHCloud

> Comprehensive troubleshooting guide for common issues when running Claude Code agents on OVHCloud infrastructure.

**Last Updated**: October 21, 2025
**Tested On**: OVHCloud Public Cloud, Ubuntu 24.04 LTS

---

## Table of Contents

1. [Connection Issues](#connection-issues)
2. [Installation Problems](#installation-problems)
3. [Agent Issues](#agent-issues)
4. [Performance Problems](#performance-problems)
5. [tmux Issues](#tmux-issues)
6. [API and Authentication](#api-and-authentication)
7. [Multi-Agent Coordination](#multi-agent-coordination)
8. [Production Environment](#production-environment)
9. [Cost and Billing](#cost-and-billing)
10. [Emergency Procedures](#emergency-procedures)

---

## Connection Issues

### Cannot SSH to OVHCloud Instance

**Symptoms**:
```
ssh: connect to host X.X.X.X port 22: Connection refused
# or
ssh: connect to host X.X.X.X port 22: Connection timed out
```

**Diagnosis**:
```bash
# Test if host is reachable
ping YOUR_INSTANCE_IP

# Check SSH with verbose output
ssh -v ubuntu@YOUR_INSTANCE_IP

# Check if port 22 is open
nmap -p 22 YOUR_INSTANCE_IP
```

**Solutions**:

1. **Verify instance is running** in OVHCloud console
2. **Check security group/firewall rules** allow SSH (port 22)
3. **Verify SSH key is correct**:
   ```bash
   # Check which key SSH is trying to use
   ssh -v ubuntu@YOUR_INSTANCE_IP 2>&1 | grep "identity file"

   # Try with explicit key
   ssh -i ~/.ssh/id_ed25519 ubuntu@YOUR_INSTANCE_IP
   ```
4. **Check UFW firewall on server** (if you can access via console):
   ```bash
   sudo ufw status
   sudo ufw allow ssh
   sudo ufw reload
   ```
5. **Try password authentication** (if enabled):
   ```bash
   ssh -o PasswordAuthentication=yes ubuntu@YOUR_INSTANCE_IP
   ```

### SSH Connection Drops Frequently

**Symptoms**:
- Connection drops after a few minutes of inactivity
- "Write failed: Broken pipe" error

**Solutions**:

```bash
# On your local machine, add to ~/.ssh/config:
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3

# Or connect with keep-alive:
ssh -o ServerAliveInterval=60 ubuntu@YOUR_INSTANCE_IP

# Better solution: Use Mosh instead of SSH
sudo apt install mosh
mosh ubuntu@YOUR_INSTANCE_IP
```

### Firewall Blocking Connections

**Symptoms**:
- Can SSH but can't access Mosh or web services
- Specific ports timing out

**Solutions**:

```bash
# Check current firewall rules
sudo ufw status verbose

# Allow Mosh (ports 60000-61000)
sudo ufw allow 60000:61000/udp

# Allow specific port (e.g., web server)
sudo ufw allow 8080/tcp

# Reload firewall
sudo ufw reload

# If completely locked out, reset UFW (via console):
sudo ufw --force reset
sudo ufw allow ssh
sudo ufw enable
```

---

## Installation Problems

### Node.js Installation Fails

**Symptoms**:
```
Failed to fetch https://deb.nodesource.com/...
# or
node: command not found
```

**Solutions**:

```bash
# Remove existing Node.js installations
sudo apt remove nodejs npm
sudo apt autoremove

# Clear package cache
sudo apt clean
sudo apt update

# Install Node.js manually
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Verify
node --version
npm --version

# If still failing, use alternative method (nvm):
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install 20
nvm use 20
```

### Claude Code CLI Installation Fails

**Symptoms**:
```
npm ERR! code EACCES
# or
npm ERR! permission denied
# or
claude: command not found
```

**Solutions**:

```bash
# Check npm permissions
npm config get prefix
# Should be /usr or /usr/local

# Fix npm permissions (if needed)
sudo chown -R $(whoami) ~/.npm

# Install with correct permissions
sudo npm install -g @anthropic-ai/claude-code

# Verify installation
which claude
claude --version

# If PATH issue:
echo $PATH
# Add to ~/.bashrc if needed:
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Alternative: Install without sudo (local)
npm install -g --prefix ~/.local @anthropic-ai/claude-code
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Package Dependencies Missing

**Symptoms**:
```
dpkg: dependency problems
# or
The following packages have unmet dependencies
```

**Solutions**:

```bash
# Fix broken dependencies
sudo apt --fix-broken install

# Update package lists
sudo apt update

# Upgrade packages
sudo apt upgrade

# If specific package is problematic:
sudo dpkg --configure -a
sudo apt install -f

# Clean and retry
sudo apt clean
sudo apt autoremove
sudo apt update
sudo apt install <package-name>
```

---

## Agent Issues

### Agent Won't Start

**Symptoms**:
- `claude` command hangs
- No output when running agent
- Error messages immediately

**Diagnosis**:
```bash
# Check if Claude is installed
which claude
claude --version

# Check if API key is set
echo $ANTHROPIC_API_KEY

# Test Claude directly
claude -p "test"

# Check system resources
free -h
df -h
```

**Solutions**:

1. **API key not set**:
   ```bash
   export ANTHROPIC_API_KEY="sk-ant-api03-..."
   echo 'export ANTHROPIC_API_KEY="sk-ant-..."' >> ~/.bashrc
   source ~/.bashrc
   ```

2. **Insufficient memory**:
   ```bash
   # Check available memory
   free -h

   # Kill other processes if needed
   pkill -f claude

   # Add swap if very low memory
   sudo fallocate -l 2G /swapfile
   sudo chmod 600 /swapfile
   sudo mkswap /swapfile
   sudo swapon /swapfile
   ```

3. **Corrupted installation**:
   ```bash
   sudo npm uninstall -g @anthropic-ai/claude-code
   sudo npm install -g @anthropic-ai/claude-code
   ```

### Agent Stops Working Mid-Task

**Symptoms**:
- Agent hangs or freezes
- No response to input
- Process still running but unresponsive

**Solutions**:

```bash
# Check if process is actually running
ps aux | grep claude

# Check system logs
tail -f ~/agents/logs/*.log

# Check for OOM (out of memory) kills
dmesg | grep -i "out of memory"

# If hung, kill and restart
tmux kill-session -t agent-name
bash ~/scripts/setup/start-agent.sh

# If frequent hangs, check for:
# 1. Infinite loops in logs
tail -f ~/agents/logs/*.log | grep -E "error|loop|retry"

# 2. Rate limiting
# Look for "rate_limit_error" in logs

# 3. Network issues
ping api.anthropic.com
```

### Agent Creates Invalid Code

**Symptoms**:
- Syntax errors in generated code
- Code doesn't run
- Unexpected behavior

**Solutions**:

This is an AI behavior issue, not a technical problem. Best practices:

1. **Be more specific in prompts**:
   ```bash
   # Instead of: "write a function"
   # Use: "write a Python function named calculate_sum that takes two integers and returns their sum"
   ```

2. **Use iterative refinement**:
   ```bash
   # Review code, then ask:
   "The function has a bug on line 5. Please fix the off-by-one error."
   ```

3. **Provide context**:
   ```bash
   "This is a Node.js project using TypeScript. Use async/await for API calls."
   ```

4. **Switch models** for different tasks:
   - Haiku: Simple, fast tasks
   - Sonnet: Most tasks (default)
   - Opus: Complex reasoning

---

## Performance Problems

### High CPU Usage

**Symptoms**:
- CPU at 100%
- System slow/unresponsive
- Fan noise (if physical machine)

**Diagnosis**:
```bash
# Check CPU usage
htop
# Look for process consuming CPU

# Check per-process
ps aux --sort=-%cpu | head -10

# Check system load
uptime
```

**Solutions**:

```bash
# Identify CPU-heavy process
top -bn1 | grep claude

# If agent is the culprit:
# 1. Check for infinite loops
tail -f ~/agents/logs/*.log | grep -i "loop\|retry\|error"

# 2. Reduce parallel agents
# Kill some agents:
tmux kill-session -t agent-3
tmux kill-session -t agent-4

# 3. Upgrade instance
# Go to OVHCloud console and resize to larger instance

# 4. Limit agent activity
# Add delays between operations in agent scripts
```

### High Memory Usage

**Symptoms**:
```
Cannot allocate memory
# or
OOMKilled (in logs)
```

**Diagnosis**:
```bash
# Check memory usage
free -h

# Check which process is using memory
ps aux --sort=-%mem | head -10

# Check OOM killer logs
dmesg | tail -50 | grep -i "oom"
```

**Solutions**:

```bash
# 1. Add swap space
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Make permanent
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# 2. Reduce agent count
# Kill unnecessary agents
for i in {3..5}; do tmux kill-session -t agent-$i; done

# 3. Reduce tmux scrollback buffer
# Add to ~/.tmux.conf:
echo "set-option -g history-limit 5000" >> ~/.tmux.conf
tmux source-file ~/.tmux.conf

# 4. Clear logs
find ~/agents/logs -name "*.log" -exec truncate -s 0 {} \;

# 5. Upgrade instance (best solution)
# Resize to b2-15 (15GB RAM) or b2-30 (30GB RAM)
```

### Disk Space Full

**Symptoms**:
```
No space left on device
# or
Disk quota exceeded
```

**Diagnosis**:
```bash
# Check disk usage
df -h

# Find large directories
du -h ~ | sort -rh | head -20

# Find large files
find ~ -type f -size +100M -exec ls -lh {} \;
```

**Solutions**:

```bash
# 1. Clean logs
find ~/agents/logs -name "*.log" -mtime +7 -delete

# 2. Clean backups
find ~/backups -name "*.tar.gz" -mtime +30 -delete

# 3. Clean npm cache
npm cache clean --force

# 4. Clean apt cache
sudo apt clean
sudo apt autoremove

# 5. Clean tmux resurrection (if using)
rm -rf ~/.tmux/resurrect/*

# 6. Identify and remove large files
du -sh ~/.npm ~/.cache
rm -rf ~/.npm ~/.cache

# 7. Check for log rotation
# Make sure logrotate is working:
sudo logrotate -f /etc/logrotate.d/claude-agent
```

### Slow Network / API Calls

**Symptoms**:
- Agent responses very slow
- Timeouts
- Long wait times

**Diagnosis**:
```bash
# Test network speed
curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -

# Test Anthropic API latency
time curl -X POST https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{"model":"claude-3-5-sonnet-20241022","max_tokens":10,"messages":[{"role":"user","content":"Hi"}]}'

# Check DNS
dig api.anthropic.com
```

**Solutions**:

```bash
# 1. Check for rate limiting
# Look in logs for "rate_limit_error"

# 2. Use a different region
# If API is slow, consider switching OVHCloud region

# 3. Enable prompt caching
# See 05-cost-optimization.md for details

# 4. Check for network issues on instance
# Restart networking
sudo systemctl restart systemd-networkd

# 5. Use Haiku model for simple tasks (faster)
# In your agent prompts, specify model if supported
```

---

## tmux Issues

### Cannot Attach to Session

**Symptoms**:
```
no sessions
# or
session not found: agent-name
```

**Solutions**:

```bash
# List all sessions
tmux ls

# If session exists but can't attach:
tmux attach -d -t agent-name

# If session is attached elsewhere, force detach
tmux attach -dt agent-name

# If no sessions found, start a new one
bash ~/scripts/setup/start-agent.sh
```

### tmux Session Disappeared

**Symptoms**:
- Session was running, now it's gone
- `tmux ls` shows no sessions

**Diagnosis**:
```bash
# Check if tmux server is running
ps aux | grep tmux

# Check system logs for crashes
dmesg | tail -50

# Check for OOM kills
dmesg | grep -i "oom"
```

**Solutions**:

```bash
# 1. Restart tmux server
pkill tmux
tmux new -s test

# 2. Check for socket issues
rm -rf /tmp/tmux-*
ls -la /tmp/tmux-*

# 3. Use systemd for persistence (Production setup)
sudo systemctl enable claude-agent
sudo systemctl start claude-agent

# 4. Use tmux-resurrect plugin
# Add to ~/.tmux.conf:
# set -g @plugin 'tmux-plugins/tmux-resurrect'
```

### tmux Pane Sizes Wrong

**Symptoms**:
- Panes have wrong dimensions
- Text wrapping incorrectly

**Solutions**:

```bash
# Inside tmux, force resize
Ctrl+b, then :
# Type: resize-pane
# Press Enter

# Reset layout
Ctrl+b, then Alt+1  # even-horizontal
Ctrl+b, then Alt+2  # even-vertical
Ctrl+b, then Alt+5  # tiled

# If connecting from different terminal sizes
# Detach all other clients first:
tmux attach -d
```

### tmux Commands Not Working

**Symptoms**:
- Ctrl+b commands don't work
- Can't detach or switch windows

**Solutions**:

```bash
# Check if tmux config is valid
tmux source-file ~/.tmux.conf

# If config has errors, it will show them

# Reset to default config
mv ~/.tmux.conf ~/.tmux.conf.backup
tmux kill-server
tmux new -s test

# Re-copy config
cp ~/config/.tmux.conf ~/.tmux.conf
```

---

## API and Authentication

### Invalid API Key Error

**Symptoms**:
```
authentication_error: Invalid API key
# or
401 Unauthorized
```

**Solutions**:

```bash
# 1. Verify API key is set correctly
echo $ANTHROPIC_API_KEY
# Should output: sk-ant-api03-...

# 2. Check for extra spaces or newlines
echo "$ANTHROPIC_API_KEY" | wc -c
# Should be around 108 characters

# 3. Regenerate API key
# Go to: https://console.anthropic.com/settings/keys
# Create new key, delete old one

# 4. Update in multiple places
# ~/.bashrc
nano ~/.bashrc
# Find and update export ANTHROPIC_API_KEY="..."

# systemd service (if using)
sudo nano /etc/systemd/system/claude-agent.service
# Update Environment="ANTHROPIC_API_KEY=..."
sudo systemctl daemon-reload
sudo systemctl restart claude-agent

# 5. Test API key manually
curl -X POST https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{"model":"claude-3-5-sonnet-20241022","max_tokens":100,"messages":[{"role":"user","content":"Hello"}]}'
```

### Rate Limit Errors

**Symptoms**:
```
rate_limit_error: Request rate too high
# or
429 Too Many Requests
```

**Solutions**:

```bash
# 1. Check your rate limits
# See: https://console.anthropic.com/settings/limits

# 2. Upgrade subscription tier
# Pro: 50 req/min
# Max: 1000+ req/min
# Go to: https://console.anthropic.com/settings/plans

# 3. Reduce parallel agents
# Kill some agents:
for i in {6..10}; do tmux kill-session -t agent-$i; done

# 4. Add exponential backoff
# Edit your agent scripts to retry with delays

# 5. Stagger agent starts
# In spawn-agents.sh, increase STAGGER_DELAY:
STAGGER_DELAY=10  # seconds between spawns

# 6. Monitor rate limits
# Check logs for patterns
grep -i "rate.*limit" ~/agents/logs/*.log | wc -l
```

### API Connection Timeouts

**Symptoms**:
```
Connection timeout
# or
Request timeout after 60000ms
```

**Solutions**:

```bash
# 1. Check network connectivity
ping api.anthropic.com
curl -I https://api.anthropic.com

# 2. Check DNS
nslookup api.anthropic.com
# Try alternative DNS
sudo nano /etc/resolv.conf
# Add: nameserver 8.8.8.8

# 3. Increase timeout in agent scripts
# (This depends on how you're calling the API)

# 4. Check firewall isn't blocking HTTPS
sudo ufw status | grep 443

# 5. Try from different network/region
# Consider moving to different OVHCloud region
```

---

## Multi-Agent Coordination

### Agents Fighting Over Same File

**Symptoms**:
- Git merge conflicts
- Agents overwriting each other's work
- Lock file errors
- Multiple agents editing same file simultaneously

**Diagnosis**:
```bash
# Check active work
source ~/scripts/coordination/agent-coordination.sh
check_active_work

# Check for duplicate file claims
jq '.[] | .file' ~/agents/coordination/active-work.json | sort | uniq -d

# Verify coordination directory structure
ls -la ~/agents/coordination/
# Should contain: active-work.json, completed-work.json, planned-work.json, agent-locks/

# Check git status for conflicts
cd ~/projects/main
git status | grep -i "conflict"
```

**Solutions**:

```bash
# 1. Verify coordination is initialized
source ~/scripts/coordination/agent-coordination.sh
init_coordination

# 2. Check for stale locks
check_stale_agents

# 3. Clean up stale locks (older than 30 minutes)
cleanup_stale_agents

# 4. Manually release a file
release_work "agent-3" "src/file.ts"

# 5. Resolve git merge conflicts
cd ~/projects/main
git status
# Edit conflicting files manually
git add <resolved-files>
git commit -m "fix: resolve multi-agent merge conflicts"

# 6. Restart coordination system (last resort)
rm -rf ~/agents/coordination/*
source ~/scripts/coordination/agent-coordination.sh
init_coordination
# Re-add tasks to planned-work.json
```

**Prevention**:
```bash
# Use coordination protocol for all multi-agent setups
# See: 02-tmux-setup.md:640-816

# Launch agents with coordination enabled
bash ~/scripts/coordination/launch-agent-team.sh 5

# Monitor coordination dashboard
tmux attach -t agent-dashboard
```

### Git Merge Conflicts from Multi-Agent Work

**Symptoms**:
```
CONFLICT (content): Merge conflict in src/file.ts
Automatic merge failed; fix conflicts and then commit the result.
```

**Solutions**:

```bash
# 1. Identify which agents caused conflict
git log --oneline --graph --all | head -20

# 2. Check active-work.json for concurrent edits
jq '.[] | select(.file == "src/file.ts")' ~/agents/coordination/active-work.json

# 3. Resolve conflicts manually
cd ~/projects/main
git status
# Edit files, keep desired changes

# 4. Mark as resolved
git add <conflicted-files>
git commit -m "fix: resolve conflict in src/file.ts"

# 5. Update coordination to prevent recurrence
# Add file to exclusive-lock list if needed
# See coordination protocol in 02-tmux-setup.md:640-816
```

### Lock File Errors

**Symptoms**:
```
Error: File is locked by agent-2
# or
Cannot claim work: file already locked
# or
jq: error: Lock file exists
```

**Diagnosis**:
```bash
# Check all lock files
ls -la ~/agents/coordination/agent-locks/

# Check which agent owns each lock
for lock in ~/agents/coordination/agent-locks/*.lock; do
    echo "Lock: $lock"
    cat "$lock"
done

# Check if locked agent is still running
tmux ls | grep agent-2
ps aux | grep "agent-2"

# Check lock timestamps
find ~/agents/coordination/agent-locks/ -name "*.lock" -exec ls -lh {} \;
```

**Solutions**:

```bash
# 1. If agent crashed, remove stale lock
source ~/scripts/coordination/agent-coordination.sh
cleanup_stale_agents

# 2. Manually remove specific lock (if agent is dead)
# First verify agent is not running:
tmux ls | grep agent-2
# If not running:
rm ~/agents/coordination/agent-locks/agent-2.lock

# 3. Force release work
source ~/scripts/coordination/agent-coordination.sh
# Edit active-work.json to remove entry
jq 'map(select(.agent != "agent-2"))' ~/agents/coordination/active-work.json > tmp.json
mv tmp.json ~/agents/coordination/active-work.json

# 4. Clear all locks (emergency only)
rm -rf ~/agents/coordination/agent-locks/*
echo "[]" > ~/agents/coordination/active-work.json

# 5. Restart coordination from clean slate
rm -rf ~/agents/coordination/*
source ~/scripts/coordination/agent-coordination.sh
init_coordination
```

### Coordination JSON Diagnostics

**Symptoms**:
```
parse error: Invalid JSON
# or
jq: error: unexpected token at line X, column Y
# or
Expected value but got EOF
```

**Diagnosis**:
```bash
# Validate each JSON file
cd ~/agents/coordination
jq '.' active-work.json
jq '.' completed-work.json
jq '.' planned-work.json

# Check for empty or truncated files
ls -lh ~/agents/coordination/*.json
cat ~/agents/coordination/active-work.json

# Look for JSON syntax errors
python3 -m json.tool active-work.json

# Inspect active-work.json structure
jq '.[] | {agent, file, started}' ~/agents/coordination/active-work.json
```

**Solutions**:

```bash
# 1. Backup current state
cd ~/agents/coordination
mkdir -p ~/backups/coordination-$(date +%Y%m%d-%H%M%S)
cp *.json ~/backups/coordination-$(date +%Y%m%d-%H%M%S)/

# 2. Try to repair JSON
# If file is truncated/empty:
echo "[]" > active-work.json
echo "[]" > completed-work.json

# If file has syntax errors, try manual fix:
nano active-work.json
# Common issues: missing comma, trailing comma, unclosed bracket

# 3. Validate after repair
jq '.' active-work.json
jq '.' completed-work.json
jq '.' planned-work.json

# 4. Remove lock files
rm -rf ~/agents/coordination/agent-locks/*

# 5. Reinitialize coordination
source ~/scripts/coordination/agent-coordination.sh
init_coordination

# 6. Restore from backup (if repair failed)
cp ~/backups/coordination-*/active-work.json.backup active-work.json
# Fix errors manually, then validate
```

### Agents Not Picking Up Tasks

**Symptoms**:
- Tasks in queue but agents idle
- "No tasks available" despite having tasks
- Agents waiting indefinitely

**Diagnosis**:
```bash
source ~/scripts/coordination/agent-coordination.sh

# Check planned work
check_planned_work

# Check if tasks are assigned but agents not running
jq '.[] | select(.assigned != null)' ~/agents/coordination/planned-work.json

# Check if files are locked
jq '.[] | .file' ~/agents/coordination/active-work.json

# Verify agents are running coordination script
tmux ls
for i in {1..5}; do
    echo "=== agent-$i ==="
    tmux capture-pane -t agent-$i -p | tail -5
done

# Check coordination statistics
show_stats
```

**Solutions**:

```bash
# 1. Unassign stale tasks
cd ~/agents/coordination
jq 'map(.assigned = null)' planned-work.json > planned-work.json.tmp
mv planned-work.json.tmp planned-work.json

# 2. Verify agent is running coordination-enabled script
tmux attach -t agent-1
# Should see: "Agent agent-1 working on: <file> - <task>"
# If not, agent is running wrong script

# 3. Manually trigger task pick-up
source ~/scripts/coordination/agent-coordination.sh
get_next_task "agent-1"

# 4. Check for priority issues
jq '.[] | {id, priority, assigned}' ~/agents/coordination/planned-work.json
# Ensure high-priority tasks have priority: 1 (lower number = higher priority)

# 5. Restart agents with coordination
for i in {1..5}; do
    tmux kill-session -t agent-$i 2>/dev/null
done
bash ~/scripts/coordination/launch-agent-team.sh 5

# 6. Monitor dashboard to verify agents are working
tmux attach -t agent-dashboard
```

### Coordination Dashboard Not Updating

**Symptoms**:
- Dashboard shows stale data
- Statistics not changing
- Active work count incorrect

**Solutions**:

```bash
# 1. Restart dashboard
tmux kill-session -t agent-dashboard
bash ~/scripts/coordination/agent-dashboard.sh

# 2. Verify coordination files are being updated
watch -n 2 'ls -lh ~/agents/coordination/*.json'

# 3. Check for file permission issues
ls -la ~/agents/coordination/
chmod 644 ~/agents/coordination/*.json
chmod 755 ~/agents/coordination/agent-locks/

# 4. Verify jq is working correctly
source ~/scripts/coordination/agent-coordination.sh
show_stats

# 5. Check for JSON corruption (see section above)
```

### Too Many Agents, System Overloaded

**Symptoms**:
- High CPU usage (>90%)
- High memory usage
- Coordination operations slow
- Lock contention

**Diagnosis**:
```bash
# Check system resources
htop
free -h

# Count active agents
tmux ls | wc -l
jq 'length' ~/agents/coordination/active-work.json

# Check coordination file sizes
du -sh ~/agents/coordination/
```

**Solutions**:

```bash
# 1. Reduce agent count
# Kill highest numbered agents
for i in {6..10}; do
    tmux kill-session -t agent-$i 2>/dev/null
done

# 2. Clean up completed work
# Archive old completions
cd ~/agents/coordination
jq '.[-100:]' completed-work.json > completed-work-recent.json
mv completed-work-recent.json completed-work.json

# 3. Upgrade instance size
# See: 01-infrastructure.md for larger instances

# 4. Optimize coordination polling
# Edit coordinated-agent.sh to increase sleep time:
# sleep 60  # Instead of sleep 10

# 5. Use staggered starts
bash ~/scripts/coordination/launch-agent-team.sh 3
sleep 30
bash ~/scripts/coordination/launch-agent-team.sh 2
```

**Reference**: For detailed coordination protocol implementation, see 02-tmux-setup.md:640-816

---

## Production Environment

### Systemd Service Won't Start

**Symptoms**:
```bash
sudo systemctl start claude-agent
# Job for claude-agent.service failed
```

**Diagnosis**:
```bash
# Check service status
sudo systemctl status claude-agent

# Check logs
sudo journalctl -u claude-agent -n 50

# Check service file syntax
sudo systemd-analyze verify claude-agent.service
```

**Solutions**:

```bash
# 1. Fix API key in service file
sudo nano /etc/systemd/system/claude-agent.service
# Ensure: Environment="ANTHROPIC_API_KEY=sk-ant-..."

# 2. Verify paths are correct
# Check WorkingDirectory exists
ls -la /home/claude-agent/projects/main

# 3. Verify user exists
id claude-agent

# 4. Reload and restart
sudo systemctl daemon-reload
sudo systemctl restart claude-agent

# 5. Check permissions
sudo chown claude-agent:claude-agent /home/claude-agent/ -R

# 6. Test command manually as user
sudo -u claude-agent tmux new-session -d -s test 'claude -p "test"'
```

### Backups Not Running

**Symptoms**:
- No backup files in ~/backups
- Cron job not executing

**Diagnosis**:
```bash
# Check cron jobs
crontab -l

# Check cron logs
grep CRON /var/log/syslog | tail -20

# Test backup script manually
bash ~/scripts/backup-agent.sh
```

**Solutions**:

```bash
# 1. Ensure backup script is executable
chmod +x ~/scripts/backup-agent.sh

# 2. Test script
~/scripts/backup-agent.sh

# 3. Check cron syntax
crontab -e
# Should be: 0 3 * * * /home/claude-agent/scripts/backup-agent.sh

# 4. Check for errors in script
bash -x ~/scripts/backup-agent.sh

# 5. Add logging to script
# Edit ~/scripts/backup-agent.sh
# Add at end:
# echo "Backup completed: $(date)" >> ~/backups/backup.log
```

### Monitoring Alerts Not Working

**Symptoms**:
- No email alerts
- Monitoring not detecting issues

**Solutions**:

```bash
# 1. Check if mail is configured
echo "Test email" | mail -s "Test" your@email.com

# 2. Install mail client if needed
sudo apt install mailutils

# 3. Configure monitoring script
nano ~/scripts/monitoring/monitor-agent.sh
# Add alert logic

# 4. Set up external monitoring
# Use services like UptimeRobot, Pingdom, etc.

# 5. Use Tailscale for notifications
# Configure push notifications via Tailscale
```

---

## Cost and Billing

### Unexpected High Costs

**Symptoms**:
- API bill higher than expected
- Billing alert triggered

**Diagnosis**:
```bash
# Check Anthropic console
# https://console.anthropic.com/settings/usage

# Count API calls in logs
grep -r "API call" ~/agents/logs/*.log | wc -l

# Check for infinite loops
grep -i "retry\|loop" ~/agents/logs/*.log | head -50

# Check number of active agents
tmux ls | wc -l
```

**Solutions**:

```bash
# 1. Enable prompt caching (CRITICAL)
# See: 05-cost-optimization.md

# 2. Reduce agent count
# Kill expensive agents
tmux ls
tmux kill-session -t agent-name

# 3. Switch to Haiku for simple tasks
# Modify agent prompts to use cheaper model

# 4. Set rate limits
# Limit requests per agent per hour

# 5. Pause agents temporarily
for i in {1..10}; do tmux kill-session -t agent-$i; done

# 6. Review logs for waste
# Look for repeated failed operations
tail -f ~/agents/logs/*.log | grep -i "error\|fail"
```

### Subscription Not Applying

**Symptoms**:
- Still hitting rate limits with Max subscription
- Charges show pay-per-use instead of subscription

**Solutions**:

```bash
# 1. Verify subscription is active
# Check: https://console.anthropic.com/settings/plans

# 2. Ensure using correct API key
# Max subscription has its own API key
echo $ANTHROPIC_API_KEY

# 3. Update API key everywhere
# ~/.bashrc
# systemd service
# All agent scripts

# 4. Wait for propagation
# Changes can take 5-10 minutes

# 5. Contact Anthropic support
# If issue persists after 1 hour
```

---

## Emergency Procedures

### Complete System Recovery

**When**: System completely broken, agents not working

```bash
# 1. Stop everything
pkill claude
tmux kill-server
sudo systemctl stop claude-agent

# 2. Backup current state
mkdir ~/emergency-backup-$(date +%Y%m%d)
cp -r ~/agents ~/emergency-backup-$(date +%Y%m%d)/
cp -r ~/projects ~/emergency-backup-$(date +%Y%m%d)/

# 3. Clean coordination
rm -rf ~/agents/coordination/*
rm -rf ~/agents/.sessions/*

# 4. Restart from scratch
source ~/scripts/coordination/agent-coordination.sh
init_coordination

# 5. Start single agent for testing
bash ~/scripts/setup/start-agent.sh test-agent ~/projects/main "test task"

# 6. Verify working
tmux attach -t test-agent

# 7. Scale back up slowly
bash ~/scripts/coordination/spawn-agents.sh 3
```

### Data Loss Recovery

**When**: Lost important code or data

```bash
# 1. Check backups
ls -lh ~/backups/

# 2. Restore latest backup
cd ~/backups
tar -xzf projects-YYYYMMDD-HHMMSS.tar.gz -C ~/

# 3. Check git history
cd ~/projects/main
git log --all --oneline
git reflog  # Shows all commits including "lost" ones

# 4. Recover from git
git checkout <commit-hash>
git checkout -b recovery-branch

# 5. Check tmux logs
grep -r "code" ~/agents/logs/*.log > recovered-code.txt
```

### Instance Completely Locked

**When**: Can't SSH, can't access instance

**Via OVHCloud Console**:

1. Log in to OVHCloud Manager
2. Go to your instance
3. Click "VNC Console" or "Serial Console"
4. Login with your credentials
5. Check what's wrong:
   ```bash
   # Check CPU
   top

   # Check memory
   free -h

   # Check disk
   df -h

   # Check processes
   ps aux | grep claude
   ```
6. Kill problematic processes
7. Restart services
8. If needed, reboot instance from console

### Catastrophic Failure - Fresh Start

**When**: Everything is broken beyond repair

```bash
# 1. Save what you can via OVHCloud console
tar -czf /tmp/emergency-save.tar.gz ~/projects ~/agents/logs

# 2. Download from instance (if possible)
scp ubuntu@YOUR_INSTANCE_IP:/tmp/emergency-save.tar.gz ~/

# 3. Destroy and recreate instance in OVHCloud

# 4. Run full setup again
# Upload scripts
scp -r scripts config ubuntu@NEW_INSTANCE_IP:~/

# Connect and setup
ssh ubuntu@NEW_INSTANCE_IP
sudo -i
bash ~/scripts/setup/01-server-setup.sh

# As agent user
su - claude-agent
bash ~/scripts/setup/02-install-claude.sh

# Restore projects
tar -xzf emergency-save.tar.gz

# Start fresh
bash ~/scripts/setup/start-agent.sh
```

---

## Getting Further Help

### Before Asking for Help

1. **Check logs**:
   ```bash
   tail -100 ~/agents/logs/*.log
   sudo journalctl -u claude-agent -n 100
   dmesg | tail -50
   ```

2. **Document the problem**:
   - Exact error message
   - What you were doing when it happened
   - Steps to reproduce
   - System info: `uname -a`, `free -h`, `df -h`

3. **Try basic troubleshooting**:
   - Restart agent
   - Check API key
   - Check system resources
   - Review recent changes

### Where to Get Help

1. **Documentation**: Review all .md files in this repo
2. **GitHub Issues**: Open issue with problem details
3. **Community**: Follow @levelsio, @ericzakariasson on X/Twitter
4. **Anthropic Support**: For API-specific issues
5. **OVHCloud Support**: For infrastructure issues

### Reporting Bugs

Include in your bug report:
- **Environment**: OS version, Claude Code version, instance type
- **Error message**: Full error text
- **Logs**: Relevant log excerpts
- **Steps to reproduce**: Detailed steps
- **Expected vs actual behavior**
- **Screenshots**: If applicable

---

**Remember**: Most issues are simple configuration problems. Check the basics first (API key, network, resources) before diving into complex debugging.

**Pro tip**: Keep a personal troubleshooting log. When you solve a problem, document it for your future self!

---

**Last Updated**: October 21, 2025
**Maintainer**: renchris
**License**: MIT
