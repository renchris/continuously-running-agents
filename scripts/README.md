# Scripts and Configuration Files

This directory contains all the scripts and configuration files needed to deploy and manage continuous Claude Code agents on your OVHCloud instance.

## Directory Structure

```
scripts/
├── setup/                    # Initial setup scripts
│   ├── 01-server-setup.sh   # Server initialization and security
│   ├── 02-install-claude.sh # Claude Code CLI installation
│   └── start-agent.sh       # Start individual agent
├── monitoring/              # Monitoring and observability
│   └── monitor-agent.sh     # Real-time dashboard
└── coordination/            # Multi-agent coordination
    ├── agent-coordination.sh # Coordination library
    └── spawn-agents.sh      # Launch multiple agents

config/
├── .tmux.conf               # tmux configuration
└── claude-agent.service     # systemd service file
```

## Quick Start

### Single Agent Setup

```bash
# 1. Upload scripts to your OVHCloud instance
scp -r scripts config ubuntu@YOUR_INSTANCE_IP:~/

# 2. Run server setup (as root)
ssh ubuntu@YOUR_INSTANCE_IP
sudo -i
bash ~/scripts/setup/01-server-setup.sh

# 3. Install Claude Code (as agent user)
exit  # Exit root
exit  # Exit ubuntu
ssh claude-agent@YOUR_INSTANCE_IP
bash ~/scripts/setup/02-install-claude.sh

# 4. Start your first agent
bash ~/scripts/setup/start-agent.sh
```

### Multi-Agent Setup

```bash
# After single agent setup, spawn multiple agents:
bash ~/scripts/coordination/spawn-agents.sh 5 ~/projects/main

# Monitor all agents:
tmux attach -t agent-dashboard
```

## Script Reference

### Setup Scripts

#### `01-server-setup.sh`
**Purpose**: Initial server configuration and security hardening
**Run as**: root
**Run when**: First time, on fresh Ubuntu instance
**What it does**:
- Updates system packages
- Creates claude-agent user
- Configures SSH security
- Sets up firewall (UFW)
- Installs essential tools (tmux, git, htop, etc.)
- Configures fail2ban
- Applies system optimizations

**Usage**:
```bash
sudo bash scripts/setup/01-server-setup.sh
```

**Environment variables**:
- `AGENT_USER`: Username for agent (default: claude-agent)
- `SSH_PORT`: SSH port (default: 22)

---

#### `02-install-claude.sh`
**Purpose**: Install Claude Code CLI and configure API key
**Run as**: claude-agent (non-root)
**Run when**: After server setup
**What it does**:
- Installs Node.js 20.x
- Installs Claude Code CLI globally
- Configures Anthropic API key
- Sets up environment variables
- Creates convenience aliases

**Usage**:
```bash
bash scripts/setup/02-install-claude.sh
```

**Interactive prompts**:
- Anthropic API key
- Reinstall options if already installed

---

#### `start-agent.sh`
**Purpose**: Start a Claude Code agent in tmux
**Run as**: claude-agent
**Run when**: Anytime you want to start a new agent
**What it does**:
- Creates tmux session with 4 windows
- Starts Claude Code agent with logging
- Sets up monitoring windows
- Handles session conflicts

**Usage**:
```bash
# Interactive mode
bash scripts/setup/start-agent.sh

# Command line mode
bash scripts/setup/start-agent.sh <session-name> <project-path> [task]

# Examples:
bash scripts/setup/start-agent.sh main ~/projects/webapp
bash scripts/setup/start-agent.sh frontend ~/projects/app "Build React components"
```

**Windows created**:
- Window 0: Main agent (Claude Code interface)
- Window 1: Logs (live log viewer)
- Window 2: System (htop monitoring)
- Window 3: Git (status and history)

---

### Monitoring Scripts

#### `monitor-agent.sh`
**Purpose**: Real-time monitoring dashboard
**Run as**: claude-agent
**Run when**: To monitor running agents
**What it does**:
- Shows system resources (CPU, RAM, Disk)
- Lists active tmux sessions
- Displays recent log activity
- Shows health status
- Provides interactive controls

**Usage**:
```bash
bash scripts/monitoring/monitor-agent.sh [refresh-interval]

# Examples:
bash scripts/monitoring/monitor-agent.sh      # Default 5 second refresh
bash scripts/monitoring/monitor-agent.sh 10   # 10 second refresh
```

**Interactive controls**:
- `q` - Quit
- `a` - Attach to session
- `l` - View logs
- `r` - Refresh now

---

### Coordination Scripts

#### `agent-coordination.sh`
**Purpose**: Library for multi-agent coordination
**Run as**: Source this file in other scripts
**Run when**: When using multiple agents
**What it does**:
- Provides coordination functions
- Manages file-level locking
- Tracks active/completed/planned work
- Detects stale agents
- Prevents conflicts

**Usage**:
```bash
# Source the library
source scripts/coordination/agent-coordination.sh

# Initialize coordination
init_coordination

# Add tasks
add_task "src/file.ts" "Fix bug" "high"

# Claim work
claim_work "agent-1" "src/file.ts" "Fix bug"

# Complete work
complete_work "agent-1" "src/file.ts" "abc123commit"

# Check status
check_active_work
check_completed_work
show_stats
```

**Key Functions**:
- `init_coordination()` - Initialize system
- `claim_work(agent, file, task)` - Claim a file
- `complete_work(agent, file, commit)` - Mark work complete
- `release_work(agent, file, reason)` - Release without completing
- `add_task(file, task, priority)` - Add to queue
- `get_next_task(agent)` - Get next available task
- `check_stale_agents()` - Find stuck agents
- `cleanup_stale_agents()` - Release stale locks
- `show_stats()` - Display statistics

---

#### `spawn-agents.sh`
**Purpose**: Launch multiple coordinated agents
**Run as**: claude-agent
**Run when**: Setting up multi-agent system
**What it does**:
- Spawns N agents in separate tmux sessions
- Sets up coordination system
- Creates monitoring dashboard
- Staggers startup to avoid overload
- Adds sample tasks

**Usage**:
```bash
bash scripts/coordination/spawn-agents.sh [num-agents] [project-path]

# Examples:
bash scripts/coordination/spawn-agents.sh 5                     # 5 agents, default project
bash scripts/coordination/spawn-agents.sh 10 ~/projects/webapp  # 10 agents, specific project
```

**Configuration**:
- `NUM_AGENTS`: Number of agents to spawn (default: 5)
- `PROJECT_PATH`: Project directory (default: ~/projects/main)
- `STAGGER_DELAY`: Seconds between spawns (default: 5)

**Created sessions**:
- `agent-1`, `agent-2`, ..., `agent-N` - Worker agents
- `agent-dashboard` - Monitoring dashboard

---

## Configuration Files

### `.tmux.conf`
**Purpose**: tmux configuration optimized for agents
**Install**:
```bash
cp config/.tmux.conf ~/.tmux.conf
tmux source-file ~/.tmux.conf
```

**Features**:
- Mouse support enabled
- 50,000 line scrollback buffer
- Window numbering starts at 1
- Activity monitoring
- Custom status bar with system info
- Convenient key bindings

**Custom bindings**:
- `Ctrl+b, r` - Reload config
- `Ctrl+b, |` - Split horizontally
- `Ctrl+b, -` - Split vertically
- `Ctrl+b, m` - Open htop
- `Ctrl+b, l` - View logs

---

### `claude-agent.service`
**Purpose**: systemd service for production deployment
**Install**:
```bash
# 1. Edit file with your configuration
nano config/claude-agent.service
# Update: ANTHROPIC_API_KEY, WorkingDirectory, User

# 2. Install service
sudo cp config/claude-agent.service /etc/systemd/system/

# 3. Enable and start
sudo systemctl daemon-reload
sudo systemctl enable claude-agent
sudo systemctl start claude-agent
```

**Features**:
- Auto-start on boot
- Auto-restart on failure
- Proper logging to journald
- Resource limits
- Security settings

**Management**:
```bash
sudo systemctl status claude-agent
sudo systemctl restart claude-agent
sudo systemctl stop claude-agent
sudo journalctl -u claude-agent -f
```

---

## Complete Workflow Examples

### Example 1: Single Agent Setup

```bash
# On OVHCloud instance (as root)
sudo bash scripts/setup/01-server-setup.sh

# Switch to agent user
su - claude-agent

# Install Claude Code
bash scripts/setup/02-install-claude.sh

# Start agent
bash scripts/setup/start-agent.sh my-agent ~/projects/webapp "Build features"

# Monitor (in another terminal)
bash scripts/monitoring/monitor-agent.sh
```

### Example 2: Multi-Agent Team

```bash
# Initialize coordination
source scripts/coordination/agent-coordination.sh
init_coordination

# Add tasks
add_task "src/auth.ts" "Implement authentication" "high"
add_task "src/api.ts" "Build API endpoints" "high"
add_task "src/db.ts" "Database optimization" "medium"
add_task "tests/unit.test.ts" "Write unit tests" "medium"
add_task "docs/README.md" "Update docs" "low"

# Spawn 5 agents
bash scripts/coordination/spawn-agents.sh 5 ~/projects/webapp

# View dashboard
tmux attach -t agent-dashboard

# View specific agent
tmux attach -t agent-3

# Check progress
source scripts/coordination/agent-coordination.sh
show_stats
check_active_work
check_completed_work
```

### Example 3: Production Deployment

```bash
# 1. Setup and install
sudo bash scripts/setup/01-server-setup.sh
su - claude-agent
bash scripts/setup/02-install-claude.sh

# 2. Configure tmux
cp config/.tmux.conf ~/.tmux.conf

# 3. Set up systemd service
nano config/claude-agent.service  # Edit configuration
sudo cp config/claude-agent.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable claude-agent
sudo systemctl start claude-agent

# 4. Set up monitoring
bash scripts/monitoring/monitor-agent.sh

# 5. Set up backups (create cron job)
crontab -e
# Add: 0 3 * * * tar -czf ~/backups/projects-$(date +\%Y\%m\%d).tar.gz ~/projects/
```

---

## Best Practices

### Security
- Always run setup scripts as appropriate user (root vs agent user)
- Never commit API keys to git
- Use SSH keys, not passwords
- Enable UFW firewall
- Use Tailscale for remote access

### Resource Management
- Start with 1-2 agents, scale up gradually
- Monitor CPU/RAM usage regularly
- Set up log rotation
- Clean up old logs/backups regularly

### Maintenance
- Update system packages weekly: `sudo apt update && sudo apt upgrade`
- Check Claude Code for updates: `npm outdated -g`
- Review logs for errors: `tail -f ~/agents/logs/*.log`
- Monitor costs: Check Anthropic console weekly

### Monitoring
- Run monitoring dashboard in separate session
- Check for stale agents daily
- Set up external uptime monitoring
- Enable cost alerts in Anthropic console

---

## Troubleshooting

If you encounter issues, see:
1. [TROUBLESHOOTING.md](../TROUBLESHOOTING.md) - Comprehensive guide
2. [IMPLEMENTATION.md](../IMPLEMENTATION.md) - Step-by-step setup
3. Script logs: `~/agents/logs/`
4. System logs: `sudo journalctl -u claude-agent`

---

**Pro Tips**:

1. **Use tmux aliases**: Add to ~/.bashrc:
   ```bash
   alias agent-list='tmux ls'
   alias agent-attach='tmux attach -t'
   alias agent-new='bash ~/scripts/setup/start-agent.sh'
   ```

2. **Quick monitoring**: Add to ~/.bashrc:
   ```bash
   alias agent-status='bash ~/scripts/monitoring/monitor-agent.sh'
   ```

3. **Coordination shortcuts**: Add to ~/.bashrc:
   ```bash
   alias coord-stats='source ~/scripts/coordination/agent-coordination.sh && show_stats'
   alias coord-active='source ~/scripts/coordination/agent-coordination.sh && check_active_work'
   ```

---

**Questions or Issues?**
- See [IMPLEMENTATION.md](../IMPLEMENTATION.md) for detailed setup guide
- See [TROUBLESHOOTING.md](../TROUBLESHOOTING.md) for common problems
- Check the main [README.md](../README.md) for project overview
- Open an issue on GitHub for bugs or feature requests

---

**Version**: 1.0.0
**Last Updated**: October 19, 2025
**License**: MIT
