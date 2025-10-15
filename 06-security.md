# Security Best Practices for Continuous Agents

## Overview

Running autonomous AI agents 24/7 requires careful security configuration. This guide covers hardening strategies based on @levelsio's recommendations and community best practices (2025).

## Security Threat Model

### Risks of Continuous Agents

1. **Autonomous Execution**: Agent can run ANY command without approval
2. **Credential Exposure**: API keys, SSH keys, database passwords accessible
3. **Network Exposure**: Server must be accessible remotely
4. **Code Injection**: Malicious prompts could execute harmful commands
5. **Data Exfiltration**: Agent has access to all project files
6. **Resource Abuse**: Runaway processes consuming CPU/memory
7. **Supply Chain**: Dependencies agent installs could be malicious

### Defense in Depth

No single security measure is perfect. Layer multiple defenses:

```
Layer 1: Network security (firewall, fail2ban, Tailscale)
Layer 2: Authentication (key-based SSH, MFA)
Layer 3: Isolation (Docker, dedicated VM)
Layer 4: Permissions (restricted tools, user permissions)
Layer 5: Monitoring (logs, alerts, anomaly detection)
Layer 6: Backups (git, snapshots, checkpoints)
```

## Server Hardening

### 1. SSH Security (@levelsio's Recommendations)

```bash
# Edit SSH config
sudo nano /etc/ssh/sshd_config

# Critical settings:
PasswordAuthentication no          # Disable password auth
PermitRootLogin no                 # Disable root login
PubkeyAuthentication yes           # Only key-based auth
ChallengeResponseAuthentication no # Disable challenge-response
UsePAM yes                         # Use PAM for additional security

# Restart SSH
sudo systemctl restart sshd
```

### 2. Firewall Configuration

```bash
# Basic UFW setup (Ubuntu Firewall)
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH (change port if using non-standard)
sudo ufw allow 22/tcp

# Allow Mosh for mobile access
sudo ufw allow 60000:61000/udp

# Allow HTTP/HTTPS if running web services
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Enable firewall
sudo ufw enable

# Verify
sudo ufw status verbose
```

### 3. fail2ban (Brute Force Protection)

```bash
# Install fail2ban
sudo apt install fail2ban

# Create custom config
sudo nano /etc/fail2ban/jail.local

# Add:
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
findtime = 600

# Start fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Check status
sudo fail2ban-client status sshd
```

### 4. Automatic Security Updates

```bash
# Enable unattended upgrades
sudo apt install unattended-upgrades

sudo dpkg-reconfigure -plow unattended-upgrades

# Configure auto-reboot if needed
sudo nano /etc/apt/apt.conf.d/50unattended-upgrades

# Uncomment:
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "03:00";  # 3 AM
```

### 5. Tailscale for Private Network

```bash
# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Connect to Tailscale network
sudo tailscale up

# Lock down SSH to only Tailscale network
sudo ufw delete allow 22/tcp
sudo ufw allow from 100.64.0.0/10 to any port 22

# Now SSH only works via Tailscale private network
# Public internet cannot access SSH at all
```

### 6. Rate Limiting (nginx/Cloudflare)

If exposing web services:

```nginx
# /etc/nginx/nginx.conf
http {
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;

    server {
        location /api/ {
            limit_req zone=api burst=20 nodelay;
            # ... rest of config
        }
    }
}
```

## Application Security

### 1. API Key Management

```bash
# NEVER commit API keys to git
echo ".env" >> .gitignore
echo "*.key" >> .gitignore
echo "secrets/" >> .gitignore

# Store in environment variables
export ANTHROPIC_API_KEY="sk-ant-..."

# Or use .env file
cat > .env <<EOF
ANTHROPIC_API_KEY=sk-ant-...
OPENAI_API_KEY=sk-proj-...
EOF

chmod 600 .env  # Restrict permissions

# Load in scripts
source .env
```

### 2. Restricted File Access

```bash
# Create dedicated user for agent
sudo adduser claude-agent --disabled-password

# Restrict home directory
chmod 750 /home/claude-agent

# Give agent only access to specific directories
sudo mkdir /workspace
sudo chown claude-agent:claude-agent /workspace
chmod 750 /workspace

# Agent runs as non-root with limited access
```

### 3. Dangerous Mode - Isolation Strategy

The `--dangerously-skip-permissions` flag is risky. Mitigate with isolation:

#### Option A: Docker Container (Recommended)

```dockerfile
# Dockerfile
FROM ubuntu:24.04

RUN apt update && apt install -y nodejs npm git

RUN npm install -g @anthropic-ai/claude-code

# Create non-root user
RUN useradd -m -s /bin/bash agent
USER agent
WORKDIR /home/agent/workspace

# Agent runs in isolated container
# Can't access host filesystem
# Can't affect host system
```

```bash
# Run agent in container with dangerous mode
docker run -it \
    -e ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY \
    -v $(pwd):/home/agent/workspace \
    claude-agent \
    claude --dangerously-skip-permissions
```

Benefits:
✅ Agent isolated from host
✅ Can't damage host system
✅ Easy to destroy and recreate
✅ Safe to use dangerous mode

#### Option B: Dedicated VM

```bash
# Run agent on separate VM
# If agent goes rogue, it only affects this VM
# Host system remains safe
```

#### Option C: Restricted Bash Commands

```bash
# Create wrapper that blocks dangerous commands
# ~/.bash_profile or ~/.bashrc for claude-agent user

# Override dangerous commands
alias rm='rm -i'  # Always ask confirmation
alias dd='echo "dd is disabled"'
alias mkfs='echo "mkfs is disabled"'

# Block shell bombs
ulimit -u 100  # Limit max processes
```

### 4. Tool Allowlisting

Instead of `--dangerously-skip-permissions`, use allowlisting:

```json
// .claude/config.json
{
  "allowedTools": [
    "read",
    "write",
    "edit",
    "grep",
    "glob"
  ],
  "allowedCommands": {
    "bash": [
      "npm install",
      "npm test",
      "git add",
      "git commit",
      "pytest"
    ]
  },
  "blockedCommands": {
    "bash": [
      "rm -rf",
      "dd",
      "mkfs",
      "sudo",
      "curl | bash",
      "wget | sh"
    ]
  }
}
```

Grants autonomy without unrestricted access.

### 5. Git Security

```bash
# Prevent force push to protected branches
git config --global push.default simple
git config --global branch.main.pushRemote no-push

# Require signed commits
git config --global commit.gpgsign true

# Agent should not have push access to main
# Use feature branches + PR workflow
```

## Monitoring and Alerting

### 1. System Monitoring

```bash
# Install monitoring tools
sudo apt install htop iotop nethogs

# Monitor in tmux pane
tmux new-window -n monitoring
tmux send-keys "htop" C-m

# Alert on high CPU
cat > ~/monitor-cpu.sh <<'EOF'
#!/bin/bash
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
if (( $(echo "$CPU_USAGE > 90" | bc -l) )); then
    echo "High CPU: ${CPU_USAGE}%" | mail -s "Alert" admin@example.com
fi
EOF

chmod +x ~/monitor-cpu.sh

# Run every 5 minutes
crontab -e
# Add: */5 * * * * /home/user/monitor-cpu.sh
```

### 2. Log Monitoring

```bash
# Centralize logs
mkdir -p ~/logs

# Redirect agent output
claude 2>&1 | tee -a ~/logs/agent-$(date +%Y%m%d).log

# Monitor for errors
tail -f ~/logs/*.log | grep -i "error\|fail\|exception"

# Alert on suspicious activity
tail -f ~/logs/*.log | grep -E "rm -rf|sudo|curl.*bash" | \
    while read line; do
        echo "Suspicious: $line" | mail -s "Security Alert" admin@example.com
    done
```

### 3. File Integrity Monitoring

```bash
# Track what files agent is modifying
inotifywait -m -r --format '%T %w%f %e' --timefmt '%Y-%m-%d %H:%M:%S' \
    /workspace | tee ~/logs/file-changes.log

# Alert on modifications to sensitive files
inotifywait -m /etc/passwd /etc/shadow ~/.ssh/authorized_keys | \
    while read line; do
        echo "Sensitive file modified: $line" | mail -s "Security Alert" admin@example.com
    done
```

### 4. Network Monitoring

```bash
# Monitor outbound connections
sudo nethogs

# Log all connections
sudo tcpdump -i any -w ~/logs/network-$(date +%Y%m%d).pcap

# Alert on unusual destinations
# (e.g., agent trying to connect to unknown servers)
```

## Incident Response

### 1. Agent Goes Rogue

```bash
# IMMEDIATE: Kill agent process
pkill -f claude
pkill -f cursor-agent

# Stop tmux session
tmux kill-session -t agent-session

# Review what happened
git diff HEAD  # What did agent change?
tail -n 100 ~/logs/agent-*.log  # What did it do?

# Rollback if needed
git reset --hard HEAD~1

# Investigate
grep "bash" ~/logs/agent-*.log  # What commands did it run?
```

### 2. Unauthorized Access Detected

```bash
# Check login attempts
sudo tail -n 100 /var/log/auth.log
sudo fail2ban-client status sshd

# Check current connections
who
w
last -n 20

# If compromised:
# 1. Disconnect server from network
sudo ufw deny in on eth0

# 2. Rotate all credentials
# 3. Review all agent changes
# 4. Restore from backup if needed
# 5. Analyze how breach occurred
```

### 3. Data Exfiltration

```bash
# Check for unusual network activity
sudo iftop
sudo nethogs

# Check agent's recent file access
find . -type f -mmin -60  # Files modified in last hour

# Check for data dumps
find . -name "*.sql" -o -name "*.csv" -o -name "dump*" -mmin -60

# Review git commits
git log --since="1 hour ago" --all --oneline
git diff HEAD~5..HEAD  # Recent changes
```

## Backup and Recovery

### 1. Automated Backups

```bash
#!/bin/bash
# backup-agent-workspace.sh

BACKUP_DIR=~/backups
WORKSPACE=/workspace
DATE=$(date +%Y%m%d-%H%M%S)

# Create backup
tar -czf $BACKUP_DIR/workspace-$DATE.tar.gz $WORKSPACE

# Keep only last 7 days
find $BACKUP_DIR -name "workspace-*.tar.gz" -mtime +7 -delete

# Upload to S3 (optional)
# aws s3 cp $BACKUP_DIR/workspace-$DATE.tar.gz s3://my-backups/
```

```bash
# Run every 6 hours
crontab -e
# Add: 0 */6 * * * /home/user/backup-agent-workspace.sh
```

### 2. Git-Based Backups

```bash
# Automatic commits every hour
#!/bin/bash
# auto-commit.sh

cd /workspace
git add -A
git commit -m "Auto-checkpoint $(date -Iseconds)" || true
git push origin auto-checkpoints || true
```

```bash
# Cron job
0 * * * * /home/user/auto-commit.sh
```

### 3. VM Snapshots

```bash
# On DigitalOcean, Hetzner, etc.
# Enable automatic daily snapshots

# Or manual snapshot before risky operations:
# Via provider's web console or API
```

## Secret Management

### 1. Never Commit Secrets

```bash
# .gitignore
.env
*.pem
*.key
secrets/
.secrets
config/local.yml
credentials.json

# Use git-secrets to prevent accidents
git clone https://github.com/awslabs/git-secrets.git
cd git-secrets
sudo make install

cd /workspace
git secrets --install
git secrets --register-aws  # Prevent AWS key commits
```

### 2. Use Environment Variables

```bash
# .env file (not committed)
ANTHROPIC_API_KEY=sk-ant-...
DATABASE_URL=postgresql://...
AWS_ACCESS_KEY_ID=...

# Load in agent startup script
set -a
source .env
set +a

claude
```

### 3. Secrets Rotation

```bash
# Rotate API keys monthly
# Set calendar reminder

# Script to rotate key
rotate-anthropic-key() {
    # 1. Generate new key in Anthropic console
    # 2. Update .env file
    # 3. Restart agent
    # 4. Delete old key
}
```

## Security Checklist

### Server Setup

- [ ] SSH key-based authentication only
- [ ] Root login disabled
- [ ] Firewall configured (UFW)
- [ ] fail2ban installed and configured
- [ ] Automatic security updates enabled
- [ ] Tailscale for private networking
- [ ] Non-standard SSH port (optional)

### Application Security

- [ ] Agent runs as non-root user
- [ ] API keys in environment variables, not code
- [ ] .gitignore includes secrets patterns
- [ ] git-secrets installed
- [ ] Dangerous commands blocked or allowlisted
- [ ] Docker isolation (if using dangerous mode)

### Monitoring

- [ ] System monitoring (CPU, memory, disk)
- [ ] Log aggregation and monitoring
- [ ] File integrity monitoring
- [ ] Network monitoring
- [ ] Alerts configured

### Backup & Recovery

- [ ] Automated backups configured
- [ ] Git-based version control
- [ ] VM snapshots enabled
- [ ] Tested recovery procedure
- [ ] Off-site backup storage

### Operational Security

- [ ] Incident response plan documented
- [ ] Regular security audits scheduled
- [ ] Access logs reviewed weekly
- [ ] API key rotation scheduled
- [ ] Team trained on security procedures

## Advanced: Security Automation

### Automated Security Scanning

```bash
#!/bin/bash
# security-scan.sh

# Check for exposed secrets
truffleHog filesystem /workspace --json > ~/logs/secrets-scan.log

# Check for vulnerable dependencies
cd /workspace
npm audit --json > ~/logs/npm-audit.log

# Check for suspicious files
find /workspace -name "*.sh" -o -name "*.py" | xargs grep -l "curl.*bash\|wget.*sh" \
    > ~/logs/suspicious-scripts.log

# Alert if issues found
if [ -s ~/logs/suspicious-scripts.log ]; then
    mail -s "Security Scan Alert" admin@example.com < ~/logs/suspicious-scripts.log
fi
```

```bash
# Run daily
crontab -e
# Add: 0 2 * * * /home/user/security-scan.sh
```

## Next Steps

1. Review working examples and complete setups → See `07-examples.md`
2. Start implementing your continuous agent → See `README.md`

## References

- @levelsio's "HOW TO SECURE YOUR RAW DOG VPS SERVER" thread (Feb 2025)
- Hetzner security best practices
- DigitalOcean security guides
- Anthropic security documentation
- Community Docker isolation setups
- fail2ban documentation
- Tailscale security model
