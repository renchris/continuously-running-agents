# Setup Scripts

Automated scripts for setting up Claude Code agents on cloud infrastructure.

## Quick Start

Run these scripts **in order** on your new cloud server:

```bash
# 1. Initial server setup (as root)
bash 01-server-setup.sh

# 2. Install Claude Code (as claude-agent user)
su - claude-agent
bash ~/scripts/setup/02-install-claude.sh

# 3. Configure GitHub access (as claude-agent user)
bash ~/scripts/setup/03-github-auth.sh

# 4. Start your first agent
bash ~/scripts/setup/start-agent.sh
```

---

## Scripts

### 01-server-setup.sh

**Purpose**: Initial server configuration and security hardening

**Run as**: `root`

**What it does**:
- Updates system packages
- Creates `claude-agent` user with sudo privileges
- Configures SSH security
- Sets up UFW firewall (SSH + HTTPS only)
- Installs fail2ban for brute-force protection
- Installs essential tools (tmux, git, htop, curl, wget, etc.)
- Creates directory structure for agents

**Usage**:
```bash
# Upload to server
scp -i ~/.ssh/your_key 01-server-setup.sh root@YOUR_SERVER_IP:~/

# SSH into server
ssh -i ~/.ssh/your_key root@YOUR_SERVER_IP

# Run the script
bash 01-server-setup.sh
```

**Time**: ~5-10 minutes (depending on system updates)

---

### 02-install-claude.sh

**Purpose**: Install Node.js and Claude Code CLI

**Run as**: `claude-agent` user (NOT root)

**What it does**:
- Installs Node.js 20.x from NodeSource
- Installs Claude Code CLI globally via npm
- Configures authentication (Max Plan or API Key)
- Creates sample configuration
- Sets up convenience aliases
- Verifies installation

**Usage**:
```bash
# Switch to claude-agent user
su - claude-agent

# Run the script
bash ~/scripts/setup/02-install-claude.sh

# Choose authentication method:
# 1. Max Plan Login (~225 msg/5hrs, uses claude.ai subscription)
# 2. API Key (pay-per-token, separate billing)
```

**Authentication Options**:

**Max Plan (Option 1)**:
- Pros: Fixed cost ($100/mo), good for 5-10 moderate agents
- Cons: Shared rate limits (~225 msg/5hrs across all agents)
- Best for: Cost-predictable workloads with moderate usage

**API Key (Option 2)**:
- Pros: No rate limits, scales to any number of agents
- Cons: Pay-per-token billing, costs vary with usage
- Best for: High-volume usage, 20+ agents, unpredictable workloads

**Time**: ~5-10 minutes

---

### 03-github-auth.sh

**Purpose**: Configure GitHub access for repository operations

**Run as**: `claude-agent` user

**What it does**:
- Configures git user.name and user.email
- Generates ED25519 SSH key for GitHub
- Displays public key to add to GitHub account
- Tests SSH connection to GitHub
- Installs GitHub CLI (gh)
- Authenticates GitHub CLI via browser
- Verifies repository access
- Creates helpful git aliases
- Generates usage guide

**Usage**:
```bash
# Run the script
bash ~/scripts/setup/03-github-auth.sh

# Follow the prompts:
# 1. Enter your git name and email
# 2. Copy SSH public key and add to https://github.com/settings/keys
# 3. Press ENTER after adding key
# 4. Authenticate GitHub CLI via browser
```

**GitHub Permissions Granted**:
- ✅ Clone private repositories (via SSH)
- ✅ Push commits (via SSH)
- ✅ Create branches (via SSH)
- ✅ Create pull requests (via gh CLI)
- ✅ Manage issues (via gh CLI)
- ✅ Create releases (via gh CLI)
- ✅ Full GitHub API access (via gh CLI)

**Security Notes**:
- SSH key is specific to this server
- GitHub CLI token stored in `~/.config/gh/hosts.yml`
- SSH key comment includes server identifier for easy management
- Both can be revoked from GitHub settings if server is compromised

**Time**: ~5 minutes

---

### start-agent.sh

**Purpose**: Start a Claude Code agent in tmux with proper configuration

**Run as**: `claude-agent` user

**What it does**:
- Creates unique tmux session name
- Sets up working directory
- Initializes log file
- Starts Claude Code with your prompt
- Detaches from tmux (agent runs in background)

**Usage**:
```bash
# Run the script
bash ~/scripts/setup/start-agent.sh

# Or with a custom prompt
bash ~/scripts/setup/start-agent.sh "Monitor logs and fix errors"

# Check running agents
tmux ls

# Attach to agent
tmux attach -t agent-20251020-0830

# Detach from agent (keep it running)
# Press: Ctrl+B, then D
```

**Options**:
- No arguments: Prompts for task description interactively
- One argument: Uses the argument as the task prompt

**Example**:
```bash
# Interactive mode
bash start-agent.sh
> Enter task: Monitor application logs every 10 minutes

# Direct mode
bash start-agent.sh "Refactor authentication module"
```

**Time**: <1 minute

---

## Typical Setup Timeline

Full setup from scratch to running agent:

| Step | Script | Time | Complexity |
|------|--------|------|------------|
| 1 | 01-server-setup.sh | 5-10 min | Easy |
| 2 | 02-install-claude.sh | 5-10 min | Easy |
| 3 | 03-github-auth.sh | 5 min | Medium |
| 4 | start-agent.sh | <1 min | Easy |
| **Total** | | **~20 min** | |

---

## Prerequisites

### Before Running Scripts

1. **Cloud server** with Ubuntu 24.04 (or 22.04/20.04)
2. **SSH access** as root
3. **SSH key pair** generated locally
4. **Anthropic account**:
   - Max Plan subscription ($100/mo), OR
   - API key from https://console.anthropic.com/
5. **GitHub account** (for 03-github-auth.sh)

### Local Machine Requirements

- SSH client
- SCP (for uploading scripts)
- Web browser (for GitHub authentication)

---

## Post-Setup

### Verify Everything Works

```bash
# Test Claude Code
claude -p "What is 2+2? Answer in one word."

# Test GitHub SSH
ssh -T git@github.com

# Test GitHub CLI
gh repo list

# Check running agents
tmux ls

# View logs
tail -f ~/agents/logs/*.log
```

### Common Next Steps

1. **Clone your repositories**:
   ```bash
   git clone git@github.com:username/repo.git
   cd repo
   ```

2. **Start a long-running agent**:
   ```bash
   bash ~/scripts/setup/start-agent.sh "Monitor and optimize performance for 24 hours"
   ```

3. **Set up systemd service** (for production 24/7 operation):
   ```bash
   # See: knowledge-base/IMPLEMENTATION.md, "Method 3: systemd Service"
   ```

---

## Troubleshooting

### Script 01 Fails

**Issue**: Package installation errors

**Solution**:
```bash
sudo apt update
sudo apt upgrade -y
# Retry the script
```

---

### Script 02 Fails

**Issue**: "This script should NOT be run as root"

**Solution**:
```bash
# Switch to claude-agent user
su - claude-agent

# Or re-connect as claude-agent
ssh -i ~/.ssh/your_key claude-agent@YOUR_SERVER_IP
```

**Issue**: Node.js installation fails

**Solution**:
```bash
# Manually add NodeSource repository
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
```

---

### Script 03 Fails

**Issue**: SSH connection to GitHub fails

**Possible causes**:
1. Public key not added to GitHub
2. Wrong key copied (must be entire line including `ssh-ed25519`)
3. Key not added to correct GitHub account

**Solution**:
```bash
# Verify public key content
cat ~/.ssh/id_ed25519.pub

# Manually test SSH
ssh -T git@github.com
# Should see: "Hi username! You've successfully authenticated..."

# Check GitHub settings
# Go to: https://github.com/settings/keys
# Verify key is listed
```

**Issue**: GitHub CLI authentication fails

**Solution**:
```bash
# Re-run authentication
gh auth login

# Choose:
# - GitHub.com
# - HTTPS
# - Authenticate with browser
# - Follow the prompts
```

---

## Security Considerations

### SSH Keys

- Each server should have its own SSH key pair
- Use provider-specific naming (e.g., `hetzner_claude_agent`, `ovh_claude_agent`)
- Never commit private keys to git
- Revoke keys from GitHub if server is compromised

### API Keys

- Never commit API keys or tokens to git
- Store in environment variables or config files (excluded from git)
- Rotate API keys periodically
- Use Max Plan where possible to avoid storing API keys

### GitHub Access

- Consider using GitHub Fine-Grained Tokens instead of full access
- Scope tokens to specific repositories
- Set expiration dates on tokens
- Monitor GitHub audit log for suspicious activity

---

## Advanced Usage

### Running Scripts Remotely

You can run setup scripts remotely without logging in:

```bash
# Upload and run server setup in one command
scp -i ~/.ssh/hetzner_claude_agent 01-server-setup.sh root@YOUR_IP:~/ && \
ssh -i ~/.ssh/hetzner_claude_agent root@YOUR_IP "bash ~/01-server-setup.sh"

# Run Claude installation as claude-agent
ssh -i ~/.ssh/hetzner_claude_agent claude-agent@YOUR_IP "bash ~/scripts/setup/02-install-claude.sh"
```

### Scripting Multiple Servers

```bash
#!/bin/bash
# setup-all-servers.sh

SERVERS=(
  "claude-agent@server1.example.com"
  "claude-agent@server2.example.com"
  "claude-agent@server3.example.com"
)

for SERVER in "${SERVERS[@]}"; do
  echo "Setting up $SERVER..."

  # Upload scripts
  scp -i ~/.ssh/key scripts/setup/*.sh "$SERVER:~/scripts/setup/"

  # Run setup
  ssh -i ~/.ssh/key "$SERVER" "bash ~/scripts/setup/02-install-claude.sh"

  echo "$SERVER setup complete"
done
```

---

## Related Documentation

- **IMPLEMENTATION.md**: Comprehensive deployment guide with real-world examples
- **TROUBLESHOOTING.md**: Detailed troubleshooting for common issues
- **CONTRIBUTING.md**: Git and changeset workflow
- **knowledge-base/*.md**: Provider comparisons, cost analysis, latency testing

---

## Support

If you encounter issues:

1. Check **TROUBLESHOOTING.md** for solutions
2. Review script output for specific error messages
3. Verify prerequisites are met
4. Check system logs: `sudo journalctl -xe`

---

## Version History

- **v1.0** (2025-10): Initial scripts (01-server-setup.sh, 02-install-claude.sh, start-agent.sh)
- **v1.1** (2025-10): Added GitHub authentication (03-github-auth.sh)

---

**Quick Reference**:

```bash
# Full setup from scratch
bash 01-server-setup.sh          # as root
su - claude-agent
bash ~/scripts/setup/02-install-claude.sh
bash ~/scripts/setup/03-github-auth.sh
bash ~/scripts/setup/start-agent.sh

# Verify
claude -p "Hello"
ssh -T git@github.com
gh repo list
tmux ls
```
