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

We use [changesets](https://github.com/changesets/changesets) to manage versions and generate changelogs.

### Creating a Changeset

After making changes, create a changeset:

```bash
npm run changeset
```

This will:
1. Ask what type of change (major, minor, patch)
2. Ask for a summary of the change
3. Create a `.changeset/*.md` file

### Changeset Types

Follow [semantic versioning](https://semver.org/):

- **Major** (breaking change): `feat!: new API`, incompatible changes
- **Minor** (new feature): `feat: new capability`, backwards-compatible
- **Patch** (bug fix): `fix: error handling`, backwards-compatible fixes

### Example Changeset Flow

```bash
# 1. Make your changes
git checkout -b feat/agent-monitoring

# Edit files...

# 2. Create changeset
npm run changeset
# Select: minor
# Summary: "agent monitoring dashboard with real-time metrics"

# 3. Commit everything (including the changeset)
git add .
git commit -m "feat: agent monitoring dashboard"

# 4. Push and create PR
git push origin feat/agent-monitoring
```

### Release Process

When ready to release:

```bash
# 1. Version packages (consumes changesets)
npm run version

# 2. Review CHANGELOG.md

# 3. Commit version changes
git add .
git commit -m "chore: release v1.1.0"

# 4. Tag and push
git tag v1.1.0
git push --follow-tags
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
