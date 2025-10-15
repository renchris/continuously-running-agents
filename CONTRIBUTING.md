# Contributing to Continuously Running Agents Knowledge Base

Thank you for your interest in contributing! This document outlines our conventions and workflow.

## Commit Message Convention

We follow semantic commit conventions to maintain a clear and useful git history. Our commits are used to automatically generate changelogs via [changesets](https://github.com/changesets/changesets).

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Rules

1. **Lowercase** - Use lowercase for everything except proper nouns, titles, and acronyms
2. **Present tense** - Use present tense verbs ("change" not "changed" or "changes")
3. **No redundant verbs** - Don't repeat what the type already implies
   - ❌ `feat: add user authentication`
   - ✅ `feat: user authentication`
   - ❌ `fix: adjust login error`
   - ✅ `fix: login error handling`
   - ❌ `docs: update README`
   - ✅ `docs: README improvements`
4. **Imperative mood** - Write as if giving a command
5. **No period** at the end of the subject line
6. **Max 50 characters** for subject line
7. **Wrap body at 72 characters**

### Types

Use these standard types:

| Type | Description | Example |
|------|-------------|---------|
| `feat` | New feature | `feat: multi-agent coordination protocol` |
| `fix` | Bug fix | `fix: broken cross-references in README` |
| `docs` | Documentation only | `docs: contribution guidelines` |
| `style` | Formatting, missing semi-colons, etc. | `style: markdownlint compliance` |
| `refactor` | Code restructuring | `refactor: agent spawner logic` |
| `perf` | Performance improvement | `perf: cache optimization for large repos` |
| `test` | Adding/updating tests | `test: agent coordination scenarios` |
| `build` | Build system or dependencies | `build: upgrade to Node 20` |
| `ci` | CI configuration changes | `ci: GitHub Actions workflow` |
| `chore` | Maintenance tasks | `chore: .gitignore for logs` |
| `revert` | Revert previous commit | `revert: "feat: experimental feature"` |

### Scope (Optional)

The scope provides additional context about which part of the codebase is affected:

```
feat(examples): Docker Compose setup
fix(tmux): session persistence issue
docs(getting-started): beginner path tutorial
```

Common scopes for this project:
- `examples` - 07-examples.md
- `tmux` - 02-tmux-setup.md
- `infrastructure` - 01-infrastructure.md
- `security` - 06-security.md
- `cost` - 05-cost-optimization.md
- `getting-started` - 00-getting-started.md
- `config` - 04-claude-configuration.md
- `remote` - 03-remote-access.md

### Examples

**Good commits:**

```bash
# Feature
feat: Pieter Levels /workers/ pattern

# Fix
fix: markdownlint warnings in 07-examples.md

# Documentation
docs: semantic commit conventions

# Multiple scopes
feat(examples,tmux): Agent Farm coordination for 50+ agents

# With body
feat: self-healing agent system

Agents monitor themselves and automatically recover from failures.
Includes health checks, circuit breaker pattern, and checkpoint
restoration.

# Breaking change
feat!: new coordination protocol schema

BREAKING CHANGE: coordination.json format has changed. Migration
required for existing multi-agent setups. See migration guide.
```

**Bad commits (avoid these):**

```bash
# Redundant verb
feat: add user authentication  # "feat" already implies adding
fix: adjust error handling    # "fix" already implies adjusting
docs: update README           # "docs" already implies updating

# Not lowercase
Feat: User Authentication
fix: README Updates

# Past tense
feat: added authentication
fix: fixed broken links

# Not imperative
feat: adds authentication
fix: fixing broken links

# Too vague
fix: stuff
chore: updates

# With period
feat: authentication system.
```

### Subject Line Guidelines

The subject should complete this sentence:
> "If applied, this commit will **[your subject line]**"

Examples:
- ✅ "If applied, this commit will **user authentication**" (feat)
- ✅ "If applied, this commit will **broken cross-references**" (fix)
- ✅ "If applied, this commit will **README improvements**" (docs)

### Body Guidelines

Use the body to explain:
- **What** changed
- **Why** it changed
- **Any** breaking changes or important notes

```
feat: circuit breaker pattern for CI agent

Prevents infinite loops when CI keeps failing on the same issue.
After 3 consecutive failures, the agent pauses for 1 hour and
sends an alert.

Includes configurable thresholds and timeout duration.
```

### Footer

Use footer for:
- **Breaking changes**: `BREAKING CHANGE: description`
- **Issue references**: `Closes #123`, `Fixes #456`, `Refs #789`
- **Co-authors**: `Co-Authored-By: Name <email>`

## Changesets Workflow

We use [changesets](https://github.com/changesets/changesets) to manage versions and generate changelogs. This is automated via GitHub Actions.

### What are Changesets?

Changesets are markdown files that describe changes made to the project. They:
- Track what changed and why
- Determine version bumps (major/minor/patch)
- Generate changelog entries automatically
- Create release notes

### Creating a Changeset

**Every PR must include a changeset** (except for docs-only changes to README/CONTRIBUTING).

After making changes, create a changeset:

```bash
bun changeset
# or
bun changeset:add
```

This interactive CLI will:
1. Ask what type of change (major, minor, patch)
2. Ask for a summary of the change
3. Create a `.changeset/*.md` file

**Tip**: Write clear summaries - they become your changelog entries **and GitHub release notes**!

### Changeset Types

Follow [semantic versioning](https://semver.org/):

| Type | When to Use | Example |
|------|-------------|---------|
| **Major** | Breaking change, incompatible changes | `feat!: new coordination protocol` |
| **Minor** | New feature, backwards-compatible | `feat: agent monitoring dashboard` |
| **Patch** | Bug fix, backwards-compatible | `fix: broken links in 07-examples.md` |

**For documentation**:
- New major section/guide → `minor`
- New subsection/examples → `patch`
- Bug fixes/typos → `patch`
- Breaking reorganization → `major`

### Example Changeset Flow

```bash
# 1. Create feature branch
git checkout -b feat/agent-monitoring

# 2. Make your changes
# Edit files...

# 3. Create changeset
bun changeset
# Select: minor
# Summary: "agent monitoring dashboard with real-time metrics"

# 4. Commit everything (including the changeset)
git add .
git commit -m "feat: agent monitoring dashboard"

# 5. Push and create PR
git push origin feat/agent-monitoring
```

### What Happens Next (Automated)

1. **PR Check**: GitHub Actions validates changeset exists
2. **PR Merged**: Changesets bot detects unreleased changesets
3. **Version PR Created**: Bot creates "chore: version packages" PR that:
   - Consumes all changesets
   - Updates version in `package.json`
   - Updates `CHANGELOG.md` with rich GitHub links
   - Deletes consumed changeset files
4. **Merge Version PR**: Automatically creates GitHub release
   - **Release notes include full changelog** - Your changeset summaries appear in the release
   - Git tag created (v2.0.0, v2.1.0, etc.)
   - Formatted with Major/Minor/Patch sections
   - Includes commit links and contributor attribution
   - Visible at https://github.com/renchris/continuously-running-agents/releases

### Manual Release Process (if needed)

If you need to release manually:

```bash
# 1. Version packages (consumes changesets)
bun run version

# 2. Review CHANGELOG.md and package.json

# 3. Commit version changes
git add .
git commit -m "chore: version packages"

# 4. Tag and push
git tag v1.1.0
git push --follow-tags
```

### Changeset Best Practices

#### Good Changeset Summaries

✅ **Clear and descriptive**:
```markdown
---
"continuously-running-agents": minor
---

LLM provider setup with OVHCloud integration

Adds comprehensive guide for setting up Anthropic API with OVHCloud VMs.
Includes cost calculators, decision matrices, and resource requirements.
```

❌ **Too vague**:
```markdown
---
"continuously-running-agents": patch
---

Updates
```

#### Multiple Changes in One PR

If your PR includes multiple unrelated changes, create multiple changesets:

```bash
bun changeset  # For first change
bun changeset  # For second change
```

Each changeset file will be processed independently.

#### Skipping Changesets

**Only skip changesets for**:
- README updates (not content changes)
- CONTRIBUTING.md updates
- Code comment changes
- `.gitignore` or config tweaks

**Everything else needs a changeset**, including:
- New documentation
- Content updates
- Examples
- Bug fixes

### GitHub Actions Integration

We have two workflows:

**`.github/workflows/release.yml`** (runs on push to main):
- Detects changesets
- Creates "Version Packages" PR
- Updates CHANGELOG.md with `@changesets/changelog-github`
  - Links to commits, PRs, and issues automatically
  - Attributes contributors (Thanks @username!)
- **Creates GitHub releases** with `createGithubReleases: true`
  - Release notes contain full changelog content
  - Formatted with Major/Minor/Patch sections
  - Same format as [Next.js releases](https://github.com/vercel/next.js/releases)

**`.github/workflows/pr-check.yml`** (runs on PRs):
- Validates changeset exists
- Checks changeset format
- Fails if changeset missing

### Troubleshooting

**"No changeset found" error on PR**:
```bash
# Create a changeset
bun changeset

# Add and commit it
git add .changeset/
git commit -m "chore: changeset"
git push
```

**Want to preview version bump**:
```bash
bun run version:preview
# Shows what version would be without actually changing files
```

**Check current changeset status**:
```bash
bunx changeset status
# Shows all pending changesets and what they'll do
```

## Pull Request Guidelines

1. **One concern per PR** - Keep PRs focused
2. **Reference issues** - Link to related issues
3. **Add changeset** - Include changeset in your PR
4. **Update docs** - Update relevant documentation
5. **Test locally** - Verify all markdown renders correctly

### PR Title Format

Use the same semantic commit format:

```
feat: circuit breaker for CI agents
fix(tmux): session persistence
docs: contribution guidelines
```

## Documentation Guidelines

When contributing documentation:

1. **Follow existing structure** - Match the style of other docs
2. **Use code examples** - Show, don't just tell
3. **Link between docs** - Cross-reference related content
4. **Test links** - Verify all cross-references work
5. **Run linter** - Ensure markdownlint compliance

### Adding New Examples

When adding to `07-examples.md`:

1. Follow the pattern: Concept → Setup → Usage → Benefits
2. Include complete, copy-paste ready code
3. Add to the Tool Comparison Matrix if applicable
4. Update README navigation if needed

### Adding New Learning Paths

When modifying `00-getting-started.md`:

1. Include all sections: Goal, Prerequisites, Steps, Tutorial, Success Criteria
2. Provide time estimates
3. Link to relevant detailed guides
4. Add to Navigation by Use Case section

## Code of Conduct

- **Be respectful** - Treat everyone with respect
- **Be constructive** - Provide helpful feedback
- **Be patient** - Not everyone has the same experience level
- **Be inclusive** - Welcome contributions from all backgrounds

## Questions?

- **Issues**: Open a GitHub issue
- **Discussions**: Use GitHub Discussions
- **Urgent**: Tag maintainers in your PR

## Attribution

All contributions will be attributed in:
- Git commit history
- CHANGELOG.md (via changesets)
- Release notes

Thank you for contributing! 🎉
