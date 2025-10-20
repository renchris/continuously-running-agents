#!/bin/bash
set -e

###############################################################################
# GitHub Authentication Setup Script
#
# This script configures GitHub access for Claude Code agents, including:
# - Git user configuration
# - SSH key generation and setup
# - GitHub CLI installation and authentication
#
# Usage:
#   Run as the agent user (NOT root):
#   bash 03-github-auth.sh
#
# Prerequisites:
#   - Server setup completed (01-server-setup.sh)
#   - Claude Code installed (02-install-claude.sh)
#   - GitHub account with repository access
#
# What this does:
#   - Configures git user.name and user.email
#   - Generates SSH key for GitHub authentication
#   - Installs GitHub CLI (gh)
#   - Guides through GitHub authentication
#   - Tests connectivity and permissions
#   - Sets up git aliases and helper scripts
###############################################################################

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

log_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
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

    # Check if git is installed
    if ! command -v git &> /dev/null; then
        log_error "Git is not installed"
        log_error "Run 01-server-setup.sh first to install git"
        exit 1
    fi

    log_info "Git version: $(git --version)"
    log_info "Prerequisites check passed"
}

configure_git_user() {
    log_step "Configuring Git user identity..."

    # Check if already configured
    GIT_NAME=$(git config --global user.name 2>/dev/null || echo "")
    GIT_EMAIL=$(git config --global user.email 2>/dev/null || echo "")

    if [ -n "$GIT_NAME" ] && [ -n "$GIT_EMAIL" ]; then
        log_info "Git user already configured:"
        echo "  Name:  $GIT_NAME"
        echo "  Email: $GIT_EMAIL"
        echo ""
        read -p "Do you want to update these? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Keeping existing git configuration"
            return
        fi
    fi

    # Prompt for git name
    echo ""
    log_prompt "Enter your name for git commits (e.g., 'Claude Agent'):"
    read -r GIT_NAME
    if [ -z "$GIT_NAME" ]; then
        log_error "Name cannot be empty"
        exit 1
    fi

    # Prompt for git email
    log_prompt "Enter your email for git commits:"
    read -r GIT_EMAIL
    if [ -z "$GIT_EMAIL" ]; then
        log_error "Email cannot be empty"
        exit 1
    fi

    # Configure git
    git config --global user.name "$GIT_NAME"
    git config --global user.email "$GIT_EMAIL"

    log_info "Git user configured:"
    echo "  Name:  $(git config --global user.name)"
    echo "  Email: $(git config --global user.email)"
}

generate_ssh_key() {
    log_step "Setting up SSH key for GitHub..."

    # Check if SSH key already exists
    if [ -f ~/.ssh/id_ed25519 ]; then
        log_warn "SSH key already exists at ~/.ssh/id_ed25519"
        echo ""
        read -p "Do you want to generate a new key? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Using existing SSH key"
            display_public_key
            return
        fi

        # Back up existing key
        BACKUP_FILE=~/.ssh/id_ed25519.backup.$(date +%Y%m%d-%H%M%S)
        cp ~/.ssh/id_ed25519 "$BACKUP_FILE"
        cp ~/.ssh/id_ed25519.pub "$BACKUP_FILE.pub"
        log_info "Existing key backed up to $BACKUP_FILE"
    fi

    # Generate new SSH key
    log_info "Generating new ED25519 SSH key..."

    # Get email for key comment
    GIT_EMAIL=$(git config --global user.email)
    KEY_COMMENT="${GIT_EMAIL}@claude-agent"

    ssh-keygen -t ed25519 -C "$KEY_COMMENT" -f ~/.ssh/id_ed25519 -N ""

    log_info "SSH key generated successfully"

    # Start ssh-agent and add key
    eval "$(ssh-agent -s)" > /dev/null 2>&1
    ssh-add ~/.ssh/id_ed25519 > /dev/null 2>&1

    display_public_key
}

display_public_key() {
    echo ""
    log_info "========================================"
    log_info "Your SSH public key:"
    log_info "========================================"
    cat ~/.ssh/id_ed25519.pub
    echo ""
    log_info "========================================"
    echo ""

    log_info "NEXT STEP: Add this key to your GitHub account"
    echo ""
    echo "1. Copy the key above (entire line starting with 'ssh-ed25519')"
    echo "2. Go to: https://github.com/settings/keys"
    echo "3. Click 'New SSH key'"
    echo "4. Title: 'Hetzner Claude Agent' (or similar)"
    echo "5. Paste the key"
    echo "6. Click 'Add SSH key'"
    echo ""

    # Save to file for easy access
    cat ~/.ssh/id_ed25519.pub > ~/github-ssh-key.txt
    log_info "Public key also saved to: ~/github-ssh-key.txt"
    echo ""

    read -p "Press ENTER after you've added the key to GitHub..." -r
}

test_github_ssh() {
    log_step "Testing SSH connection to GitHub..."

    # Test SSH connection
    echo ""
    log_info "Attempting to connect to GitHub..."

    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        log_info "✓ SSH connection to GitHub successful!"
    else
        # Show the actual output for debugging
        log_warn "SSH test output:"
        ssh -T git@github.com 2>&1 || true
        echo ""
        log_warn "If you see 'Permission denied', the SSH key may not be added correctly"
        log_warn "If you see 'Hi [username]!', the connection is working"
        echo ""
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_error "SSH authentication failed. Please check your SSH key setup."
            exit 1
        fi
    fi
}

install_github_cli() {
    log_step "Installing GitHub CLI (gh)..."

    # Check if gh is already installed
    if command -v gh &> /dev/null; then
        GH_VERSION=$(gh --version | head -1)
        log_warn "GitHub CLI is already installed: $GH_VERSION"
        echo ""
        read -p "Do you want to reinstall/upgrade? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Skipping GitHub CLI installation"
            return
        fi
    fi

    log_info "Adding GitHub CLI repository..."

    # Add GitHub CLI repository
    sudo mkdir -p -m 755 /etc/apt/keyrings
    wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
        sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
        sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

    log_info "Updating package lists..."
    sudo apt update > /dev/null 2>&1

    log_info "Installing GitHub CLI..."
    sudo apt install -y gh > /dev/null 2>&1

    log_info "GitHub CLI installed: $(gh --version | head -1)"
}

authenticate_github_cli() {
    log_step "Authenticating GitHub CLI..."

    # Check if already authenticated
    if gh auth status > /dev/null 2>&1; then
        log_info "GitHub CLI is already authenticated"
        echo ""
        gh auth status
        echo ""
        read -p "Do you want to re-authenticate? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Keeping existing GitHub CLI authentication"
            return
        fi
    fi

    echo ""
    log_info "Starting GitHub CLI authentication..."
    log_info "You'll be prompted to authenticate via browser"
    echo ""

    # Run gh auth login
    gh auth login

    echo ""
    log_info "GitHub CLI authentication complete!"
}

verify_github_access() {
    log_step "Verifying GitHub access..."

    echo ""
    log_info "Testing GitHub CLI authentication..."

    if gh auth status > /dev/null 2>&1; then
        log_info "✓ GitHub CLI is authenticated"
        echo ""
        gh auth status
    else
        log_error "GitHub CLI authentication failed"
        exit 1
    fi

    echo ""
    log_info "Testing repository access..."

    # Try to list repos (just first 3)
    if gh repo list --limit 3 > /dev/null 2>&1; then
        log_info "✓ Can access GitHub repositories"
        echo ""
        log_info "Your repositories:"
        gh repo list --limit 5
    else
        log_warn "Could not list repositories, but authentication may still be working"
    fi
}

setup_git_helpers() {
    log_step "Setting up Git helpers and aliases..."

    # Configure git to use SSH for GitHub
    git config --global url."git@github.com:".insteadOf "https://github.com/"
    log_info "Configured git to use SSH for GitHub URLs"

    # Add helpful git aliases if not already present
    if ! grep -q "alias git-status" ~/.bashrc; then
        cat >> ~/.bashrc <<'EOF'

# Git and GitHub aliases for Claude Code agents
alias git-status='git status -sb'
alias git-log='git log --oneline --graph --decorate -10'
alias gh-prs='gh pr list'
alias gh-issues='gh issue list'
EOF
        log_info "Git aliases added to ~/.bashrc"
    fi

    # Configure git pull to rebase by default (cleaner history)
    git config --global pull.rebase true
    log_info "Configured git pull to use rebase by default"

    # Configure default branch name
    git config --global init.defaultBranch main
    log_info "Set default branch name to 'main'"
}

create_usage_guide() {
    log_step "Creating usage guide..."

    cat > ~/github-access-guide.txt <<'EOF'
GitHub Access Guide for Claude Code Agents
==========================================

Your GitHub access is configured with:

1. SSH Authentication (for git operations)
   - Clone: git clone git@github.com:username/repo.git
   - Push:  git push origin main
   - Pull:  git pull origin main

2. GitHub CLI (for GitHub API operations)
   - List repos:    gh repo list
   - Create PR:     gh pr create
   - List PRs:      gh pr list
   - Create issue:  gh issue create
   - View PR:       gh pr view 123

3. Helpful Aliases
   - git-status:    Short git status
   - git-log:       Compact git log
   - gh-prs:        List pull requests
   - gh-issues:     List issues

Common Tasks:
-------------

Clone a repository:
  git clone git@github.com:username/repo.git
  cd repo

Create a branch and push:
  git checkout -b feature-branch
  # Make changes
  git add .
  git commit -m "feat: description"
  git push -u origin feature-branch

Create a PR:
  gh pr create --title "Feature title" --body "Description"

Check PR status:
  gh pr status

Merge a PR:
  gh pr merge 123 --squash

Authentication Files:
---------------------
- SSH key: ~/.ssh/id_ed25519
- GitHub CLI auth: ~/.config/gh/hosts.yml
- Git config: ~/.gitconfig

Troubleshooting:
----------------
- Test SSH: ssh -T git@github.com
- Check gh auth: gh auth status
- Refresh token: gh auth refresh

EOF

    log_info "Usage guide created: ~/github-access-guide.txt"
}

print_summary() {
    echo ""
    log_info "========================================"
    log_info "GitHub authentication setup complete!"
    log_info "========================================"
    echo ""
    echo "Configuration summary:"
    echo "  - Git user: $(git config --global user.name) <$(git config --global user.email)>"
    echo "  - SSH key: ~/.ssh/id_ed25519"
    echo "  - GitHub CLI: $(gh --version 2>&1 | head -1 || echo 'installed')"
    echo ""
    echo "GitHub Permissions:"
    echo "  ✓ Clone private repositories"
    echo "  ✓ Push commits"
    echo "  ✓ Create branches"
    echo "  ✓ Create pull requests"
    echo "  ✓ Manage issues"
    echo "  ✓ Create releases"
    echo "  ✓ Full GitHub API access"
    echo ""
    echo "Quick Test:"
    echo "  # Test SSH connection"
    echo "  ssh -T git@github.com"
    echo ""
    echo "  # Test GitHub CLI"
    echo "  gh repo list"
    echo ""
    echo "  # Clone a repo (example)"
    echo "  git clone git@github.com:username/repo.git"
    echo ""
    echo "Usage Guide: ~/github-access-guide.txt"
    echo ""
    log_info "Your Claude Code agents can now:"
    echo "  - Clone and work with repositories"
    echo "  - Push commits and create branches"
    echo "  - Create pull requests automatically"
    echo "  - Manage issues and releases"
    echo ""
}

# Main execution
main() {
    log_info "Starting GitHub authentication setup..."
    echo ""

    check_not_root
    check_prerequisites
    configure_git_user
    generate_ssh_key
    test_github_ssh
    install_github_cli
    authenticate_github_cli
    verify_github_access
    setup_git_helpers
    create_usage_guide

    print_summary

    echo ""
    log_info "Reload your shell to use new aliases:"
    echo "  source ~/.bashrc"
    echo ""
}

# Run main function
main
