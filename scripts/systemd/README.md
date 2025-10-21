# Systemd Service for Claude Agents (Optional)

This directory contains systemd service files for running Claude agents as managed services with robust resource limits.

## Why Use Systemd?

**Advantages over tmux + bash scripts:**
- **Automatic restarts** on crash/failure
- **Resource limits** enforced by kernel (cgroups)
- **Better monitoring** via journalctl
- **Startup on boot** if desired
- **Process isolation** and security hardening

**When to use:**
- Long-running production agents
- Unattended server environments
- Need strict resource enforcement
- Want automatic failure recovery

**When NOT to use:**
- Interactive development
- Short-lived tasks
- Need to attach/detach frequently
- Prefer simpler tmux workflow

## Files

- `claude-agent@.service` - Template service file for agent instances
- `README.md` - This file

## Installation

### 1. Copy service file to systemd directory

```bash
# On Hetzner server
sudo cp claude-agent@.service /etc/systemd/system/
sudo systemctl daemon-reload
```

### 2. Start agent instances

```bash
# Start agent 1
sudo systemctl start claude-agent@1

# Start agents 1-5
for i in {1..5}; do
    sudo systemctl start claude-agent@$i
done
```

### 3. Enable auto-start on boot (optional)

```bash
# Enable agent 1 to start on boot
sudo systemctl enable claude-agent@1

# Enable all 5 agents
for i in {1..5}; do
    sudo systemctl enable claude-agent@$i
done
```

## Management Commands

```bash
# Check status
sudo systemctl status claude-agent@1

# View logs (live)
sudo journalctl -u claude-agent@1 -f

# View logs (last 100 lines)
sudo journalctl -u claude-agent@1 -n 100

# Stop agent
sudo systemctl stop claude-agent@1

# Restart agent
sudo systemctl restart claude-agent@1

# Check resource usage
systemd-cgtop
```

## Resource Limits

Each agent is limited to:
- **CPU**: 80% of one core
- **Memory**: 800MB max (700MB soft limit)
- **Processes**: 100 max
- **Open Files**: 1024 max
- **Disk I/O**: 10MB/s read, 5MB/s write
- **Runtime**: 8 hours max (auto-terminates)

## Security Features

The service file includes several hardening measures:
- Isolated /tmp directory
- Read-only system directories
- Cannot gain new privileges
- No kernel module loading
- No SUID/SGID execution
- Restricted to project directory

## Customization

### Adjust resource limits

Edit `/etc/systemd/system/claude-agent@.service`:

```ini
[Service]
CPUQuota=150%          # Use 1.5 CPU cores
MemoryMax=1G           # Use 1GB RAM
RuntimeMaxSec=14400    # 4 hours max
```

Then reload:
```bash
sudo systemctl daemon-reload
sudo systemctl restart claude-agent@1
```

### Change working directory

```ini
[Service]
WorkingDirectory=/home/claude-agent/projects/different-repo
```

### Restrict network access

Uncomment these lines:
```ini
[Service]
PrivateNetwork=true              # No network access
# OR
RestrictAddressFamilies=AF_INET AF_INET6  # Only IPv4/IPv6
```

## Monitoring

### View all agent resource usage

```bash
# Real-time resource monitor
systemd-cgtop

# Show only claude-agent services
systemd-cgtop | grep claude-agent
```

### Check if agent hit resource limits

```bash
# Check for OOM (out of memory) kills
sudo journalctl -u claude-agent@1 | grep -i "oom\|killed"

# Check CPU throttling
sudo journalctl -u claude-agent@1 | grep -i "cpu"

# Check all limits
systemctl show claude-agent@1 | grep -E "CPU|Memory|Tasks"
```

## Comparison: Systemd vs Tmux Script

| Feature | Tmux + Bash | Systemd Service |
|---------|-------------|-----------------|
| Resource Limits | Soft (ulimit) | Hard (cgroups) |
| Auto-restart | No | Yes |
| Logging | File-based | Journald |
| Security | Basic | Hardened |
| Interactive | Easy | Harder |
| Complexity | Low | Medium |
| Boot startup | Manual | Automatic |

## Recommendation

**For development/testing:**
Use `scripts/start-agent-yolo.sh` (tmux-based)

**For production/unattended:**
Use systemd service files

**Hybrid approach:**
Use tmux for interactive work, systemd for background agents

## Troubleshooting

### Service won't start

```bash
# Check syntax
sudo systemd-analyze verify /etc/systemd/system/claude-agent@.service

# View full error
sudo journalctl -u claude-agent@1 -xe
```

### Agent keeps restarting

```bash
# Disable auto-restart temporarily
sudo systemctl edit claude-agent@1

# Add:
[Service]
Restart=no

# Save and restart
sudo systemctl daemon-reload
sudo systemctl restart claude-agent@1
```

### Resource limits too strict

```bash
# Check current usage
systemctl show claude-agent@1 | grep -E "MemoryCurrent|CPUUsage"

# Adjust limits in service file
sudo vim /etc/systemd/system/claude-agent@.service

# Reload and restart
sudo systemctl daemon-reload
sudo systemctl restart claude-agent@1
```

## Removal

```bash
# Stop and disable all agents
for i in {1..5}; do
    sudo systemctl stop claude-agent@$i
    sudo systemctl disable claude-agent@$i
done

# Remove service file
sudo rm /etc/systemd/system/claude-agent@.service
sudo systemctl daemon-reload
```
