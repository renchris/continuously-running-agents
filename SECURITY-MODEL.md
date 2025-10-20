# GitHub Security Model for Claude Agents

**Last Updated**: 2025-10-20

## Summary

Secure machine user setup for Claude Code agents on personal GitHub account without requiring organization.

## Configuration

### Branch Protection Settings
```json
{
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1
  },
  "allow_force_pushes": false,
  "allow_deletions": false
}
```

### Access Control

**@renchris (repository owner)**:
- ✅ Push directly to main via `git push origin main`
- ✅ Full repository settings access
- ✅ Can delete/modify repository
- **Why**: Admin permissions + `enforce_admins: false` = bypass enabled

**@renchris-agent (machine user collaborator)**:
- ✅ Push to feature/side branches
- ✅ Create pull requests to main
- ❌ **BLOCKED** from pushing to main branch
- ❌ **BLOCKED** from repository settings/deletion
- ❌ **BLOCKED** from accessing other 81 repos
- **Why**: Collaborator permissions (not admin) = no bypass allowed

## Key Insight

**The `enforce_admins: false` setting is critical:**
- When `false`: Repository owner (admin) can bypass branch protection
- Collaborators (non-admin) cannot bypass regardless of this setting
- No organization account needed for this security model

## Verification Commands

```bash
# Check branch protection status
gh api /repos/renchris/continuously-running-agents/branches/main/protection | \
  jq '{enforce_admins: .enforce_admins.enabled, required_pr_reviews: .required_pull_request_reviews.required_approving_review_count}'

# Test owner push (should succeed with bypass message)
git push origin main

# Test agent push (should fail with protection error)
ssh -i ~/.ssh/hetzner_claude_agent claude-agent@5.78.152.238 \
  "cd /path/to/repo && git push origin main"
```

## Daily Workflow

### Owner (@renchris)
```bash
# Direct push to main (no PR needed)
git checkout main
git add .
git commit -m "feat: new feature"
git push origin main  # ✅ Works
```

### Agent (@renchris-agent)
```bash
# Must use feature branches and PRs
git checkout -b feature/agent-work
git add .
git commit -m "feat: agent work"
git push origin feature/agent-work  # ✅ Works
gh pr create --fill                 # Create PR
# ❌ git push origin main would be blocked
```

## Security Benefits

1. **Least Privilege**: Agent has minimum required access
2. **Branch Protection**: Main branch protected from agent
3. **Isolation**: Agent cannot access other repositories
4. **No Admin Rights**: Agent cannot modify repository settings
5. **Owner Flexibility**: You maintain full direct push capability

## Related Documentation

- `MACHINE-USER-STATUS.md` - Current setup status
- `MACHINE-USER-SETUP-PLAN.md` - Complete setup history
- `IMPLEMENTATION.md` - Full deployment guide
