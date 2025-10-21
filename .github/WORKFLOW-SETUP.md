# GitHub Actions Workflow Setup

**Repository**: `renchris/continuously-running-agents`
**Last Updated**: 2025-10-21

---

## Required Repository Settings

### For Release Workflow (changesets)

**Setting**: Allow GitHub Actions to create and approve pull requests

**Location**:
1. Repository Settings → https://github.com/renchris/continuously-running-agents/settings/actions
2. Scroll to "Workflow permissions"
3. Check: ☑️ "Allow GitHub Actions to create and approve pull requests"

**Why**: The changesets workflow (`release.yml`) needs to create PRs for version bumps

**Status**: ✅ Enabled (2025-10-21)

---

## Workflow Overview

### Release Workflow (`release.yml`)

**Trigger**: Every push to `main` branch

**What It Does**:
1. Checks out repository
2. Sets up Bun runtime
3. Installs dependencies
4. Runs `changeset version` (updates CHANGELOG.md, package.json, removes consumed changesets)
5. Creates commit: "chore: version packages"
6. **Creates PR** with version bumps (requires setting above)
7. When PR is merged, creates GitHub release

**Required Permissions**:
```yaml
permissions:
  contents: write       # Create commits and releases
  pull-requests: write  # Create PRs
  issues: write         # Reference issues in changelog
  id-token: write       # OpenID Connect
```

---

## Troubleshooting

### Error: "GitHub Actions is not permitted to create or approve pull requests"

**Full Error**:
```
##[error]HttpError: GitHub Actions is not permitted to create or approve pull requests.
```

**Cause**: Repository setting "Allow GitHub Actions to create and approve pull requests" is disabled

**Fix**:
1. Go to: https://github.com/renchris/continuously-running-agents/settings/actions
2. Scroll to "Workflow permissions"
3. Enable: ☑️ "Allow GitHub Actions to create and approve pull requests"
4. Click "Save"

**Verification**:
```bash
# Trigger workflow with empty commit
git commit --allow-empty -m "chore: test release workflow"
git push origin main

# Watch workflow run
gh run watch --repo renchris/continuously-running-agents
```

---

### Important GitHub Limitation

**PRs created by `GITHUB_TOKEN` do NOT trigger other workflows**

**What This Means**:
- If you have `on: pull_request` workflows (tests, linting, checks)
- Those workflows **will not run** on PRs created by the release workflow
- This is a GitHub security feature to prevent recursive workflow runs

**Workaround** (if needed):
- Use a Personal Access Token (PAT) instead of `GITHUB_TOKEN`
- Create fine-grained PAT at: https://github.com/settings/tokens
- Scope: `Contents: Read & Write`, `Pull Requests: Read & Write`
- Add as repository secret: `PAT_TOKEN`
- Update workflow: `GITHUB_TOKEN: ${{ secrets.PAT_TOKEN }}`

**Current Status**: Not needed (no PR checks in this repo)

---

## Changeset Workflow

### How to Create a Changeset

```bash
# In knowledge-base directory
bunx changeset

# Follow prompts:
# 1. Select change type: patch/minor/major
# 2. Provide summary of changes
# 3. Commit the .changeset/*.md file
```

### What Happens After Merge

**On push to main**:
1. ✅ Workflow runs
2. ✅ Detects changesets
3. ✅ Creates "chore: version packages" PR
4. ⏸️ **WAIT** - PR needs manual review/merge

**After PR merge**:
1. ✅ Workflow runs again
2. ✅ Detects version bump was merged
3. ✅ Creates GitHub release with changelog

---

## Repository Settings Checklist

For new repositories or forks:

- [ ] **Actions enabled**: Settings → Actions → General → "Allow all actions and reusable workflows"
- [ ] **Workflow permissions**: Settings → Actions → General → "Read and write permissions"
- [ ] **PR creation allowed**: Settings → Actions → General → ☑️ "Allow GitHub Actions to create and approve pull requests"
- [ ] **Branch protection** (optional): Settings → Branches → Add rule for `main`
  - Require PR reviews
  - Require status checks
  - `enforce_admins: false` (allows owner to bypass)

---

## Historical Context

### Failed Workflow Runs (2025-10-20 to 2025-10-21)

**Runs**: #18691465491, #18690609729, #18690007665, #18690001461, #18670908350, #18664865338

**Cause**: Repository setting was disabled (default for personal repos)

**Resolution**: Enabled setting on 2025-10-21

**Lesson**: New personal repositories have strict defaults; explicitly enable PR creation for changesets workflow

---

## References

**GitHub Docs**:
- [Managing GitHub Actions settings](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository)
- [Automatic token authentication](https://docs.github.com/en/actions/security-for-github-actions/security-guides/automatic-token-authentication)
- [Workflow permissions](https://docs.github.com/en/actions/using-jobs/assigning-permissions-to-jobs)

**Related Issues**:
- [GitHub Community Discussion #27689](https://github.com/orgs/community/discussions/27689) - PR creation restrictions
- [peter-evans/create-pull-request #2767](https://github.com/peter-evans/create-pull-request/issues/2767) - Breaking change with PR permissions

**Changesets**:
- [Changesets GitHub Action](https://github.com/changesets/action)
- [Changesets Documentation](https://github.com/changesets/changesets)

---

**Setup Complete**: 2025-10-21
**Verified By**: @renchris
**Next Review**: When adding CI/CD checks or forking repository
