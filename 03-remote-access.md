# Remote Access for Continuously Running Agents

## Overview

This guide covers methods to access and monitor your Claude Code agents from anywhere - including mobile devices. Based on successful setups from the community (March-October 2025).

## Why Remote Access Matters

- **Mobile Monitoring**: Check on agent progress from your phone
- **On-the-Go Steering**: Adjust agent direction while away from desk
- **Network Resilience**: Maintain connections through network changes
- **Multi-Device Access**: Work from laptop, phone, tablet seamlessly
- **Real-Time Visibility**: Watch agents work in real-time

## Access Methods Comparison

| Method | Cost | Complexity | Mobile Support | Security | Use Case |
|--------|------|------------|----------------|----------|----------|
| SSH | Free | Low | Yes (with client) | High | Basic access |
| Mosh | Free | Low | Excellent | High | Mobile-first |
| Tailscale | Free tier | Medium | Excellent | Very High | Private network |
| VibeTunnel | Free | Low | Excellent | Medium | Web browser access |
| GoTTY/ttyd | Free | Medium | Good | Medium | Web terminal |
| ngrok | Free tier | Low | Good | Medium | Quick demos |

## Method 1: SSH (Foundation)

### Basic SSH Setup

```bash
# On server: Ensure SSH is running
sudo systemctl status ssh

# On client: Connect
ssh username@server-ip

# With key-based auth (recommended)
ssh -i ~/.ssh/id_rsa username@server-ip

# Keep connection alive
ssh -o ServerAliveInterval=60 username@server-ip
```

### SSH on Mobile

**iOS Apps**:
- **Blink Shell** (Recommended, $20 one-time)
  - Native SSH & Mosh support
  - Excellent keyboard
  - Background execution
- **Termius** (Freemium)
  - Good UI, popular choice
  - Free for basic use
  - @levelsio uses this

**Android Apps**:
- **JuiceSSH** (Free)
- **Termius** (Cross-platform)
- **ConnectBot** (Free, open source)

### SSH Limitations

❌ Disconnects on network changes
❌ Laggy on poor connections
❌ Session dies if mobile app backgrounded (sometimes)
❌ No instant reconnection

## Method 2: Mosh (Mobile Shell) - Recommended for Mobile

### What is Mosh?

Mosh = SSH + UDP + local echo + state synchronization

**Key Benefits**:
- Survives network changes (WiFi ↔ Cellular)
- Works on intermittent connections
- Instant responsiveness (local echo)
- Background-safe (can close app and return)
- Combines perfectly with tmux

### Installation

```bash
# Server side
sudo apt install mosh

# Allow Mosh through firewall
sudo ufw allow 60000:61000/udp

# Verify
mosh --version
```

### Usage

```bash
# Basic connection
mosh username@server-ip

# With Tailscale (private IP)
mosh username@100.x.y.z

# From Blink Shell on iPhone
mosh you@<private-tailscale-ip>

# Combine with tmux
mosh username@server -- tmux attach -t claude-agent
```

### Recommended Mobile Setup (from community)

**Brian Sunter's Setup**:
```
Tools:
- Host Machine with remote SSH configured
- Mobile SSH client (Termius or Blink)
- Tailscale (private connection)
- Tmux (keeps CC running if disconnected)
- Mosh (survive network interruptions)

Workflow:
1. Tailscale creates private network
2. Mosh provides resilient connection
3. Tmux persists sessions
4. Claude Code runs inside tmux
Result: Code from anywhere, even while GF is shopping!
```

### Mosh Best Practices

```bash
# Set prediction mode for better mobile experience
# In ~/.ssh/config or mosh startup:
mosh --predict=always username@server

# Combine with screen/tmux for ultimate persistence
mosh user@server -- tmux attach
```

## Method 3: Tailscale (Private Network) - Most Secure

### What is Tailscale?

Tailscale creates a secure private network (VPN) between your devices using WireGuard encryption.

**Key Benefits**:
- Peer-to-peer connections (no traffic through servers)
- No port forwarding needed
- Works behind NAT/firewalls
- WireGuard encryption
- Free tier sufficient for personal use
- Access via private IPs anywhere

### Setup

#### On Server

```bash
# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Start Tailscale
sudo tailscale up

# Note your Tailscale IP (100.x.y.z)
tailscale ip -4
```

#### On Client Devices

1. **Desktop** (Mac/Linux/Windows):
   ```bash
   # Install from: https://tailscale.com/download
   # Login with same account
   ```

2. **Mobile** (iOS/Android):
   - Download Tailscale app
   - Login with same account
   - Enable VPN

#### Secure Your Server

```bash
# Only allow SSH from Tailscale network
sudo ufw delete allow ssh
sudo ufw allow from 100.64.0.0/10 to any port 22

# Verify
sudo ufw status
```

### Usage

```bash
# SSH via Tailscale (from anywhere)
ssh username@100.x.y.z

# Mosh via Tailscale (even better)
mosh username@100.x.y.z

# From iPhone with Blink:
# 1. Enable Tailscale VPN on phone
# 2. Open Blink Shell
# 3. mosh you@100.x.y.z
# Result: Secure access from anywhere in the world
```

### Tailscale + Mosh + Tmux = Ultimate Setup

```bash
# The golden combination:

1. Tailscale: Private secure network
2. Mosh: Resilient mobile connection
3. Tmux: Persistent sessions
4. Claude Code: Running in tmux

# Connection from phone:
Enable Tailscale → Open SSH app → mosh user@tailscale-ip → tmux attach

# Benefits:
✅ Fully encrypted (WireGuard)
✅ Survives network changes
✅ Can switch between devices mid-session
✅ No public exposure
✅ Zero-config networking
```

## Method 4: VibeTunnel (Web Browser Access)

### What is VibeTunnel?

Turn any browser into your terminal - no SSH client needed.

**Features**:
- Web-based terminal access
- No SSH client installation required
- AI agent monitoring optimized
- Multiple authentication modes
- Localhost-only or tunneled via Tailscale/ngrok

### Installation

```bash
# Clone repository
git clone https://github.com/amantus-ai/vibetunnel.git
cd vibetunnel

# Install dependencies
npm install

# Start server
npm start

# Access via browser: http://localhost:8000
```

### Secure Remote Access

```bash
# Option 1: Via Tailscale (recommended)
# Start VibeTunnel on server
npm start

# Access from any device on Tailscale:
http://100.x.y.z:8000

# Option 2: Via ngrok (quick demos)
ngrok http 8000
# Use provided ngrok URL
```

### Use Cases

- Monitor Claude Code from any device with browser
- No native app installation needed
- Great for tablets/chromebooks
- Perfect for demonstrations
- Quick access without SSH setup

## Method 5: GoTTY / ttyd (Web Terminal)

### GoTTY

Share your terminal as a web application.

```bash
# Install
wget https://github.com/yudai/gotty/releases/download/v1.0.1/gotty_linux_amd64.tar.gz
tar -xzf gotty_linux_amd64.tar.gz
sudo mv gotty /usr/local/bin/

# Basic usage
gotty -w tmux attach -t claude-agent

# With authentication
gotty -w --credential user:password tmux attach

# With TLS (secure)
gotty -w --tls --tls-crt ~/.ssl/cert.pem --tls-key ~/.ssl/key.pem tmux attach

# Access: https://server-ip:8080
```

### ttyd (Alternative)

```bash
# Install
sudo apt install ttyd

# Run with tmux
ttyd -W tmux attach -t claude-agent

# Access: http://server-ip:7681
```

### Security Considerations

⚠️ **Important**:
- Use TLS/SSL for production
- Implement authentication
- Prefer Tailscale for tunneling
- Don't expose to public internet without auth

## Method 6: ngrok (Quick Tunneling)

### Use Case

Quick demos, temporary access, no server config needed.

```bash
# Install
curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null
echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list
sudo apt update && sudo apt install ngrok

# Auth with token from ngrok.com
ngrok config add-authtoken YOUR_TOKEN

# Tunnel SSH
ngrok tcp 22

# Result: Access via ngrok-provided URL
# ssh user@0.tcp.ngrok.io -p 12345
```

### ngrok Limitations

- Free tier has session limits
- URLs change on restart (unless paid)
- Less secure than Tailscale
- Best for temporary access

## Recommended Setup by Use Case

### Solo Developer - Mobile Access
```
Base: Hetzner VPS ($5/mo)
Access: SSH + Mosh + Tailscale (all free)
Mobile: Blink Shell (iOS) or Termius
Persistence: tmux
Cost: $5-25/mo total
Security: ⭐⭐⭐⭐⭐
```

### Team Collaboration
```
Base: DigitalOcean Droplet ($8-15/mo)
Access: Tailscale for team private network
Monitoring: VibeTunnel for web dashboards
Persistence: tmux + Claude Squad
Cost: $10-30/mo
Security: ⭐⭐⭐⭐⭐
```

### Quick Experiments
```
Base: Any VPS
Access: ngrok for quick demos
Monitoring: GoTTY for web terminal
Persistence: tmux
Cost: Minimal
Security: ⭐⭐ (temporary only)
```

### Maximum Mobility
```
Setup:
1. Tailscale on all devices
2. Mosh for mobile clients
3. tmux for persistence
4. Claude Code in tmux sessions

Result:
- Code from phone while commuting
- Switch from phone to laptop seamlessly
- Survives network changes
- Fully encrypted
```

## Real-World Examples

### @levelsio's Mobile Setup

```
Hardware: Hetzner VPS
Client: Termius on iOS
Protocol: SSH (considering Mosh)
Workflow: "Can code on phone while GF is shopping!"
Security: Key-based auth, fail2ban
```

### Community Mobile Setup

```
Stack:
- Mac Mini at home running Claude Code
- Tailscale on Mac Mini + iPhone
- Blink Shell on iPhone
- Mosh over Tailscale
- tmux for session persistence

Result:
- Access from anywhere in world
- Switch devices seamlessly
- Sessions persist through network changes
- Monitor agent progress on the go
```

### Web Dashboard Monitoring

```
Stack:
- VPS running multiple Claude agents in tmux
- VibeTunnel for web access
- Tailscale for secure tunneling
- Access from tablet/phone browser

Result:
- Monitor all agents from single dashboard
- No native app needed
- Perfect for tablets
```

## Troubleshooting

### Mosh Not Connecting

```bash
# Check firewall allows UDP 60000-61000
sudo ufw status | grep 60000

# Verify mosh-server installed
which mosh-server

# Test with verbose mode
mosh --ssh="ssh -v" username@server
```

### Tailscale Not Connecting

```bash
# Check Tailscale status
tailscale status

# Restart Tailscale
sudo tailscale down
sudo tailscale up

# Verify firewall allows Tailscale
sudo ufw allow in on tailscale0
```

### SSH Keeps Disconnecting

```bash
# Add to ~/.ssh/config on client:
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3

# Or switch to Mosh for mobile
```

### Web Terminal Not Loading

```bash
# Check if service is running
ps aux | grep gotty

# Verify port is accessible
sudo netstat -tlnp | grep 8080

# Check firewall
sudo ufw status
```

## Security Best Practices

1. **Always use key-based SSH authentication**
2. **Enable Tailscale for private networking**
3. **Use Mosh over Tailscale (not public internet)**
4. **Enable TLS for any web terminals**
5. **Use strong passwords for web auth**
6. **Regularly rotate API keys**
7. **Monitor access logs**
8. **Use fail2ban for SSH brute-force protection**

## Performance Tips

### For Mobile Connections

```bash
# In ~/.ssh/config:
Host agent-server
    HostName 100.x.y.z  # Tailscale IP
    User claude-agent
    Compression yes
    ServerAliveInterval 30
    ServerAliveCountMax 3

# Use mosh instead of SSH for better responsiveness
```

### For Low Bandwidth

```bash
# Reduce tmux status bar updates
set -g status-interval 5  # in .tmux.conf

# Use simpler terminal
export TERM=xterm-256color
```

## Next Steps

1. Configure Claude Code for autonomous operation → See `04-claude-configuration.md`
2. Implement security hardening → See `06-security.md`
3. Review cost optimization strategies → See `05-cost-optimization.md`

## Resources

- **Tailscale Docs**: https://tailscale.com/kb/
- **Mosh Project**: https://mosh.org/
- **VibeTunnel**: https://github.com/amantus-ai/vibetunnel
- **Blink Shell**: https://blink.sh/
- **Community guides**: Multiple mobile setup guides from 2025
