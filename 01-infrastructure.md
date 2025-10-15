# Infrastructure Setup for Continuously Running Agents

## Overview

This guide covers the infrastructure setup for running Claude Code agents 24/7 in the cloud, based on successful implementations from the community (March-October 2025).

## Cloud Provider Options

### Low-Cost VPS Providers

#### Hetzner (Most Popular)
- **Cost**: Starting at €4.99/month (~$5)
- **Why Popular**: Excellent performance-to-cost ratio
- **Community Favorite**: Heavily used by @levelsio and the vibecoding community
- **Specs**:
  - CPX11: 2 vCPU, 2GB RAM, 40GB SSD
  - Sufficient for Claude Code CLI operations
- **Location**: Multiple data centers (Germany, Finland, USA)

#### DigitalOcean
- **Cost**: Starting at $4-8/month
- **Droplet Options**:
  - Basic: $4/mo (512MB RAM) - may need upgrade to $8 (1GB) for package installs
  - Regular: $6/mo (1GB RAM)
  - GPU Droplets: Available for intensive workloads
- **Benefits**:
  - Easy setup with one-click apps
  - Official DigitalOcean MCP server for Claude integration
  - Good documentation for Claude Code setup

#### OVHCloud
- **Cost**: Starting at $5-8/month (Public Cloud)
- **Global Presence**: Data centers in US, Europe, Asia-Pacific
- **Public Cloud Instances**:
  - s1-2: 1 vCPU, 2GB RAM, 10GB SSD (~$5/mo)
  - s1-4: 1 vCPU, 4GB RAM, 20GB SSD (~$8/mo)
  - b2-7: 2 vCPU, 7GB RAM, 50GB SSD (~$15/mo)
- **Benefits**:
  - Competitive pricing
  - Flexible hourly or monthly billing
  - Good European presence
  - OpenStack-based infrastructure
- **Setup**:
  - Web console: <https://us.ovhcloud.com/manager/>
  - Create Public Cloud project
  - Launch instance with Ubuntu 24.04 LTS
  - Configure SSH keys during creation

#### Other Options
- **AWS EC2**: More expensive but highly scalable
- **Google Cloud**: Free tier available, more complex setup
- **Vultr**: Similar pricing to DigitalOcean
- **Linode/Akamai**: Reliable alternative

## The "Rawdog Dev on the Server" Approach

### Concept (from @levelsio)

Instead of traditional development workflow (local → git → deploy), you:
1. SSH directly into a VPS
2. Install Claude Code or Cursor CLI on the server
3. Code directly on production/staging
4. Refresh browser to see changes live
5. No deployment pipeline needed

### Why This Works

- **Speed**: No build/deploy cycle
- **Simplicity**: Single environment to manage
- **Cost-Effective**: $5/month vs complex CI/CD infrastructure
- **Real Environment**: Test in actual production conditions
- **Agent-Friendly**: Agent can directly manipulate running services

### When to Use It

✅ **Good For**:
- Rapid prototyping
- Solo developer projects
- MVPs and experiments
- Agent-driven development
- Learning and exploration

❌ **Avoid For**:
- Mission-critical production systems
- Team collaboration requiring code review
- Regulated industries requiring audit trails
- High-traffic production applications

## Basic VPS Setup

### Initial Server Provisioning

```bash
# 1. Create VPS with your provider
# - Choose Ubuntu 24.04 LTS or 22.04 LTS
# - Enable SSH key authentication during setup
# - Note your server IP address

# 2. First login
ssh root@YOUR_SERVER_IP

# 3. Update system
apt update && apt upgrade -y

# 4. Create non-root user (recommended)
adduser claude-agent
usermod -aG sudo claude-agent

# 5. Set up SSH key for new user
mkdir -p /home/claude-agent/.ssh
cp ~/.ssh/authorized_keys /home/claude-agent/.ssh/
chown -R claude-agent:claude-agent /home/claude-agent/.ssh
chmod 700 /home/claude-agent/.ssh
chmod 600 /home/claude-agent/.ssh/authorized_keys

# 6. Switch to new user
su - claude-agent
```

### Installing Required Software

```bash
# Install Node.js (required for Claude Code CLI)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Install Claude Code CLI
npm install -g @anthropic-ai/claude-code

# Install Git
sudo apt install -y git

# Install tmux (for session persistence)
sudo apt install -y tmux

# Install Mosh (for mobile access)
sudo apt install -y mosh

# Verify installations
node --version
npm --version
claude --version
tmux -V
mosh --version
```

### Installing Cursor CLI (Alternative)

```bash
# Install Cursor CLI
curl https://cli.cursor.com -fsS | bash

# Verify installation
cursor-agent --version
```

## Server Sizing Guidelines

### Memory Requirements

| Use Case | Minimum RAM | Recommended RAM |
|----------|-------------|-----------------|
| Claude Code CLI only | 512MB | 1GB |
| Claude Code + small web server | 1GB | 2GB |
| Multiple tmux agents | 2GB | 4GB |
| Heavy development workload | 4GB | 8GB |

### Storage Requirements

- **Minimum**: 20GB SSD
- **Recommended**: 40GB+ SSD
- **Consider**: Project size, dependencies, Docker images if used

### CPU Considerations

- **2 vCPU**: Sufficient for most agent workloads
- **4+ vCPU**: Better for parallel agent execution
- Agent work is mostly I/O-bound (API calls), not CPU-intensive

## Networking Setup

### Firewall Configuration

```bash
# Basic UFW setup
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH
sudo ufw allow ssh

# Allow Mosh (for mobile access)
sudo ufw allow 60000:61000/udp

# Allow HTTP/HTTPS if running web servers
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Enable firewall
sudo ufw enable
```

### DNS Configuration (Optional)

If you want a domain name for your agent server:

1. Purchase domain (Namecheap, Cloudflare, etc.)
2. Create A record pointing to your VPS IP
3. Wait for DNS propagation (5-30 minutes)
4. Set up SSL with Let's Encrypt:

```bash
sudo apt install -y certbot
sudo certbot certonly --standalone -d your-domain.com
```

## Environment Variables

Create a persistent environment configuration:

```bash
# Edit ~/.bashrc or ~/.zshrc
nano ~/.bashrc

# Add at the end:
export ANTHROPIC_API_KEY="your-api-key-here"
export OPENAI_API_KEY="your-openai-key-if-needed"

# Source the file
source ~/.bashrc
```

## Docker Setup (Optional, for Isolation)

If you want to run agents in isolated containers:

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER

# Logout and login again for group changes to take effect

# Verify
docker run hello-world
```

Some users run Claude Code with `--dangerously-skip-permissions` only inside Docker containers for safety.

## Monitoring and Maintenance

### Basic Monitoring

```bash
# Check disk usage
df -h

# Check memory usage
free -h

# Check CPU usage
htop  # install with: sudo apt install htop

# Check running processes
ps aux | grep claude
```

### Automated Updates

```bash
# Enable unattended upgrades (security updates)
sudo apt install unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades

# Enable auto-reboot for kernel updates (optional)
sudo nano /etc/apt/apt.conf.d/50unattended-upgrades
# Uncomment: Unattended-Upgrade::Automatic-Reboot "true";
```

### Log Management

```bash
# Create log directory
mkdir -p ~/agent-logs

# Configure log rotation
sudo nano /etc/logrotate.d/claude-agent

# Add:
/home/claude-agent/agent-logs/*.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
}
```

## Cost Comparison

| Setup | Monthly Cost | Use Case |
|-------|-------------|----------|
| Hetzner CPX11 | €4.99 (~$5) | Solo developer, learning |
| DigitalOcean Basic | $8 | Small projects |
| OVHCloud s1-2 | $5 | Budget-conscious, EU presence |
| DigitalOcean + Tailscale | $8 + free tier | Secure remote access |
| Hetzner + Domains + SSL | ~$10 | Professional setup |
| OVHCloud b2-7 (multi-agent) | $15 | 10-20 parallel agents |
| Multiple agents (4GB) | $15-25 | Team/parallel workflows |

## Community Examples

### @levelsio's Setup
- Provider: Hetzner VPS ($5/mo)
- Access: Termius (SSH client) + Mosh
- Workflow: SSH → Claude Code → Refresh browser
- Security: Key-based auth, fail2ban, firewall
- Result: Built entire 3D web apps in hours

### Community Reports
- "Hetzner VPS $4.99 + Claude Code = MVP in hours"
- "DigitalOcean $4 VPS + nginx + node server = 30mins to SSL-enabled site"
- "On iPhone with Termius + Claude Code on staging VPS = test immediately in Safari"

## Next Steps

After setting up infrastructure:
1. Configure tmux for session persistence → See `02-tmux-setup.md`
2. Set up remote access → See `03-remote-access.md`
3. Configure Claude Code for autonomous operation → See `04-claude-configuration.md`
4. Implement security hardening → See `06-security.md`

## References

- @levelsio tweet: "HOW TO RAW DOG DEV ON THE SERVER" (Feb 2025)
- DigitalOcean tutorial: "VS Code + Claude Code on GPU Droplets"
- Community experiments with Hetzner autonomous agents
- Various success stories from X/Twitter (March-Oct 2025)
