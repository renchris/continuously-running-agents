# Machine User Setup Guide - Quick Reference

**Complete details**: [MACHINE-USER-SETUP-PLAN.md](MACHINE-USER-SETUP-PLAN.md) | **Security**: [06-security.md](06-security.md) | **Troubleshooting**: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

## What is This?

Machine user = dedicated GitHub account for AI agent. Provides security isolation and audit trail.

**Time**: ~45 minutes | **Example**: `@renchris-agent` on this repo

---

## 1. Create Machine User Account

```bash
# Use email aliasing: your.name+agent@gmail.com
# Sign up at github.com/signup with username: yourname-agent
# Enable 2FA and save recovery codes
# Set profile: Name "Your Name (Agent)", Bio "🤖 Automated agent"
```

---

## 2. SSH Key Setup (on Server)

```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "your.name+agent@gmail.com" -f ~/.ssh/id_ed25519_github_agent

# Copy public key
cat ~/.ssh/id_ed25519_github_agent.pub

# Configure SSH
cat >> ~/.ssh/config <<'EOF'
Host github.com-agent
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_github_agent
    IdentitiesOnly yes
EOF

chmod 600 ~/.ssh/config ~/.ssh/id_ed25519_github_agent

# Test connection
ssh -T git@github.com-agent
```

**In browser** (as machine user): Settings → SSH keys → Add new → Paste public key

---

## 3. Repository Access

```bash
# As owner (local machine):
gh api -X PUT "/repos/OWNER/REPO/collaborators/yourname-agent" --field permission=push

# As machine user (server):
gh api user/repository_invitations  # Get ID
gh api -X PATCH /user/repository_invitations/ID
```

---

## 4. Git Configuration (on Server)

```bash
# Set identity
git config --global user.name "Your Name (Agent)"
git config --global user.email "your.name+agent@gmail.com"

# Set remote URL
cd ~/projects/your-repo
git remote set-url origin git@github.com-agent:OWNER/REPO.git

# Authenticate GitHub CLI
gh auth login --web --git-protocol ssh
```

---

## 5. Branch Protection

### Key Discovery: `enforce_admins` Setting

`enforce_admins: false` allows **owners** to bypass branch protection, while **collaborators** are still blocked.

| Role | `enforce_admins: true` | `enforce_admins: false` |
|------|------------------------|-------------------------|
| Owner | ❌ Blocked | ✅ Can bypass |
| Collaborator | ❌ Blocked | ❌ Blocked |

### Option A: Collaborator (Recommended for Security)

```bash
# Machine user = collaborator, must use PRs
gh api -X PUT "/repos/OWNER/REPO/branches/main/protection" --input - <<'EOF'
{
  "required_pull_request_reviews": {"required_approving_review_count": 1},
  "enforce_admins": true,
  "restrictions": null,
  "allow_force_pushes": false
}
EOF
```
✅ Machine user CANNOT push to main | ✅ Must create PRs | ✅ Secure

### Option B: Owner Bypass (Autonomous)

```bash
# Machine user = owner, enforce_admins: false
# Owner can push directly, collaborators blocked
# See commits c34de05, 6eb5222 for production examples
```
✅ Fully autonomous | ⚠️ Less oversight | See [MACHINE-USER-SETUP-PLAN.md](MACHINE-USER-SETUP-PLAN.md)

---

## 6. Testing

```bash
# Clone and test
git clone git@github.com-agent:OWNER/REPO.git && cd REPO

# Create feature branch (should succeed)
git checkout -b test/setup
echo "Test" >> README.md
git add . && git commit -m "test: machine user"
git push origin test/setup

# Create PR (should succeed)
gh pr create --title "test" --body "Testing machine user"

# Test direct push to main (should fail with protection)
git checkout main && git pull
echo "Test" >> README.md
git add . && git commit -m "test: direct push"
git push origin main  # Expected: ❌ Blocked

# Verify author
git log -1 --format='%an <%ae>'  # Should show machine user
```

---

## Access Management

```bash
# Grant access (as owner):
gh api -X PUT "/repos/OWNER/REPO/collaborators/yourname-agent" --field permission=push

# Revoke access (as owner):
gh api -X DELETE "/repos/OWNER/REPO/collaborators/yourname-agent"

# Track access (server):
echo "$(date +%Y-%m-%d) | REPO | REASON" >> ~/agent-repo-access.txt

# Audit access:
gh api user/repos --paginate | jq -r '.[].full_name'
```

**Principle of Least Privilege**: Only grant access to specific repos as needed.

---

## Quick Troubleshooting

```bash
# SSH fails
ssh -vT git@github.com-agent  # Debug
chmod 600 ~/.ssh/id_ed25519_github_agent  # Fix perms

# Git asks for password
git remote set-url origin git@github.com-agent:OWNER/REPO.git

# Wrong author
git config user.name "Your Name (Agent)"
git config user.email "your.name+agent@gmail.com"
```

**Full troubleshooting**: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

## Security Checklist

- [ ] SSH key permissions: `chmod 600 ~/.ssh/id_ed25519_github_agent`
- [ ] Write permission only (NOT admin)
- [ ] Branch protection enabled
- [ ] 2FA enabled, recovery codes saved
- [ ] Server hardened (firewall, fail2ban)
- [ ] Access tracked per repo

**Full security guide**: [06-security.md](06-security.md)

---

## Next Steps

1. Configure Claude Code: [04-claude-configuration.md](04-claude-configuration.md)
2. Set up monitoring: [06-security.md](06-security.md)
3. Automate with tmux: [02-tmux-setup.md](02-tmux-setup.md)

---

## Resources

- [MACHINE-USER-SETUP-PLAN.md](MACHINE-USER-SETUP-PLAN.md) - Detailed setup plan with decision tree
- [06-security.md](06-security.md) - Security best practices
- [GitHub Machine Users Docs](https://docs.github.com/en/developers/overview/managing-deploy-keys#machine-users)
- [Branch Protection Docs](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches)

**Last Updated**: October 2025 | **License**: MIT
