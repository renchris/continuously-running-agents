# Machine User Setup Guide

## Overview

This guide provides step-by-step instructions for setting up a dedicated GitHub machine user account for your continuously running AI agent. A machine user is a separate GitHub account used exclusively for automation, providing better security isolation and audit trails compared to using your personal account.

## Table of Contents

- [Why Use a Machine User?](#why-use-a-machine-user)
- [Prerequisites](#prerequisites)
- [Part 1: GitHub Machine User Account Setup](#part-1-github-machine-user-account-setup)
- [Part 2: SSH Key Generation and Configuration](#part-2-ssh-key-generation-and-configuration)
- [Part 3: Repository Access and Permissions](#part-3-repository-access-and-permissions)
- [Part 4: Git Configuration on Server](#part-4-git-configuration-on-server)
- [Part 5: Branch Protection Configuration](#part-5-branch-protection-configuration)
- [Part 6: Testing and Verification](#part-6-testing-and-verification)
- [Security Best Practices](#security-best-practices)
- [Troubleshooting](#troubleshooting)

## Why Use a Machine User?

### Benefits

1. **Security Isolation**: Separate credentials from your personal account
2. **Audit Trail**: Clear distinction between human and automated commits
3. **Access Control**: Granular permissions without compromising personal account
4. **Revocability**: Easy to revoke access without affecting your personal workflows
5. **Compliance**: Many organizations require separate service accounts
6. **Rate Limits**: Separate API rate limits from your personal account

### Real-World Example

The `renchris/continuously-running-agents` repository uses a machine user `@renchris-agent` with email `ren.chris+agent@outlook.com`, demonstrating the pattern in production.

## Prerequisites

- [ ] Active GitHub personal account (repository owner)
- [ ] New email address for machine user (e.g., `your.name+agent@gmail.com`)
- [ ] SSH access to your server/VM where the agent runs
- [ ] Repository owner permissions on target repository
- [ ] Basic understanding of SSH keys and Git

**Time Estimate**: 30-45 minutes for first-time setup

## Part 1: GitHub Machine User Account Setup

### Step 1.1: Create Email Address

GitHub requires a unique email for each account. Use email aliasing:

```bash
# Gmail example (supports + aliasing)
Personal:      your.name@gmail.com
Machine User:  your.name+agent@gmail.com

# Outlook example
Personal:      your.name@outlook.com
Machine User:  your.name+agent@outlook.com

# Custom domain (if available)
Personal:      you@yourdomain.com
Machine User:  agent@yourdomain.com
```

**Note**: Both emails will deliver to the same inbox, simplifying 2FA and notifications.

### Step 1.2: Sign Out of Personal GitHub

```bash
# In your browser:
# 1. Go to github.com
# 2. Click your profile picture → Sign out
# 3. Use incognito/private window for next steps (recommended)
```

**Tip**: Use a separate browser profile to keep machine user sessions separate.

### Step 1.3: Create Machine User Account

1. Navigate to https://github.com/signup
2. Fill in the registration form:
   - **Email**: `your.name+agent@gmail.com`
   - **Password**: Use a strong, unique password (store in password manager)
   - **Username**: `yourname-agent` (e.g., `renchris-agent`)
3. Complete verification (email verification, puzzle, etc.)
4. Choose "Free" plan (sufficient for machine users)
5. Skip personalization questions

### Step 1.4: Configure Machine User Profile

1. Go to **Settings** → **Profile**
2. Set **Public profile**:
   - **Name**: `Your Name (Agent)` or `@yourname Agent`
   - **Bio**: `🤖 Automated agent for @yourname's repositories. Running continuously via Claude Code.`
   - **Company**: (Optional) Same as personal account
   - **Location**: (Optional) `Running on Hetzner Cloud` or your provider
3. **Avatar**: Use a robot emoji or distinct avatar to differentiate from personal account

Example profile (based on `@renchris-agent`):
```
Name: Chris Ren (Agent)
Bio: 🤖 Automated CI/CD agent for @renchris repositories
Location: Hetzner Cloud - Nuremberg, Germany
```

### Step 1.5: Enable Two-Factor Authentication (Recommended)

1. Go to **Settings** → **Password and authentication**
2. Click **Enable two-factor authentication**
3. Choose **Authenticator app** method
4. Scan QR code with your authenticator app (same app as personal account)
5. **Save recovery codes** in password manager

**Important**: Store recovery codes securely. If you lose access, recovering a machine account is harder than a personal account.

## Part 2: SSH Key Generation and Configuration

### Step 2.1: Generate Dedicated SSH Key Pair

On your **server/VM** where the agent runs:

```bash
# Connect to your server
ssh user@your-server-ip

# Create .ssh directory if it doesn't exist
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Generate ED25519 key (recommended) or RSA
ssh-keygen -t ed25519 -C "your.name+agent@gmail.com" -f ~/.ssh/id_ed25519_github_agent

# Alternative: RSA key (if ED25519 not supported)
# ssh-keygen -t rsa -b 4096 -C "your.name+agent@gmail.com" -f ~/.ssh/id_rsa_github_agent
```

**Passphrase Decision**:
- **With passphrase**: More secure, but requires SSH agent or manual entry
- **Without passphrase**: Easier automation, acceptable with proper server security

For continuously running agents with secure server setup (see [06-security.md](06-security.md)), a passphraseless key is acceptable.

### Step 2.2: Add SSH Key to GitHub Machine User

```bash
# Display public key
cat ~/.ssh/id_ed25519_github_agent.pub
# Copy the entire output (starts with "ssh-ed25519 ...")
```

In browser (still logged in as machine user):

1. Go to **Settings** → **SSH and GPG keys**
2. Click **New SSH key**
3. Fill in:
   - **Title**: `Hetzner Cloud Agent Server` (or your server name)
   - **Key type**: `Authentication Key`
   - **Key**: Paste the public key content
4. Click **Add SSH key**
5. Confirm with password/2FA if prompted

### Step 2.3: Configure SSH Client

Create SSH config to use machine user key for GitHub:

```bash
# Edit SSH config
nano ~/.ssh/config
```

Add this configuration:

```ssh-config
# GitHub - Machine User Account
Host github.com-agent
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_github_agent
    IdentitiesOnly yes
    AddKeysToAgent yes

# Optional: Keep your personal GitHub separate
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519  # Your personal key
    IdentitiesOnly yes
```

Set proper permissions:

```bash
chmod 600 ~/.ssh/config
chmod 600 ~/.ssh/id_ed25519_github_agent
chmod 644 ~/.ssh/id_ed25519_github_agent.pub
```

### Step 2.4: Test SSH Connection

```bash
# Test machine user SSH connection
ssh -T git@github.com-agent

# Expected output:
# Hi yourname-agent! You've successfully authenticated, but GitHub does not provide shell access.
```

**Troubleshooting**: If connection fails, see [Troubleshooting](#troubleshooting) section.

## Part 3: Repository Access and Permissions

### Step 3.1: Invite Machine User as Collaborator

**Using GitHub Web Interface** (as repository owner):

1. Sign out of machine user account
2. Sign in to your **personal account** (repository owner)
3. Navigate to your repository (e.g., `yourname/continuously-running-agents`)
4. Go to **Settings** → **Collaborators and teams**
5. Click **Add people**
6. Search for machine user username (e.g., `yourname-agent`)
7. Select **Write** permission level (or **Maintain** if you want branch management)
8. Click **Add yourname-agent to this repository**

**Using GitHub CLI** (faster):

```bash
# From your local machine or server (authenticated as personal account)
gh api repos/yourname/continuously-running-agents/collaborators/yourname-agent \
  -X PUT \
  -f permission=push
```

### Step 3.2: Accept Invitation (Machine User)

**Option A**: Email notification
1. Check inbox for `your.name+agent@gmail.com`
2. Click invitation link
3. Accept invitation

**Option B**: GitHub web interface
1. Sign in as machine user
2. Go to https://github.com/yourname-agent
3. Look for notification banner at top
4. Click **View invitation** → **Accept invitation**

**Option C**: GitHub CLI (on server)
```bash
# List pending invitations
gh api user/repository_invitations

# Accept invitation (replace INVITATION_ID)
gh api user/repository_invitations/INVITATION_ID -X PATCH
```

### Step 3.3: Verify Access

```bash
# On server (as machine user)
gh auth login
# Choose: GitHub.com → SSH → Yes (upload key) → Paste authentication token

# Verify repository access
gh repo view yourname/continuously-running-agents

# Test clone
git clone git@github.com-agent:yourname/continuously-running-agents.git test-clone
cd test-clone
# Should succeed without errors
cd ..
rm -rf test-clone
```

## Part 4: Git Configuration on Server

### Step 4.1: Configure Git Identity

```bash
# Global git config for machine user
git config --global user.name "Your Name (Agent)"
git config --global user.email "your.name+agent@gmail.com"

# Verify configuration
git config --global --list | grep user
```

### Step 4.2: Configure Git to Use Machine User SSH

For the agent's working directory:

```bash
cd ~/projects/continuously-running-agents

# Set repository-specific remote to use machine user SSH host
git remote set-url origin git@github.com-agent:yourname/continuously-running-agents.git

# Verify
git remote -v
# Should show:
# origin  git@github.com-agent:yourname/continuously-running-agents.git (fetch)
# origin  git@github.com-agent:yourname/continuously-running-agents.git (push)
```

### Step 4.3: Test Push Access

```bash
# Create test commit
echo "Test machine user setup - $(date)" >> README.md
git add README.md
git commit -m "test: machine user configuration"

# Push to remote
git push origin main

# Should succeed without password prompt
# Verify on GitHub that commit shows machine user as author
```

## Part 5: Branch Protection Configuration

This section documents a **critical discovery** about GitHub branch protection and repository owners.

### Understanding Branch Protection Bypass

GitHub branch protection has a setting called `enforce_admins` that controls whether repository administrators (including owners) can bypass protection rules.

**Key Discovery**: Setting `enforce_admins: false` allows repository owners to push directly to protected branches, **even if they're using a machine user account that is the owner**.

### The `enforce_admins` Behavior

| Scenario | `enforce_admins: true` | `enforce_admins: false` |
|----------|----------------------|------------------------|
| **Repository Owner** (personal account) | ❌ Cannot bypass protection | ✅ Can bypass protection |
| **Repository Owner** (machine user that owns repo) | ❌ Cannot bypass protection | ✅ Can bypass protection |
| **Collaborator with Write** | ❌ Must follow rules | ❌ Must follow rules |
| **Collaborator with Admin** | ❌ Must follow rules | ✅ Can bypass protection |

### Recommended Configuration for Machine Users

#### Option A: Machine User as Collaborator (Recommended)

**Best for**: Most users wanting standard PR workflow with automation

```bash
# Setup:
# 1. Your personal account owns the repository
# 2. Machine user is added as collaborator with "Write" permission
# 3. Enable branch protection on 'main'

# Configure branch protection
gh api repos/yourname/continuously-running-agents/branches/main/protection \
  -X PUT \
  -F "required_pull_request_reviews[required_approving_review_count]=1" \
  -F "required_pull_request_reviews[dismiss_stale_reviews]=true" \
  -F "enforce_admins=true" \
  -F "restrictions=null"

# Result:
# - Machine user creates branches and PRs
# - You review and approve PRs from your personal account
# - Machine user cannot push directly to 'main'
# - Standard GitHub workflow
```

**Benefits**:
- ✅ Forces PR review workflow
- ✅ Clear audit trail
- ✅ Prevents accidental direct pushes
- ✅ Standard GitHub collaboration model

**Limitations**:
- ⚠️ Requires manual PR approval
- ⚠️ Agent cannot auto-merge (without additional automation)

#### Option B: Owner Bypass with `enforce_admins=false`

**Best for**: Fully autonomous agents with owner account

```bash
# Setup:
# 1. Machine user is the repository owner OR has admin permission
# 2. Enable branch protection on 'main'
# 3. Set enforce_admins=false to allow owner bypass

# Configure branch protection with owner bypass
gh api repos/yourname/continuously-running-agents/branches/main/protection \
  -X PUT \
  -F "required_pull_request_reviews[required_approving_review_count]=1" \
  -F "enforce_admins=false" \
  -F "restrictions=null"

# Result:
# - Branch protection exists (shows in UI)
# - Owner account can push directly to 'main' (bypasses protection)
# - Other collaborators must still follow rules
```

**Benefits**:
- ✅ Fully autonomous operation
- ✅ No manual intervention needed
- ✅ Protection still enforced for non-owners

**Risks**:
- ⚠️ Agent can bypass protections (by design)
- ⚠️ No enforcement of PR review
- ⚠️ Relies entirely on agent logic being correct

**Security Mitigation** (if using Option B):
- Implement monitoring and alerts (see [06-security.md](06-security.md))
- Enable automated backups
- Use git hooks for additional validation
- Consider running agent in isolated environment
- Implement circuit breakers for suspicious activity

#### Option C: No Branch Protection (Not Recommended)

```bash
# No protection configured
# Machine user can push directly

# Only use for:
# - Personal experimental repositories
# - Repositories you don't care about
# - Temporary testing
```

### Verification Tests

Based on actual tests from the `continuously-running-agents` repository:

```bash
# Test 1: Verify owner bypass with enforce_admins=false
# Commit: c34de05 - "test: verify owner bypass with enforce_admins=false"
# Result: ✅ Direct push succeeded (owner account bypassed protection)

# Test 2: Direct push to main without PR
# Commit: 6eb5222 - "test: direct push to main without PR"
# Result: ✅ Direct push succeeded (confirms bypass works)

# Lesson: enforce_admins=false allows owner to push directly
# even with branch protection rules enabled
```

### Recommended Workflow by Use Case

| Use Case | Recommended Setup | Branch Protection | enforce_admins |
|----------|------------------|-------------------|----------------|
| **Learning/Testing** | Machine user as collaborator | Optional | N/A |
| **Production with Oversight** | Machine user as collaborator | ✅ Enabled | `true` |
| **Fully Autonomous** | Machine user as owner/admin | ✅ Enabled | `false` |
| **Open Source Project** | Machine user as collaborator | ✅ Enabled | `true` |

## Part 6: Testing and Verification

### Step 6.1: Test Full Workflow

```bash
# 1. Clone repository (if not already)
cd ~/projects
git clone git@github.com-agent:yourname/continuously-running-agents.git
cd continuously-running-agents

# 2. Create feature branch
git checkout -b test/machine-user-setup

# 3. Make changes
echo "Machine user setup complete - $(date)" >> MACHINE-USER-STATUS.md
git add MACHINE-USER-STATUS.md
git commit -m "docs: machine user setup verification"

# 4. Push branch
git push origin test/machine-user-setup

# 5. Create PR (using GitHub CLI)
gh pr create \
  --title "docs: machine user setup verification" \
  --body "Verifying machine user configuration and permissions"

# 6. Verify PR appears on GitHub
# 7. Merge PR from web interface (as personal account)
# 8. Observe commit attribution shows machine user
```

### Step 6.2: Verify Commit Attribution

```bash
# Check recent commits
git log --oneline -5

# Verify author is machine user
git log -1 --format='%an <%ae>'
# Should output: Your Name (Agent) <your.name+agent@gmail.com>

# Check on GitHub
gh pr view 1  # Replace 1 with your PR number
# Should show machine user avatar and name
```

### Step 6.3: Test Branch Protection (if configured)

```bash
# Attempt direct push to main (if using Option A - Collaborator)
git checkout main
git pull origin main
echo "Test direct push - $(date)" >> README.md
git add README.md
git commit -m "test: direct push to protected branch"
git push origin main

# Expected result with enforce_admins=true:
# ❌ Error: protected branch hook declined

# Expected result with enforce_admins=false (owner):
# ✅ Push succeeds (owner bypass)
```

### Step 6.4: Test Claude Code Integration

```bash
# Start tmux session
tmux new -s agent-session

# Start Claude Code as machine user
claude --dangerously-skip-permissions

# Test that Claude can commit and push
# (from within Claude Code session)

# Verify commits appear with machine user identity
```

## Security Best Practices

### Principle of Least Privilege

```bash
# Recommended permissions hierarchy:

Repository Owner (You)
  └─ Full control, including settings and team management

Machine User (Agent)
  └─ Write or Maintain access only
  └─ Just enough to commit, push branches, create PRs
  └─ NOT admin unless absolutely necessary

Collaborators
  └─ Write or Read as appropriate
```

### Credential Security

1. **SSH Keys**:
   ```bash
   # Restrict key file permissions
   chmod 600 ~/.ssh/id_ed25519_github_agent

   # Use SSH agent for passphrase-protected keys
   eval "$(ssh-agent -s)"
   ssh-add ~/.ssh/id_ed25519_github_agent
   ```

2. **GitHub Personal Access Tokens** (if using HTTPS):
   ```bash
   # If you must use PAT instead of SSH:
   # - Create PAT with minimal scopes (repo only)
   # - Set expiration date (max 90 days)
   # - Store in environment variable, not code
   # - Rotate regularly

   export GITHUB_TOKEN="ghp_your_token_here"

   # Never commit to git:
   echo "GITHUB_TOKEN" >> ~/.gitignore
   echo ".env" >> ~/.gitignore
   ```

3. **Environment Variables**:
   ```bash
   # Store credentials in .env file
   cat > ~/.config/agent/.env <<EOF
   GITHUB_TOKEN=ghp_...
   ANTHROPIC_API_KEY=sk-ant-...
   EOF

   chmod 600 ~/.config/agent/.env
   ```

### Server Hardening

**Machine user should follow all security practices from [06-security.md](06-security.md)**:

- [ ] SSH key-based authentication only
- [ ] Firewall configured (UFW)
- [ ] fail2ban installed
- [ ] Tailscale for private networking (recommended)
- [ ] Regular security updates
- [ ] Monitoring and alerting
- [ ] Automated backups

### Isolation Strategies

#### Option 1: Dedicated User Account (Recommended)

```bash
# Create dedicated Linux user for agent
sudo adduser claude-agent --disabled-password

# Set up SSH key for this user
sudo -u claude-agent ssh-keygen -t ed25519 -C "your.name+agent@gmail.com"

# Add GitHub machine user SSH key
sudo -u claude-agent cat > ~claude-agent/.ssh/id_ed25519_github_agent.pub <<EOF
[paste public key]
EOF

# Configure permissions
sudo chown claude-agent:claude-agent ~claude-agent/.ssh/id_ed25519_github_agent
sudo chmod 600 ~claude-agent/.ssh/id_ed25519_github_agent

# Run agent as this user
sudo -u claude-agent tmux new -s agent
```

#### Option 2: Docker Isolation

```dockerfile
# Dockerfile
FROM ubuntu:24.04

# Install dependencies
RUN apt update && apt install -y git nodejs npm
RUN npm install -g @anthropic-ai/claude-code

# Create non-root user
RUN useradd -m -s /bin/bash agent

# Copy SSH config and keys (build-time)
COPY --chown=agent:agent .ssh /home/agent/.ssh
RUN chmod 700 /home/agent/.ssh && chmod 600 /home/agent/.ssh/*

USER agent
WORKDIR /home/agent/workspace

CMD ["claude", "--dangerously-skip-permissions"]
```

```bash
# Run agent in isolated container
docker build -t claude-agent .
docker run -it \
  -e ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY \
  -v $(pwd)/workspace:/home/agent/workspace \
  claude-agent
```

### Monitoring and Auditing

```bash
# Monitor machine user activity
gh api users/yourname-agent/events/public | jq '.[].type'

# Check recent commits by machine user
gh api repos/yourname/continuously-running-agents/commits \
  --jq '.[] | select(.commit.author.email == "your.name+agent@gmail.com") | {sha: .sha, message: .commit.message, date: .commit.author.date}'

# Set up alerts for unexpected pushes
# (integrate with monitoring from 06-security.md)
```

### Incident Response

If machine user credentials are compromised:

```bash
# IMMEDIATE ACTIONS:

# 1. Revoke SSH keys (from GitHub web interface)
# Settings → SSH and GPG keys → Delete key

# 2. Rotate GitHub PAT (if using)
# Settings → Developer settings → Personal access tokens → Delete token

# 3. Remove collaborator access (from repository owner account)
gh api repos/yourname/continuously-running-agents/collaborators/yourname-agent -X DELETE

# 4. Review commit history for unauthorized changes
git log --author="your.name+agent@gmail.com" --since="24 hours ago"

# 5. Audit repository settings changes
gh api repos/yourname/continuously-running-agents/events | jq '.[] | select(.type == "RepositoryEvent")'

# 6. Reset repository to known good state if needed
git reset --hard KNOWN_GOOD_COMMIT_SHA
git push --force origin main  # Only if you own the repo and no one else is using it

# RECOVERY:

# 1. Generate new SSH key pair
ssh-keygen -t ed25519 -C "your.name+agent@gmail.com" -f ~/.ssh/id_ed25519_github_agent_new

# 2. Add new key to GitHub
# 3. Update SSH config
# 4. Re-add collaborator access
# 5. Test connection and permissions
# 6. Document incident and update security measures
```

## Troubleshooting

### SSH Connection Issues

#### Problem: `Permission denied (publickey)`

```bash
# Diagnosis
ssh -vT git@github.com-agent

# Common causes:
# 1. Wrong key file path in SSH config
# 2. Key not added to GitHub
# 3. Permissions too open

# Solution:
chmod 600 ~/.ssh/id_ed25519_github_agent
ssh-add ~/.ssh/id_ed25519_github_agent
cat ~/.ssh/id_ed25519_github_agent.pub  # Verify this is on GitHub
```

#### Problem: `ssh: Could not resolve hostname github.com-agent`

```bash
# Diagnosis
cat ~/.ssh/config | grep -A 5 "github.com-agent"

# Cause: SSH config not set up correctly

# Solution:
nano ~/.ssh/config
# Ensure Host is exactly "github.com-agent"
# Ensure HostName is "github.com" (not github.com-agent)
```

#### Problem: Using wrong SSH key

```bash
# Diagnosis
ssh -vT git@github.com-agent 2>&1 | grep "identity file"

# Should show:
# debug1: identity file /home/user/.ssh/id_ed25519_github_agent

# If showing different key:
# Add IdentitiesOnly yes to SSH config
```

### Git Authentication Issues

#### Problem: Git asks for username/password

```bash
# Cause: Using HTTPS URL instead of SSH

# Check remote URL
git remote -v

# If shows https://github.com/...:
git remote set-url origin git@github.com-agent:yourname/repo.git

# Verify
git remote -v
```

#### Problem: Commits show wrong author

```bash
# Check git config
git config user.name
git config user.email

# If wrong, set correct values:
git config user.name "Your Name (Agent)"
git config user.email "your.name+agent@gmail.com"

# For already committed changes:
git commit --amend --author="Your Name (Agent) <your.name+agent@gmail.com>"
```

### GitHub Permissions Issues

#### Problem: `remote: Permission to user/repo.git denied`

```bash
# Verify collaborator was added
gh api repos/yourname/continuously-running-agents/collaborators

# Verify invitation was accepted
# Log in as machine user on GitHub web interface
# Check for pending invitations

# Re-send invitation if needed
gh api repos/yourname/continuously-running-agents/collaborators/yourname-agent \
  -X PUT -f permission=push
```

#### Problem: Cannot create PRs

```bash
# Ensure machine user has at least Write permission
gh api repos/yourname/continuously-running-agents/collaborators/yourname-agent \
  --jq '.permissions'

# Should show:
# {
#   "admin": false,
#   "maintain": false,
#   "push": true,    ← Should be true
#   "triage": true,
#   "pull": true
# }
```

### Branch Protection Issues

#### Problem: Cannot push to main despite being owner

```bash
# Check branch protection settings
gh api repos/yourname/continuously-running-agents/branches/main/protection

# If shows protection but you're owner:
# - Check if enforce_admins is true or false
# - If true: Protection applies to everyone including owner
# - If false: Owners can bypass (this is expected)

# Verify your account is actually the owner:
gh api repos/yourname/continuously-running-agents --jq '.owner.login'
# Should match your machine user username if machine user owns the repo
```

#### Problem: Unsure if machine user can bypass protection

```bash
# Check permissions
gh api repos/yourname/continuously-running-agents/collaborators/yourname-agent/permission \
  --jq '.permission'

# Permissions that can bypass (with enforce_admins=false):
# - admin
# - maintain (sometimes, depending on settings)

# Permission that cannot bypass:
# - write (push access, but must follow protection rules)
```

### Claude Code Integration Issues

#### Problem: Claude Code commits not showing machine user

```bash
# Check git config in Claude Code's working directory
cd ~/projects/continuously-running-agents
git config user.name
git config user.email

# If wrong, reconfigure:
git config user.name "Your Name (Agent)"
git config user.email "your.name+agent@gmail.com"
```

#### Problem: Claude Code cannot push changes

```bash
# Test git push outside Claude Code first
git push origin main

# If that works but Claude can't push:
# - Check Claude Code's working directory is correct
# - Ensure git remote is configured with machine user SSH
# - Check SSH agent has the key loaded

# Debug by checking Claude Code's git configuration:
# (from within Claude Code environment)
git config --list
git remote -v
ssh -T git@github.com-agent
```

### Email and Notification Issues

#### Problem: Not receiving machine user notifications

```bash
# Cause: Using + aliasing with provider that doesn't support it

# Solution 1: Use actual separate email
# Create new email account specifically for machine user

# Solution 2: Check spam folder
# Machine user emails might be filtered

# Solution 3: Configure notification settings
# Log in as machine user → Settings → Notifications
# Ensure email notifications are enabled
```

### Multi-User Server Issues

#### Problem: SSH keys conflict on shared server

```bash
# Use different SSH config hosts for different users

# User 1 (personal):
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_personal

# User 2 (machine):
Host github.com-agent
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_agent

# Each user uses their respective host in git remotes
```

### Recovery Procedures

#### Lost Access to Machine User Account

```bash
# If you lose 2FA codes or password:

# Option 1: Use recovery codes (saved during 2FA setup)
# Option 2: GitHub account recovery (email verification)
# Option 3: Create new machine user and migrate:

# Steps to migrate to new machine user:
# 1. Create new machine user account (yourname-agent2)
# 2. Generate new SSH keys
# 3. Add new machine user as collaborator
# 4. Remove old machine user
# 5. Update server git config
# 6. Update SSH config

# All commit history with old machine user remains intact
```

## Advanced Topics

### Multiple Machine Users

For complex setups with multiple agents:

```bash
# Example: Separate agents for different tasks
# - yourname-ci (continuous integration)
# - yourname-deploy (deployment automation)
# - yourname-docs (documentation generation)

# SSH config:
Host github.com-ci
    HostName github.com
    IdentityFile ~/.ssh/id_ed25519_ci

Host github.com-deploy
    HostName github.com
    IdentityFile ~/.ssh/id_ed25519_deploy

Host github.com-docs
    HostName github.com
    IdentityFile ~/.ssh/id_ed25519_docs

# Each agent uses its respective SSH host
```

### GitHub App vs Machine User

| Feature | Machine User | GitHub App |
|---------|--------------|------------|
| **Setup Complexity** | Simple | Complex |
| **Rate Limits** | Standard (5000/hour) | Higher (5000/hour per installation) |
| **Permissions** | Repository-level | Fine-grained |
| **Cost** | Free | Free for public repos |
| **Audit Trail** | Clear in commits | Appears as "bot" |
| **Best For** | Single user, simple automation | Organizations, complex workflows |

**When to use GitHub App**:
- Organization with multiple repositories
- Need fine-grained permissions
- Multiple developers need agent access
- Webhook-based automation

**When to use Machine User** (this guide):
- Personal or small team projects
- Simple commit/push automation
- Want clear commit attribution
- Easier setup and maintenance

### Converting Personal Repository to Organization

If you later want to move your repository to an organization:

```bash
# Process:
# 1. GitHub: Settings → Danger Zone → Transfer repository
# 2. Transfer to organization
# 3. Add machine user to organization team
# 4. Update repository access for machine user

# No changes needed on server side (SSH keys remain valid)
# Git remote URLs update automatically
```

## Checklist

### Initial Setup

- [ ] Created email address for machine user (e.g., `name+agent@gmail.com`)
- [ ] Created GitHub machine user account
- [ ] Configured machine user profile (name, bio, avatar)
- [ ] Enabled 2FA on machine user account
- [ ] Saved recovery codes in password manager
- [ ] Generated SSH key pair on server
- [ ] Added SSH public key to GitHub machine user
- [ ] Configured SSH config with `github.com-agent` host
- [ ] Tested SSH connection successfully

### Repository Access

- [ ] Invited machine user to repository as collaborator
- [ ] Machine user accepted invitation
- [ ] Verified repository access with `gh repo view`
- [ ] Configured git identity (name and email)
- [ ] Set git remote URL to use machine user SSH
- [ ] Tested push access to repository

### Branch Protection

- [ ] Decided on branch protection strategy (Option A, B, or C)
- [ ] Configured branch protection rules if applicable
- [ ] Set `enforce_admins` appropriately
- [ ] Tested direct push behavior
- [ ] Documented chosen approach for team

### Security

- [ ] Server follows hardening practices from 06-security.md
- [ ] SSH key permissions set correctly (600)
- [ ] Credentials stored securely (not in code)
- [ ] Monitoring and alerting configured
- [ ] Automated backups enabled
- [ ] Incident response plan documented
- [ ] Team knows how to revoke access in emergency

### Testing

- [ ] Successfully cloned repository using machine user
- [ ] Created and pushed feature branch
- [ ] Created pull request as machine user
- [ ] Verified commit attribution shows machine user
- [ ] Tested branch protection if enabled
- [ ] Integrated with Claude Code successfully

## Next Steps

After completing this setup:

1. **Configure Claude Code**: See [04-claude-configuration.md](04-claude-configuration.md)
2. **Set up monitoring**: See [06-security.md](06-security.md) → Monitoring and Alerting
3. **Automate with tmux**: See [02-tmux-setup.md](02-tmux-setup.md) for persistent sessions
4. **Deploy to cloud**: See [01-infrastructure.md](01-infrastructure.md) for Hetzner/DigitalOcean setup

## Resources

- [GitHub Machine Users Documentation](https://docs.github.com/en/developers/overview/managing-deploy-keys#machine-users)
- [SSH Key Generation Guide](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)
- [Branch Protection Settings](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
- [GitHub Collaborators](https://docs.github.com/en/account-and-profile/setting-up-and-managing-your-personal-account-on-github/managing-access-to-your-personal-repositories/inviting-collaborators-to-a-personal-repository)
- Project Security Guide: [06-security.md](06-security.md)

## Contributing

Found an issue or have an improvement? See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Examples in Production

- **renchris/continuously-running-agents**: Uses `@renchris-agent` with email `ren.chris+agent@outlook.com`
  - Owner bypass with `enforce_admins=false` for autonomous operation
  - See commits [c34de05](https://github.com/renchris/continuously-running-agents/commit/c34de05) and [6eb5222](https://github.com/renchris/continuously-running-agents/commit/6eb5222) for real-world tests

---

**Last Updated**: October 20, 2025

**Maintained by**: The continuously-running-agents community

**License**: MIT
