# Continuously Running Agents - AI Agent Guide

> Concise guide for AI coding agents working on this knowledge base for running Claude Code agents 24/7.

## Project Overview

Knowledge base for deploying and managing autonomous Claude Code agents on cloud VPS infrastructure. Compiled from community research (March-October 2025) including patterns from @levelsio, @ericzakariasson, and production deployments.

## Repository Structure

```
continuously-running-agents/
├── 00-13-*.md           # Core documentation (read in order)
├── scripts/             # Setup, monitoring, deployment automation
│   ├── setup/          # Installation and configuration
│   ├── monitoring/     # Resource tracking and health checks
│   └── install-git-hooks.sh  # ⚠️ Run this first
├── .claude/            # Claude Code project settings
├── .changeset/         # Version management
├── config/             # Tmux and systemd configurations
└── AGENTS.md           # This file (symlinked to CLAUDE.md, .cursorrules, etc.)
```

## Quick Setup

```bash
# Install git hooks (commit validation)
bash scripts/install-git-hooks.sh

# Deploy new autonomous agent
bash scripts/start-agent-yolo.sh <agent_number> "<task_description>"

# Monitor running agents
bash scripts/monitor-agents-yolo.sh

# View resource usage
tail -f ~/agents/logs/resource-usage.log
```

## Commit Message Format (STRICTLY ENFORCED)

**Format**: `<type>(<scope>): <subject>`

**Critical Rules**:
1. **Lowercase** - everything except proper nouns, titles, acronyms
2. **NO redundant verbs** - type already implies action:
   - ❌ `feat: add feature` → ✅ `feat: feature name`
   - ❌ `fix: adjust bug` → ✅ `fix: bug description`
   - ❌ `docs: update guide` → ✅ `docs: guide improvements`
   - ❌ `chore: configure` → ✅ `chore: configuration updates`
3. **Imperative mood** - command form ("change" not "changed")
4. **No period** at end of subject
5. **Max 50 characters** for subject line

**Good Examples**:
```bash
feat: multi-agent task distribution
feat(tmux): session persistence across reboots
fix: broken documentation cross-references
docs: semantic commit conventions
docs(cost): production deployment analysis
chore: dependency updates
```

**Bad Examples (Will Be REJECTED)**:
```bash
feat: Add multi-agent task distribution    # ❌ redundant "Add", capitalized
fix: Fix broken links                       # ❌ redundant "Fix", capitalized
docs: Update README                         # ❌ redundant "Update", capitalized
docs(cost): Add cost analysis               # ❌ redundant "Add", capitalized
```

**Enforcement**: commit-msg hook automatically validates and rejects violations.

**Full conventions**: See CONTRIBUTING.md (432 lines) for complete guide.

## Code Style

- **Documentation**: Markdown with consistent heading levels
- **Scripts**: Bash with `set -euo pipefail` for safety
- **Line length**: 100 chars for code, 80 for markdown where reasonable
- **Follow existing patterns**: Check similar files before creating new ones

## Testing & Validation

```bash
# Markdown linting
markdownlint *.md

# Test script syntax
bash -n script.sh

# Commit message validation (automatic)
git commit -m "..."  # Hook validates format
```

## Key Documentation

**Essential Reading**:
- `README.md` (327 lines): Complete project overview, learning paths
- `CONTRIBUTING.md` (432 lines): Full commit conventions, contributing workflow
- `AGENT-OPERATIONS.md` (in cloud-agent repo): AI agent operation policy, prompts, optimization

**Core Guides** (read in order):
1. `00-getting-started.md`: Structured learning paths for all skill levels
2. `01-infrastructure.md`: Cloud VPS setup and providers
3. `02-tmux-setup.md`: Session persistence and orchestration
4. `03-remote-access.md`: Mobile access via Tailscale/Mosh
5. `04-claude-configuration.md`: Autonomous operation patterns
6. `05-cost-optimization.md`: Pricing and resource strategies
7. `06-security.md`: Server hardening and isolation
8. `07-examples.md`: Real-world setups and patterns

## Working Guidelines

**Before Making Changes**:
1. Run `bash scripts/install-git-hooks.sh` (first time only)
2. Read relevant documentation in numbered guides
3. Follow existing patterns and conventions
4. Test locally before committing

**When Committing**:
- Hook validates format automatically
- Errors show helpful examples
- Fix and retry if rejected

**When Creating PRs**:
- Title follows commit format
- One PR = one logical change
- Reference related issues/docs
- **NEVER merge to main without approval** (see AGENT-OPERATIONS.md)

## Common Tasks

**Add new documentation**:
```bash
# Follow numbering scheme: XX-topic-name.md
# Update README.md navigation
# Create changeset if minor/major change
```

**Update existing docs**:
```bash
# Edit file
# Update "Last Updated" date if present
# Commit with docs(scope): format
```

**Add new script**:
```bash
# Place in scripts/<category>/
# Make executable: chmod +x script.sh
# Add header comment with usage
# Document in relevant guide
```

## Critical Gotchas

⚠️ **Branch Protection**:
- Main branch requires PRs
- `enforce_admins=false`: Owner can bypass, collaborators (agents) cannot
- Direct push to main blocked for machine users

⚠️ **Rate Limits** (Claude Max Plan):
- 225 messages per 5 hours total
- Plan accordingly when running multiple agents
- See `ACTUAL-DEPLOYMENT-COSTS.md` for analysis

⚠️ **Commit Validation**:
- Hook rejects bad commits immediately
- No way to force-push bad commits
- Fix message format and retry

⚠️ **Tmux Sessions**:
- Persist across disconnects
- Attach with `tmux attach -t <session>`
- Kill carefully: `tmux kill-session -t <session>`

## Resource Limits (Per Agent)

Enforced via ulimit in start scripts:
- **CPU**: 80% max per agent
- **Memory**: 2GB max per agent
- **Disk writes**: 5GB per session
- **Runtime**: 8 hours max (auto-terminate)

See `scripts/start-agent-yolo.sh` for implementation.

## References

**Documentation Standards**:
- AGENTS.md (this file): Works with Claude Code, Cursor, Cline, Windsurf
- Symlinked as: CLAUDE.md, .cursorrules, .clinerules/rules.md

**Related Projects**:
- Tmux Orchestrator, Claude Squad, tmux-mcp (see 07-examples.md)

**Community Sources**:
- X/Twitter posts from @levelsio, @ericzakariasson
- GitHub projects and discussions
- Anthropic Claude Code documentation

---

**Last Updated**: 2025-10-21
**Standard**: AGENTS.md v1.0 (multi-platform compatible)
