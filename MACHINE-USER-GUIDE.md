# Machine User Setup Guide

Complete guide for setting up a machine user account for Claude Code agents with proper security isolation.

**Time to complete**: ~45 minutes
**Example**: `@renchris-agent` on this repo
**Last Updated**: October 2025

---

## What is a Machine User?

A **machine user** is a dedicated GitHub account for AI agents that provides:
- **Security isolation**: Separate credentials from your personal account
- **Least privilege**: Access only to specific repositories
- **Audit trail**: Clear attribution of agent actions
- **Branch protection enforcement**: Agent cannot push to main, owner can

---

## Quick Reference

### Grant Access to Repo
```bash
# As owner (from your local machine):
gh api -X PUT "/repos/OWNER/REPO/collaborators/yourname-agent" \
  --field permission=push
```

### Accept Invitation
```bash
# As machine user (on server):
gh api user/repository_invitations  # Get invitation ID
gh api -X PATCH /user/repository_invitations/INVITATION_ID
```

### Revoke Access
```bash
# As owner:
gh api -X DELETE "/repos/OWNER/REPO/collaborators/yourname-agent"
```

### Check Status
```bash
# On server as machine user:
gh auth status
ssh -T git@github.com
gh api user/repos --paginate | jq -r '.[].full_name'
```

---

## Complete Setup Guide

### 1. Create Machine User Account

**On GitHub**:
1. Sign up at github.com/signup
2. Use email aliasing: `your.name+agent@gmail.com`
3. Choose username: `yourname-agent`
4. Enable 2FA and save recovery codes
5. Set profile:
   - Name: "Your Name (Agent)"
   - Bio: "🤖 Automated agent for [purpose]"

**Best Practices**:
- Use email alias to share inbox with your main account
- Make username clearly indicate it's an agent
- Enable 2FA for security

---

### 2. SSH Key Setup (on Server)

```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "your.name+agent@gmail.com" \
  -f ~/.ssh/id_ed25519_github_agent -N ""

# Display public key
cat ~/.ssh/id_ed25519_github_agent.pub
# Copy the entire output (ssh-ed25519 ... comment)

# Configure SSH
cat >> ~/.ssh/config <<'EOF'
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_github_agent
  IdentitiesOnly yes
EOF

# Set permissions
chmod 600 ~/.ssh/config ~/.ssh/id_ed25519_github_agent

# Test connection (after adding key to GitHub)
ssh -T git@github.com
# Expected: "Hi yourname-agent! You've successfully authenticated"
```

**In browser** (as machine user):
1. Go to GitHub Settings → SSH and GPG keys
2. Click "New SSH key"
3. Title: "Server Name" (e.g., "Hetzner Claude Agent")
4. Paste public key
5. Click "Add SSH key"

---

### 3. Git Configuration (on Server)

```bash
# Set identity
git config --global user.name "Your Name (Agent)"
git config --global user.email "your.name+agent@gmail.com"

# Verify
git config --global --list | grep -E "(user.name|user.email)"
```

---

### 4. GitHub CLI Authentication (on Server)

```bash
# Authenticate
gh auth login --web --git-protocol ssh

# Follow prompts:
# - GitHub.com
# - SSH
# - Upload SSH key: Yes
# - Login via web browser
# - Paste one-time code from browser

# Verify
gh auth status
# Expected: "Logged in to github.com account yourname-agent"
```

---

### 5. Repository Access Management

#### Grant Access (as repository owner)

From your local machine:

```bash
# Invite machine user as collaborator with push permission
gh api -X PUT \
  "/repos/OWNER/REPO/collaborators/yourname-agent" \
  --field permission=push

# Invitation sent - machine user must accept
```

#### Accept Invitation (as machine user)

On the server:

```bash
# List pending invitations
gh api user/repository_invitations

# Note the invitation ID, then accept
gh api -X PATCH /user/repository_invitations/INVITATION_ID

# Verify access
gh api /repos/OWNER/REPO/collaborators/yourname-agent
```

#### Track Access (Important!)

Maintain an access log to track which repos the agent can access:

```bash
# Create access log
cat > ~/agent-repo-access.txt <<'EOF'
# Machine User Repository Access Log
# Format: YYYY-MM-DD | repository-name | reason for access
# ===================================================
EOF

# When granting access
echo "$(date +%Y-%m-%d) | REPO_NAME | REASON" >> ~/agent-repo-access.txt

# View current access
cat ~/agent-repo-access.txt

# Audit access
gh api user/repos --paginate | jq -r '.[].full_name' | grep OWNER/
```

#### Revoke Access (as repository owner)

```bash
# Remove collaborator
gh api -X DELETE "/repos/OWNER/REPO/collaborators/yourname-agent"

# Update access log on server
sed -i '/REPO_NAME/d' ~/agent-repo-access.txt
```

**Principle of Least Privilege**: Only grant access to specific repos as needed. Revoke when work is complete.

---

### 6. Branch Protection Setup

This is the **critical security boundary** that prevents the machine user from pushing directly to main.

#### Key Discovery: `enforce_admins` Setting

The `enforce_admins: false` setting is critical for personal accounts:
- When `false`: Repository **owner** (admin) can bypass branch protection
- Collaborators (non-admin) **cannot bypass** regardless of this setting
- No organization account needed

**Access Control Result**:

| User | Role | Can Push to Main? | Why |
|------|------|-------------------|-----|
| @owner | Repository owner | ✅ Yes | Admin bypass enabled |
| @agent | Collaborator | ❌ No | Not admin, must use PRs |

#### Apply Branch Protection

```bash
# As repository owner (from local machine):
gh api -X PUT "/repos/OWNER/REPO/branches/main/protection" \
  --input - <<'EOF'
{
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true
  },
  "enforce_admins": false,
  "required_status_checks": {
    "strict": false,
    "contexts": []
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF
```

#### Verify Protection

```bash
# Check protection status
gh api /repos/OWNER/REPO/branches/main/protection | \
  jq '{enforce_admins: .enforce_admins.enabled, required_reviews: .required_pull_request_reviews.required_approving_review_count}'
```

---

### 7. Testing & Validation

Run these tests to verify the security model works correctly:

```bash
# On server as machine user

# Test 1: Clone repository
git clone git@github.com:OWNER/REPO.git test-security
cd test-security

# Test 2: Create feature branch (should succeed)
git checkout -b test/machine-user-validation
echo "# Test" >> README.md
git add README.md
git commit -m "test: machine user validation"
git push origin test/machine-user-validation
# ✅ Expected: SUCCESS

# Test 3: Create PR (should succeed)
gh pr create --title "test: machine user validation" \
  --body "Testing machine user setup" \
  --repo OWNER/REPO
# ✅ Expected: PR created successfully

# Test 4: Push to main (should fail - SECURITY BOUNDARY)
git checkout main
git pull
echo "# Test" >> README.md
git add README.md
git commit -m "test: direct push to main"
git push origin main
# ✅ Expected: BLOCKED "Changes must be made through a pull request"

# Test 5: Force push (should fail)
git push --force origin main
# ✅ Expected: BLOCKED

# Test 6: Access other repos (should fail - ISOLATION)
cd ~
git clone git@github.com:OWNER/OTHER_REPO.git
# ✅ Expected: DENIED "Repository not found"

# Cleanup
cd test-security
gh pr close --delete-branch
cd ~ && rm -rf test-security
```

**All tests should pass** for proper security isolation.

---

## Security Model

### Access Levels

**Repository Owner** (`@owner`):
- ✅ Push directly to main via `git push origin main`
- ✅ Full repository settings access
- ✅ Can delete or modify repository
- ✅ Can bypass branch protection (with `enforce_admins: false`)

**Machine User** (`@agent` as collaborator):
- ✅ Push to feature/side branches
- ✅ Create pull requests to main
- ❌ **BLOCKED** from pushing to main branch
- ❌ **BLOCKED** from repository settings/deletion
- ❌ **BLOCKED** from accessing repos without invitation

### Daily Workflows

**Owner Workflow**:
```bash
# Direct push to main (no PR needed)
git checkout main
git add .
git commit -m "feat: new feature"
git push origin main  # ✅ Works
```

**Agent Workflow**:
```bash
# Must use feature branches and PRs
git checkout -b feature/agent-work
git add .
git commit -m "feat: agent work"
git push origin feature/agent-work  # ✅ Works
gh pr create --fill                 # Create PR

# ❌ git push origin main would be BLOCKED
```

### Security Benefits

1. **Least Privilege**: Agent has minimum required access
2. **Branch Protection**: Main branch protected from agent
3. **Repository Isolation**: Agent cannot access other repositories
4. **No Admin Rights**: Agent cannot modify repository settings
5. **Owner Flexibility**: You maintain full direct push capability
6. **Audit Trail**: Clear git history showing agent vs owner commits

---

## Troubleshooting

### SSH Connection Fails

```bash
# Check SSH config
cat ~/.ssh/config

# Test with verbose output
ssh -vT git@github.com

# Verify key exists and has correct permissions
ls -la ~/.ssh/id_ed25519_github_agent*
chmod 600 ~/.ssh/id_ed25519_github_agent

# Verify key is added to GitHub
# Visit: https://github.com/settings/keys (as machine user)
```

### GitHub CLI Not Authenticated

```bash
# Check status
gh auth status

# Re-authenticate if needed
gh auth logout --hostname github.com
gh auth login --web --git-protocol ssh
```

### Cannot Push to Branch

```bash
# Verify you're a collaborator
gh api /repos/OWNER/REPO/collaborators/yourname-agent

# Check for pending invitation
gh api user/repository_invitations

# Accept if pending
gh api -X PATCH /user/repository_invitations/INVITATION_ID
```

### Can Push to Main (Security Issue!)

```bash
# This means branch protection is NOT working
# Check protection status:
gh api /repos/OWNER/REPO/branches/main/protection

# Re-apply protection (see step 6 above)
```

### Wrong Git Author

```bash
# Check current config
git config --global --list | grep -E "(user.name|user.email)"

# Fix if wrong
git config --global user.name "Your Name (Agent)"
git config --global user.email "your.name+agent@gmail.com"

# Update existing commits (if needed)
git commit --amend --author="Your Name (Agent) <your.name+agent@gmail.com>"
```

---

## Best Practices

### Access Management
- ✅ **DO**: Invite agent to specific repos as needed
- ✅ **DO**: Grant "push" permission (collaborator level)
- ✅ **DO**: Revoke access when project is complete
- ✅ **DO**: Maintain access log (`~/agent-repo-access.txt`)
- ❌ **DON'T**: Bulk invite to all repos
- ❌ **DON'T**: Grant admin permissions
- ❌ **DON'T**: Leave access indefinitely

### Branch Protection
- ✅ **DO**: Apply branch protection to all repos with agent access
- ✅ **DO**: Set `enforce_admins: false` (allows owner bypass on personal repos)
- ✅ **DO**: Require PR reviews (at least 1 approval)
- ✅ **DO**: Disable force pushes and deletions
- ❌ **DON'T**: Remove branch protection while agent has access

### Security
- ✅ **DO**: Enable 2FA on machine user account
- ✅ **DO**: Use SSH keys (not HTTPS with password)
- ✅ **DO**: Set restrictive SSH key permissions (chmod 600)
- ✅ **DO**: Regularly audit repository access
- ❌ **DON'T**: Share machine user credentials
- ❌ **DON'T**: Use machine user for manual operations

---

## Related Documentation

- `06-security.md` - Server hardening and security best practices
- `IMPLEMENTATION.md` - Complete deployment guide with machine user setup
- `TROUBLESHOOTING.md` - Common issues and solutions
- [GitHub Machine Users Docs](https://docs.github.com/en/developers/overview/managing-deploy-keys#machine-users)
- [Branch Protection Docs](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches)

---

**Last Updated**: October 2025
**License**: MIT
