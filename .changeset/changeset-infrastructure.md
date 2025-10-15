---
"continuously-running-agents": patch
---

Changeset workflow with GitHub Actions integration

Implements automated versioning and changelog generation following changesets best practices:

- **Automated releases**: GitHub Actions creates "Version Packages" PR automatically
- **PR validation**: All PRs must include changeset (enforced by CI)
- **Rich changelogs**: Uses @changesets/changelog-github for links to PRs/issues
- **Zero-touch versioning**: No manual version bumps needed
- **Enhanced documentation**: Comprehensive changeset workflow in CONTRIBUTING.md
