#!/bin/bash
set -e

###############################################################################
# Claude Code CLI Installation Script
#
# This script installs Claude Code CLI and sets up the environment for
# running continuous agents on OVHCloud.
#
# Usage:
#   Run as the agent user (NOT root):
#   bash 02-install-claude.sh
#
# Prerequisites:
#   - Server setup completed (01-server-setup.sh)
#   - Logged in as agent user
#   - Anthropic API key ready
#
# What this does:
#   - Installs Node.js 20.x
#   - Installs Claude Code CLI globally
#   - Configures API key
#   - Verifies installation
#   - Sets up environment
###############################################################################

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_prompt() {
    echo -e "${BLUE}[INPUT]${NC} $1"
}

check_not_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should NOT be run as root"
        log_error "Please run as your agent user (e.g., claude-agent)"
        exit 1
    fi
}

check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check if running on Ubuntu/Debian
    if [ ! -f /etc/os-release ]; then
        log_error "Cannot detect OS. This script is for Ubuntu/Debian."
        exit 1
    fi

    . /etc/os-release
    if [[ "$ID" != "ubuntu" && "$ID" != "debian" ]]; then
        log_error "This script is designed for Ubuntu/Debian. Detected: $ID"
        exit 1
    fi

    log_info "Prerequisites check passed"
}

install_nodejs() {
    log_info "Installing Node.js 20.x..."

    # Check if Node.js is already installed
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version)
        log_warn "Node.js is already installed: $NODE_VERSION"
        read -p "Do you want to reinstall? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Skipping Node.js installation"
            return
        fi
    fi

    # Install Node.js from NodeSource
    log_info "Adding NodeSource repository..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -

    log_info "Installing Node.js and npm..."
    sudo apt install -y nodejs

    # Verify installation
    NODE_VERSION=$(node --version)
    NPM_VERSION=$(npm --version)

    log_info "Node.js installed: $NODE_VERSION"
    log_info "npm installed: $NPM_VERSION"
}

install_claude_code() {
    log_info "Installing Claude Code CLI..."

    # Check if already installed
    if command -v claude &> /dev/null; then
        CLAUDE_VERSION=$(claude --version 2>&1 || echo "unknown")
        log_warn "Claude Code CLI is already installed: $CLAUDE_VERSION"
        read -p "Do you want to reinstall/upgrade? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Skipping Claude Code installation"
            return
        fi
    fi

    # Install Claude Code globally
    sudo npm install -g @anthropic-ai/claude-code

    log_info "Claude Code CLI installed successfully"
}

verify_installation() {
    log_info "Verifying installation..."

    # Check if claude command is available
    if ! command -v claude &> /dev/null; then
        log_error "Claude Code CLI not found in PATH"
        log_error "Installation may have failed"
        exit 1
    fi

    # Get version
    CLAUDE_VERSION=$(claude --version 2>&1)
    log_info "Claude Code CLI version: $CLAUDE_VERSION"

    log_info "Installation verified successfully"
}

configure_authentication() {
    log_info "Configuring Claude Code authentication..."

    echo ""
    echo "Choose authentication method:"
    echo ""
    echo "  1) Max Plan Login (Recommended for cost savings)"
    echo "     - Uses your claude.ai Max Plan subscription (\$100/mo)"
    echo "     - ~225 messages/5hrs shared across all agents"
    echo "     - Best for: 5-10 agents with moderate usage"
    echo ""
    echo "  2) API Key (Pay-per-token)"
    echo "     - Uses Anthropic API with pay-per-use billing"
    echo "     - Separate from claude.ai subscription"
    echo "     - Best for: High-volume usage or 20+ agents"
    echo ""
    log_prompt "Select option (1 or 2):"
    read -r AUTH_CHOICE

    case $AUTH_CHOICE in
        1)
            configure_max_plan_login
            ;;
        2)
            configure_api_key
            ;;
        *)
            log_error "Invalid choice. Please run the script again."
            exit 1
            ;;
    esac
}

configure_max_plan_login() {
    log_info "Setting up Max Plan authentication..."
    echo ""
    log_info "After this script completes, run:"
    echo ""
    echo "  claude login"
    echo ""
    log_info "You'll authenticate with your claude.ai account credentials."
    log_info "This will use your Max Plan subscription limits."
    echo ""
    log_warn "IMPORTANT: All agents on this VM will share the ~225 messages/5hr limit."
    log_warn "Monitor usage and switch to API key if you hit rate limits frequently."
    echo ""

    # Add a note to .bashrc
    if ! grep -q "Claude Code Max Plan" ~/.bashrc; then
        cat >> ~/.bashrc <<'EOF'

# Claude Code Authentication
# Using Max Plan login (claude.ai subscription)
# Run 'claude login' to authenticate if needed
# Rate limit: ~225 messages per 5 hours shared across all agents
EOF
        log_info "Authentication note added to ~/.bashrc"
    fi

    log_info "Max Plan authentication setup complete"
    log_info "Remember to run 'claude login' after installation!"
}

configure_api_key() {
    log_info "Setting up API key authentication..."

    # Check if API key is already set
    if [ -n "$ANTHROPIC_API_KEY" ]; then
        log_warn "ANTHROPIC_API_KEY is already set in environment"
        echo "Current key: ${ANTHROPIC_API_KEY:0:20}..."
        read -p "Do you want to update it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Keeping existing API key"
            return
        fi
    fi

    # Prompt for API key
    echo ""
    log_prompt "Please enter your Anthropic API key:"
    log_prompt "(Get it from: https://console.anthropic.com/settings/keys)"
    read -r API_KEY

    # Validate API key format
    if [[ ! $API_KEY =~ ^sk-ant- ]]; then
        log_warn "API key doesn't match expected format (should start with 'sk-ant-')"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_error "API key configuration cancelled"
            exit 1
        fi
    fi

    # Add to .bashrc
    if ! grep -q "ANTHROPIC_API_KEY" ~/.bashrc; then
        echo "" >> ~/.bashrc
        echo "# Anthropic API Key for Claude Code" >> ~/.bashrc
        echo "# Using pay-per-token billing (separate from claude.ai subscription)" >> ~/.bashrc
        echo "export ANTHROPIC_API_KEY=\"$API_KEY\"" >> ~/.bashrc
        log_info "API key added to ~/.bashrc"
    else
        # Update existing entry
        sed -i "s|export ANTHROPIC_API_KEY=.*|export ANTHROPIC_API_KEY=\"$API_KEY\"|g" ~/.bashrc
        log_info "API key updated in ~/.bashrc"
    fi

    # Set for current session
    export ANTHROPIC_API_KEY="$API_KEY"

    log_info "API key configured successfully"
}

test_authentication() {
    log_info "Testing Claude Code CLI..."

    # Create a simple test to verify the CLI works
    if claude --help > /dev/null 2>&1; then
        log_info "Claude Code CLI is working correctly"
    else
        log_warn "Claude Code CLI test failed, but this may be normal"
    fi

    echo ""
    if [ -n "$ANTHROPIC_API_KEY" ]; then
        log_info "API key is configured. Test with:"
        echo "  claude -p 'Hello, Claude!'"
    else
        log_info "Remember to authenticate before testing:"
        echo "  claude login"
        echo ""
        log_info "Then test with:"
        echo "  claude -p 'Hello, Claude!'"
    fi
}

setup_environment() {
    log_info "Setting up environment..."

    # Create aliases for convenience
    if ! grep -q "alias claude-status" ~/.bashrc; then
        cat >> ~/.bashrc <<'EOF'

# Claude Code aliases
alias claude-status='tmux ls 2>/dev/null || echo "No active sessions"'
alias claude-attach='tmux attach -t'
alias claude-logs='tail -f ~/agents/logs/*.log'
EOF
        log_info "Convenience aliases added to ~/.bashrc"
    fi

    log_info "Environment setup complete"
}

create_sample_config() {
    log_info "Creating sample configuration..."

    # Create a sample .claude.json if it doesn't exist
    if [ ! -f ~/.claude/config.json ]; then
        mkdir -p ~/.claude
        cat > ~/.claude/config.json <<'EOF'
{
  "defaultModel": "claude-sonnet-4-5",
  "temperature": 0.7,
  "maxTokens": 4096
}
EOF
        log_info "Sample config created at ~/.claude/config.json"
    else
        log_info "Config file already exists, skipping"
    fi
}

print_summary() {
    echo ""
    log_info "================================================"
    log_info "Claude Code CLI installation completed!"
    log_info "================================================"
    echo ""
    echo "Installation summary:"
    echo "  - Node.js: $(node --version)"
    echo "  - npm: $(npm --version)"
    echo "  - Claude Code: $(claude --version 2>&1 || echo 'installed')"
    echo ""
    echo "Next steps:"
    echo ""
    echo "1. Reload your shell environment:"
    echo "   source ~/.bashrc"
    echo ""
    echo "2. Test Claude Code:"
    echo "   claude -p 'Hello, Claude!'"
    echo ""
    echo "3. Set up tmux configuration:"
    echo "   cp config/.tmux.conf ~/.tmux.conf"
    echo ""
    echo "4. Start your first agent:"
    echo "   bash scripts/setup/start-agent.sh"
    echo ""
    log_info "For detailed usage, see IMPLEMENTATION.md"
    echo ""
}

# Main execution
main() {
    log_info "Starting Claude Code CLI installation..."
    echo ""

    check_not_root
    check_prerequisites
    install_nodejs
    install_claude_code
    verify_installation
    configure_authentication
    setup_environment
    create_sample_config
    test_authentication

    print_summary
}

# Run main function
main
