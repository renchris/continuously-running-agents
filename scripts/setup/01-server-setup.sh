#!/bin/bash
set -e

###############################################################################
# OVHCloud Server Initial Setup Script
#
# This script performs the initial setup of your OVHCloud instance for
# running continuous Claude Code agents.
#
# Usage:
#   Run as root on fresh Ubuntu 24.04 LTS instance:
#   curl -fsSL https://raw.githubusercontent.com/... | bash
#   Or: bash 01-server-setup.sh
#
# What this does:
#   - Updates system packages
#   - Creates non-root user for agents
#   - Configures SSH security
#   - Sets up firewall (UFW)
#   - Installs essential tools
#   - Configures fail2ban
###############################################################################

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
AGENT_USER="${AGENT_USER:-claude-agent}"
SSH_PORT="${SSH_PORT:-22}"

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

update_system() {
    log_info "Updating system packages..."
    apt update
    apt upgrade -y
    log_info "System updated successfully"
}

install_essentials() {
    log_info "Installing essential packages..."
    apt install -y \
        curl \
        wget \
        git \
        tmux \
        mosh \
        htop \
        iotop \
        nethogs \
        fail2ban \
        ufw \
        build-essential \
        ca-certificates \
        gnupg \
        jq \
        vim \
        nano
    log_info "Essential packages installed"
}

create_agent_user() {
    log_info "Creating user: $AGENT_USER"

    if id "$AGENT_USER" &>/dev/null; then
        log_warn "User $AGENT_USER already exists, skipping..."
        return
    fi

    # Create user with home directory
    adduser --disabled-password --gecos "" $AGENT_USER

    # Add to sudo group
    usermod -aG sudo $AGENT_USER

    # Allow passwordless sudo for this user (optional, comment if you want password)
    echo "$AGENT_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$AGENT_USER
    chmod 0440 /etc/sudoers.d/$AGENT_USER

    log_info "User $AGENT_USER created successfully"
}

setup_ssh_keys() {
    log_info "Setting up SSH keys for $AGENT_USER"

    # Create .ssh directory
    mkdir -p /home/$AGENT_USER/.ssh
    chmod 700 /home/$AGENT_USER/.ssh

    # Copy root's authorized_keys if it exists
    if [ -f /root/.ssh/authorized_keys ]; then
        cp /root/.ssh/authorized_keys /home/$AGENT_USER/.ssh/
        log_info "Copied SSH keys from root"
    else
        log_warn "No root SSH keys found. You'll need to add them manually."
        log_warn "After setup, add your public key to: /home/$AGENT_USER/.ssh/authorized_keys"
    fi

    # Set correct permissions
    chmod 600 /home/$AGENT_USER/.ssh/authorized_keys 2>/dev/null || true
    chown -R $AGENT_USER:$AGENT_USER /home/$AGENT_USER/.ssh

    log_info "SSH keys configured"
}

configure_firewall() {
    log_info "Configuring UFW firewall..."

    # Set default policies
    ufw --force default deny incoming
    ufw --force default allow outgoing

    # Allow SSH
    ufw allow $SSH_PORT/tcp comment 'SSH'

    # Allow Mosh (for mobile access)
    ufw allow 60000:61000/udp comment 'Mosh'

    # Enable firewall
    ufw --force enable

    log_info "Firewall configured and enabled"
}

configure_fail2ban() {
    log_info "Configuring fail2ban..."

    # Create custom SSH jail
    cat > /etc/fail2ban/jail.d/sshd.local <<EOF
[sshd]
enabled = true
port = $SSH_PORT
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
findtime = 600
EOF

    # Start and enable fail2ban
    systemctl enable fail2ban
    systemctl restart fail2ban

    log_info "fail2ban configured and started"
}

configure_ssh_hardening() {
    log_info "Applying SSH security hardening..."

    # Backup original sshd_config
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

    # Apply security settings
    cat >> /etc/ssh/sshd_config <<EOF

# Added by agent setup script
PermitRootLogin prohibit-password
PasswordAuthentication no
PubkeyAuthentication yes
PermitEmptyPasswords no
X11Forwarding no
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
EOF

    log_info "SSH hardening applied (restart SSH to apply)"
}

create_directory_structure() {
    log_info "Creating directory structure for agent..."

    # Create directories for agent operations
    sudo -u $AGENT_USER mkdir -p /home/$AGENT_USER/{projects,scripts,logs,backups}
    sudo -u $AGENT_USER mkdir -p /home/$AGENT_USER/agents/{logs,coordination}

    log_info "Directory structure created"
}

optimize_system() {
    log_info "Applying system optimizations..."

    # Increase file descriptor limits
    cat >> /etc/security/limits.conf <<EOF

# Agent optimizations
$AGENT_USER soft nofile 65536
$AGENT_USER hard nofile 65536
EOF

    # Optimize for agent workloads
    cat >> /etc/sysctl.conf <<EOF

# Agent optimizations
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
vm.swappiness = 10
EOF

    sysctl -p > /dev/null

    log_info "System optimizations applied"
}

setup_log_rotation() {
    log_info "Configuring log rotation..."

    cat > /etc/logrotate.d/claude-agent <<EOF
/home/$AGENT_USER/logs/*.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
    create 0644 $AGENT_USER $AGENT_USER
}

/home/$AGENT_USER/agents/logs/*.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
    create 0644 $AGENT_USER $AGENT_USER
}
EOF

    log_info "Log rotation configured"
}

print_summary() {
    echo ""
    log_info "======================================"
    log_info "Server setup completed successfully!"
    log_info "======================================"
    echo ""
    echo "Next steps:"
    echo "1. Test SSH connection as $AGENT_USER:"
    echo "   ssh $AGENT_USER@YOUR_SERVER_IP"
    echo ""
    echo "2. After successful login, run the Claude Code installation script:"
    echo "   bash 02-install-claude.sh"
    echo ""
    echo "3. (Optional) Restart SSH to apply hardening:"
    echo "   sudo systemctl restart sshd"
    echo ""
    log_warn "IMPORTANT: Make sure you can login as $AGENT_USER before restarting SSH!"
    echo ""
}

# Main execution
main() {
    log_info "Starting OVHCloud server setup..."
    echo ""

    check_root
    update_system
    install_essentials
    create_agent_user
    setup_ssh_keys
    configure_firewall
    configure_fail2ban
    configure_ssh_hardening
    create_directory_structure
    optimize_system
    setup_log_rotation

    print_summary
}

# Run main function
main
