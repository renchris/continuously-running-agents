# Real-World Examples and Working Setups

## Overview

This document contains real-world examples of continuously running agents from the community (March-October 2025).

## Example 1: @levelsio's Rawdog Vibecoding Setup

**Source**: X/Twitter posts, February 2025

### Infrastructure

- **Provider**: Hetzner VPS ($5/month)
- **Specs**: 2 vCPU, 2GB RAM, 40GB SSD
- **OS**: Ubuntu 24.04 LTS

### Workflow

```text
1. SSH into Hetzner VPS (using Termius on iPhone)
2. Install Claude Code CLI on server
3. Start Claude Code
4. Claude builds/modifies apps directly on server
5. Refresh browser to see changes live
6. No git workflow, no deployment pipeline
```

### What Makes It Work

**Speed**:
- "Built entire 3D computer app in just a few hours"
- "I've never been so fast"
- No deployment lag, instant feedback

**Simplicity**:
- One environment (production = development)
- No build/deploy pipeline
- Direct manipulation

**Mobile Coding**:
- "Can code on phone while GF is shopping"
- Uses Termius on iOS
- Mosh for persistent connections

### Security Configuration (from @levelsio)

```bash
# Disable password auth, use only key-based auth
PasswordAuthentication no

# Install fail2ban on SSH
sudo apt install fail2ban

# Enable unattended-upgrades with auto reboot
sudo apt install unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades

# Enable firewall in Hetzner dashboard
# Block all ports except 22 (SSH), 80 (HTTP), 443 (HTTPS)

# Optional: Tailscale for private network
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up

# Use Let's Encrypt for SSL
sudo apt install certbot
sudo certbot certonly --standalone -d yourdomain.com
```

### Results

- Multiple successful projects built this way
- Demonstrated with photo booth app, 3D web apps
- Fast iteration, low cost
- Perfect for solo developer MVPs

### Limitations

- Not suitable for team collaboration
- No code review process
- Single point of failure
- Requires comfort with production coding

## Example 2: Mobile Claude Code Setup (Community Standard)

**Source**: Multiple community blog posts, 2025

### Stack

```text
Hardware:
- Mac Mini / VPS at "home base"
- iPhone / Android phone for access

Software:
- Tailscale (private network)
- Blink Shell / Termius (mobile SSH client)
- Mosh (mobile shell)
- tmux (session persistence)
- Claude Code CLI
```

### Setup Steps

#### 1. Server Side

```bash
# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up

# Note Tailscale IP
tailscale ip -4  # e.g., 100.64.1.5

# Install Mosh
sudo apt install mosh
sudo ufw allow 60000:61000/udp

# Install tmux
sudo apt install tmux

# Install Claude Code
npm install -g @anthropic-ai/claude-code

# Create agent startup script
cat > ~/start-agent.sh <<'EOF'
#!/bin/bash
tmux new-session -d -s claude "claude"
echo "Agent started. Attach with: tmux attach -t claude"
EOF

chmod +x ~/start-agent.sh
```

#### 2. Mobile Side (iOS)

```text
1. Install Tailscale app from App Store
2. Login with same account as server
3. Enable VPN

4. Install Blink Shell ($20)
5. Add server config:
   - Host: mac-mini (or use Tailscale IP)
   - User: your-username
   - Port: 22

6. Connect via Mosh:
   mosh you@100.64.1.5

7. Attach to tmux session:
   tmux attach -t claude

Result: Full Claude Code access from phone!
```

### Usage Patterns

**Morning commute**:
- Open Blink on phone
- Connect via Mosh
- Check on overnight agent progress
- Steer agent in new direction

**At coffee shop**:
- Switch from phone to laptop
- Same Tailscale network
- `mosh laptop@100.64.1.5`
- Seamless continuation

**Network changes**:
- Walking WiFi → Cellular
- Mosh maintains connection
- tmux persists session
- Zero interruption

### Benefits

✅ Code from literally anywhere
✅ Survives network changes
✅ Fully encrypted (WireGuard)
✅ Switch devices seamlessly
✅ Session persistence

### Cost

- Tailscale: Free tier (up to 100 devices)
- Blink Shell: $20 one-time (iOS)
- Mosh: Free
- tmux: Free
- VPS: $5-15/month

**Total**: ~$5-15/month + $20 one-time

## Example 3: Tmux Orchestrator (Autonomous Multi-Agent)

**Source**: GitHub - Jedward23/Tmux-Orchestrator

### Concept

Multiple Claude agents working autonomously across different projects:

```text
Project Manager Agent
  ├── Frontend Agent (in tmux window 1)
  ├── Backend Agent (in tmux window 2)
  └── Testing Agent (in tmux window 3)
```

### Features

1. **Self-Scheduling**: Agents schedule their own check-ins
2. **Coordination**: PM assigns tasks to appropriate agents
3. **Persistence**: Work continues even when laptop is closed
4. **Scaling**: Run multiple teams on different projects

### Setup

```bash
# Clone repository
git clone https://github.com/Jedward23/Tmux-Orchestrator.git
cd Tmux-Orchestrator

# Modify config for your paths
nano config.yml

# Key configuration:
spec_folder: /workspace/spec
task_manager_folder: /workspace/tasks
check_in_interval: 900  # 15 minutes

# Enable dangerous mode for autonomy
dangerous_mode: true
```

### Agent Roles

**Project Manager**:
```yaml
role: project_manager
responsibilities:
  - Review project spec
  - Break down into tasks
  - Assign to worker agents
  - Coordinate progress
  - Report to human
prompt: |
  You are a project manager overseeing development.
  Review spec/ folder for requirements.
  Assign tasks to frontend, backend, and testing agents.
  Check in every 15 minutes with progress update.
```

**Worker Agents**:
```yaml
role: frontend_developer
tmux_window: 1
prompt: |
  You are the frontend developer.
  Check task-manager/ for assigned tasks.
  Implement UI components and styles.
  Run tests before committing.
  Report progress to PM every 15 minutes.
```

### Workflow

```text
Hour 0:00 - PM reads spec, creates task breakdown
Hour 0:15 - Tasks assigned to workers
Hour 0:15 - Frontend agent starts on UI
Hour 0:15 - Backend agent starts on API
Hour 0:15 - Testing agent sets up test framework
Hour 0:30 - Agents report progress to PM
Hour 0:45 - PM adjusts priorities based on blockers
...continues autonomously...
```

### Results

- Projects progressing 24/7
- Minimal human intervention needed
- Coordinated multi-agent work
- Automatic checkpoints and commits

### Challenges

- Requires well-defined specs
- Agents can get stuck (need monitoring)
- High API usage costs
- Debugging multi-agent coordination

### Mitigations

```bash
# Set max-turns to prevent runaway costs
MAX_TURNS=50

# Checkpoint every hour
CHECKPOINT_INTERVAL=3600

# Monitor and alert on issues
bash monitor-agents.sh &
```

## Example 4: Claude Squad (Parallel Task Execution)

**Source**: GitHub - smtg-ai/claude-squad

### Concept

Manage multiple AI agents in isolated tmux sessions with git worktrees.

### Stack

- tmux: Isolated sessions per agent
- git worktrees: Separate branches per task
- Claude Code / Codex / Aider / Gemini

### Complete Setup Guide

```bash
# 1. Install Claude Squad
git clone https://github.com/smtg-ai/claude-squad.git
cd claude-squad
./install.sh

# Creates:
# - ~/.claude-squad/ config directory
# - /usr/local/bin/cs symlink
# - ~/agents/ workspace directory

# 2. Configure
cat > ~/.claude-squad/config.json <<'EOF'
{
  "workspaceRoot": "~/agents",
  "defaultModel": "claude-sonnet-4",
  "maxConcurrentAgents": 5,
  "tmuxPrefix": "C-b",
  "autoCommit": true,
  "approvalRequired": false
}
EOF

# 3. Initialize in your project
cd ~/my-project
cs init

# Creates:
# - .squad/ directory
# - .squad/agents.json (agent registry)
# - .squad/tasks.json (task queue)
```

### TUI Commands (Complete Reference)

```text
# Launch TUI
cs

# Inside TUI:
# Navigation
#   j/k or ↑/↓  - Move between agents
#   Enter       - Attach to agent terminal
#   q           - Detach from agent (back to TUI)
#   Q           - Quit TUI completely

# Agent Management
#   n           - Create new agent
#   d           - Delete selected agent
#   r           - Restart selected agent
#   p           - Pause/resume agent
#   l           - View agent logs

# Task Management
#   t           - Add task to queue
#   T           - View all tasks
#   a           - Assign task to agent

# Status
#   s           - Show detailed status
#   h           - Show help
#   /           - Search agents/tasks
```

### Workflow Examples

**Example 1: Feature Development Sprint**

```bash
# Create squad workspace
cs init

# Spawn specialized agents
cs create frontend "Build user profile page with React"
cs create backend "Implement user profile API endpoints"
cs create tests "Write E2E tests for profile feature"
cs create docs "Document profile feature in API docs"

# Monitor all agents
cs status

# Output:
# ┌──────────────────────────────────────────┐
# │ Agent: frontend (session: cs-frontend)   │
# │ Status: In progress                      │
# │ Branch: feature/user-profile-ui          │
# │ Last activity: 2 minutes ago             │
# │ Progress: 3/5 tasks complete             │
# ├──────────────────────────────────────────┤
# │ Agent: backend (session: cs-backend)     │
# │ Status: Blocked                          │
# │ Branch: feature/user-profile-api         │
# │ Last activity: 15 minutes ago            │
# │ Error: Database migration needed         │
# ├──────────────────────────────────────────┤
# │ Agent: tests (session: cs-tests)         │
# │ Status: Waiting                          │
# │ Branch: feature/user-profile-tests       │
# │ Dependencies: frontend, backend          │
# └──────────────────────────────────────────┘

# Intervene on blocked agent
cs attach backend
# Fix the issue manually
# Press Ctrl+b d to detach

# When done, merge all branches
cs merge-all --squash
```

**Example 2: Refactoring Project**

```bash
# Create refactoring agents
for module in auth users payments notifications; do
    cs create "refactor-$module" \
        "Refactor $module to use TypeScript and add tests"
done

# Agents work in parallel on separate modules
# Each in isolated git worktree
# No merge conflicts

# Review progress
cs review --all

# Merge completed agents
cs merge refactor-auth
cs merge refactor-users
# etc.
```

### Advanced: Custom Agent Templates

```bash
# Create agent template
cat > ~/.claude-squad/templates/test-writer.json <<'EOF'
{
  "name": "test-writer",
  "prompt": "You are a test writing specialist. For each file you're given:\n1. Analyze the code\n2. Write comprehensive unit tests\n3. Achieve >90% coverage\n4. Follow Jest best practices\n5. Commit tests with message: 'test: add tests for X'",
  "allowedTools": ["Read", "Write", "Edit", "Bash"],
  "workingDirectory": "tests/",
  "model": "claude-haiku-3-5"
}
EOF

# Use template
cs create-from-template test-writer "Write tests for auth module"
```

### YOLO Mode (Autonomous)

```bash
# Auto-accept all agent actions
cs start --yolo

# Even more aggressive: auto-merge
cs start --yolo --auto-merge

# Safeguards even in YOLO mode:
# - Runs tests before merge
# - Creates backup branch
# - Monitors for infinite loops
# - Stops on critical errors
```

### Git Worktrees Integration

Claude Squad automatically manages git worktrees:

```text
# Squad creates structure:
~/my-project/              # Main repo
├── .git/
├── .squad/
└── worktrees/
    ├── agent-1/           # Separate worktree
    │   └── [branch: task/agent-1]
    ├── agent-2/
    │   └── [branch: task/agent-2]
    └── agent-3/
        └── [branch: task/agent-3]

# Each agent works in isolated filesystem
# No conflicts, no need to stash/switch branches
# All commits tracked separately
```

### Coordination Protocol

```bash
# Agents communicate via .squad/coordination.json
{
  "agents": {
    "frontend": {
      "status": "working",
      "task": "Build profile UI",
      "dependencies": [],
      "outputs": ["src/components/Profile.tsx"],
      "lastHeartbeat": "2025-10-15T10:30:00Z"
    },
    "backend": {
      "status": "blocked",
      "task": "Profile API",
      "dependencies": ["database schema"],
      "blockedReason": "Waiting for migration",
      "lastHeartbeat": "2025-10-15T10:29:00Z"
    },
    "tests": {
      "status": "waiting",
      "task": "E2E tests",
      "dependencies": ["frontend", "backend"],
      "lastHeartbeat": "2025-10-15T10:30:00Z"
    }
  },
  "sharedResources": {
    "database": "locked_by:backend",
    "testServer": "available"
  }
}
```

### Benefits

✅ Parallel task execution (5-10x faster)
✅ Isolated git branches (zero conflicts)
✅ Easy task review and merge
✅ Supports multiple agent types
✅ Background execution
✅ TUI for visual management
✅ Auto-coordination between agents

### Use Cases

- Feature development sprints (multiple agents per feature)
- Large refactoring projects (one agent per module)
- Test generation (agents work through codebase)
- Documentation updates (parallel doc writing)
- Polyglot projects (specialized agents per language)

### Cost Analysis

```text
# Typical sprint: 3 agents, 8 hours
# - Frontend agent: $12 (Sonnet)
# - Backend agent: $15 (Sonnet)
# - Test agent: $4 (Haiku)
# Total: ~$31 for 8-hour parallel sprint

# Compared to sequential: 24 hours @ $31 = same cost, 3x slower
# Benefit: Time savings, not cost savings
```

## Example 5: Continuous Integration Agent with Circuit Breaker

**Community Pattern**, 2025

### Concept

Claude agent that monitors CI failures and auto-fixes them, with circuit breaker to prevent infinite loops.

### Basic Setup

```bash
#!/bin/bash
# ci-agent.sh

while true; do
    # Check if CI is failing
    CI_STATUS=$(gh run list --limit 1 --json status -q '.[0].status')

    if [ "$CI_STATUS" == "failure" ]; then
        echo "CI failing, triggering fix agent..."

        # Get failure logs
        FAILURE_LOGS=$(gh run view --log-failed)

        # Ask Claude to fix
        claude -p "$(cat <<EOF
CI is currently failing. Here are the failure logs:

$FAILURE_LOGS

Please:
1. Analyze the failure
2. Fix the issue
3. Run tests locally to verify
4. Commit the fix
5. Push to trigger new CI run
EOF
)" --dangerously-skip-permissions

    fi

    # Check every 10 minutes
    sleep 600
done
```

### Production: Circuit Breaker Pattern

```bash
#!/bin/bash
# ci-agent-with-circuit-breaker.sh

STATE_FILE=~/.ci-agent-state.json
MAX_CONSECUTIVE_FAILURES=3
CIRCUIT_BREAKER_TIMEOUT=3600  # 1 hour

# Initialize state if not exists
if [ ! -f "$STATE_FILE" ]; then
    cat > "$STATE_FILE" <<'EOF'
{
  "consecutiveFailures": 0,
  "lastFailureHash": "",
  "circuitBreakerOpen": false,
  "circuitBreakerOpenedAt": 0,
  "totalFixes": 0,
  "successfulFixes": 0
}
EOF
fi

get_state() {
    jq -r ".$1" "$STATE_FILE"
}

update_state() {
    local key=$1
    local value=$2
    jq ".$key = $value" "$STATE_FILE" > "$STATE_FILE.tmp"
    mv "$STATE_FILE.tmp" "$STATE_FILE"
}

get_failure_hash() {
    # Hash of failure logs to detect same failure repeating
    echo "$1" | sha256sum | cut -d' ' -f1
}

check_circuit_breaker() {
    local open=$(get_state circuitBreakerOpen)
    if [ "$open" == "true" ]; then
        local opened_at=$(get_state circuitBreakerOpenedAt)
        local now=$(date +%s)
        local elapsed=$((now - opened_at))

        if [ $elapsed -gt $CIRCUIT_BREAKER_TIMEOUT ]; then
            echo "Circuit breaker timeout expired, resetting..."
            update_state circuitBreakerOpen false
            update_state consecutiveFailures 0
            return 0
        else
            echo "Circuit breaker OPEN. Waiting $((CIRCUIT_BREAKER_TIMEOUT - elapsed))s..."
            return 1
        fi
    fi
    return 0
}

open_circuit_breaker() {
    echo "⚠️  CIRCUIT BREAKER TRIGGERED ⚠️"
    echo "Agent has failed $MAX_CONSECUTIVE_FAILURES times in a row."
    echo "Pausing for $CIRCUIT_BREAKER_TIMEOUT seconds..."

    update_state circuitBreakerOpen true
    update_state circuitBreakerOpenedAt "$(date +%s)"

    # Send alert (example: via curl to webhook)
    curl -X POST "$ALERT_WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d "{\"text\":\"CI Agent circuit breaker triggered after $MAX_CONSECUTIVE_FAILURES failures\"}"
}

while true; do
    # Check circuit breaker
    if ! check_circuit_breaker; then
        sleep 300
        continue
    fi

    # Check CI status
    CI_STATUS=$(gh run list --limit 1 --json status,conclusion -q '.[0] | "\(.status):\(.conclusion)"')

    if [[ "$CI_STATUS" == *"failure"* ]]; then
        echo "CI failing, analyzing..."

        # Get failure details
        FAILURE_LOGS=$(gh run view --log-failed)
        FAILURE_HASH=$(get_failure_hash "$FAILURE_LOGS")
        LAST_HASH=$(get_state lastFailureHash)

        # Check if same failure repeating
        if [ "$FAILURE_HASH" == "$LAST_HASH" ]; then
            CONSECUTIVE=$(($(get_state consecutiveFailures) + 1))
            update_state consecutiveFailures "$CONSECUTIVE"

            if [ $CONSECUTIVE -ge $MAX_CONSECUTIVE_FAILURES ]; then
                open_circuit_breaker
                continue
            fi

            echo "Same failure detected ($CONSECUTIVE/$MAX_CONSECUTIVE_FAILURES attempts)"
        else
            # New failure, reset counter
            update_state consecutiveFailures 1
            update_state lastFailureHash "\"$FAILURE_HASH\""
        fi

        # Attempt fix
        echo "Triggering fix agent..."
        if claude -p "$(cat <<EOF
CI is failing. Analyze and fix:

$FAILURE_LOGS

Steps:
1. Identify root cause
2. Implement fix
3. Run tests locally
4. Commit with message: "fix(ci): address test failure"
5. Push to trigger new CI run

If you cannot fix this issue, respond with: CANNOT_FIX: [reason]
EOF
)" --dangerously-skip-permissions; then
            echo "Fix agent completed"

            # Wait for new CI run
            sleep 120

            # Check if fixed
            NEW_STATUS=$(gh run list --limit 1 --json conclusion -q '.[0].conclusion')
            if [ "$NEW_STATUS" == "success" ]; then
                echo "✅ Fix successful!"
                update_state consecutiveFailures 0
                update_state successfulFixes "$(($(get_state successfulFixes) + 1))"
            fi
        fi

        update_state totalFixes "$(($(get_state totalFixes) + 1))"
    else
        # CI passing, reset failure counter
        if [ $(get_state consecutiveFailures) -gt 0 ]; then
            echo "CI passing, resetting failure counter"
            update_state consecutiveFailures 0
        fi
    fi

    # Check every 10 minutes
    sleep 600
done
```

### Advanced: GitHub Actions Integration

From Eric Zakariasson's tweet:

```yaml
# .github/workflows/auto-fix.yml
name: Auto-fix on CI Failure

on:
  workflow_run:
    workflows: ["CI"]
    types:
      - completed

jobs:
  auto-fix:
    if: ${{ github.event.workflow_run.conclusion == 'failure' }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Cursor CLI
        run: curl https://cli.cursor.com -fsS | bash

      - name: Run fix agent
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          cursor-agent -p "CI failed. Review logs and create PR with fix" \
            --force

      - name: Create PR
        run: gh pr create --title "Auto-fix: CI failure" --body "Generated by agent"
```

### Monitoring Dashboard

```bash
#!/bin/bash
# ci-agent-dashboard.sh

STATE_FILE=~/.ci-agent-state.json

echo "=== CI Agent Status ==="
echo ""
echo "Total fixes attempted:    $(jq -r .totalFixes $STATE_FILE)"
echo "Successful fixes:         $(jq -r .successfulFixes $STATE_FILE)"
echo "Success rate:             $(jq -r '(.successfulFixes / .totalFixes * 100 | floor)' $STATE_FILE)%"
echo ""
echo "Consecutive failures:     $(jq -r .consecutiveFailures $STATE_FILE)/3"
echo "Circuit breaker:          $(jq -r 'if .circuitBreakerOpen then "OPEN ⚠️" else "CLOSED ✅" end' $STATE_FILE)"
echo ""

# Recent CI history
echo "=== Recent CI Runs ==="
gh run list --limit 10 --json conclusion,createdAt,displayTitle | \
    jq -r '.[] | "\(.createdAt | split("T")[0]) \(.createdAt | split("T")[1] | split(".")[0]) - \(.conclusion) - \(.displayTitle)"'
```

### Results

- Reduces time to fix failing CI by 60-80%
- Catches regressions within minutes
- Learns common failure patterns
- Frees developers from toil
- Circuit breaker prevents infinite loops
- Alerts team when manual intervention needed

## Example 6: Documentation Agent

**Community Pattern**

### Concept

Agent that continuously updates documentation as code changes.

```bash
#!/bin/bash
# docs-agent.sh

# Watch for code changes
inotifywait -m -r --format '%w%f' -e modify src/ | while read file; do
    echo "File changed: $file"

    # Update related documentation
    claude -p "$(cat <<EOF
The file $file was just modified.

Please:
1. Review the changes
2. Update relevant documentation in docs/
3. Update code comments if needed
4. Update README if public API changed
5. Commit documentation updates
EOF
)"

    # Small delay to batch rapid changes
    sleep 60
done
```

### Results

- Documentation stays up-to-date
- Reduces documentation debt
- Automatic API doc generation
- Lower maintenance burden

## Example 7: Cost-Optimized Multi-Model Setup

**Community Pattern**, 2025

### Concept

Use different models for different task types to optimize cost.

```bash
#!/bin/bash
# smart-dispatch.sh

TASK_TYPE=$1
TASK_DESC=$2

case $TASK_TYPE in
    "plan"|"architecture"|"complex")
        # High complexity: Use Opus 4
        MODEL="claude-opus-4"
        echo "Using Opus 4 for complex task"
        ;;

    "implement"|"feature"|"bugfix")
        # Standard work: Use Sonnet 4
        MODEL="claude-sonnet-4"
        echo "Using Sonnet 4 for implementation"
        ;;

    "test"|"docs"|"refactor"|"simple")
        # Routine work: Use Haiku
        MODEL="claude-haiku-3-5"
        echo "Using Haiku for routine task"
        ;;

    *)
        MODEL="claude-sonnet-4"
        ;;
esac

claude --model $MODEL -p "$TASK_DESC"
```

### Usage

```bash
# High-level planning
./smart-dispatch.sh plan "Design authentication system architecture"

# Feature implementation
./smart-dispatch.sh implement "Build user login page"

# Testing
./smart-dispatch.sh test "Generate unit tests for auth service"

# Documentation
./smart-dispatch.sh docs "Update API documentation"
```

### Results

- 50-70% cost reduction vs. using Opus for everything
- Appropriate model for each task
- Still high quality on important tasks

## Example 8: VibeTunnel Web Dashboard

**Source**: GitHub - amantus-ai/vibetunnel

### Concept

Monitor multiple Claude agents from web browser.

### Setup

```bash
# On server with agents
git clone https://github.com/amantus-ai/vibetunnel.git
cd vibetunnel
npm install

# Start VibeTunnel
npm start

# Access via Tailscale
# From any device: http://100.x.y.z:8000
```

### Dashboard Features

- Live view of all tmux sessions
- Click to interact with any agent
- Works on tablets, phones
- No SSH client needed
- Multi-agent overview

### Use Case

```text
Scenario: Running 5 agents on different projects

Dashboard shows:
┌─────────────────────────────────┐
│ Agent 1: project-alpha          │
│ Status: Implementing feature... │
├─────────────────────────────────┤
│ Agent 2: project-beta           │
│ Status: Running tests...        │
├─────────────────────────────────┤
│ Agent 3: project-gamma          │
│ Status: Waiting for review      │
└─────────────────────────────────┘

Click any agent to view full terminal and interact.
```

## Example 9: Agent Farm (50+ Parallel Agents)

**Source**: Community pattern for large-scale development

### Concept

Coordinate 50+ specialized agents working on massive codebases or multiple projects simultaneously.

### Architecture

```text
Agent Farm Controller
├── Project Manager Agents (5)
│   ├── PM-Web: Manages 10 web agents
│   ├── PM-API: Manages 10 API agents
│   ├── PM-Mobile: Manages 10 mobile agents
│   ├── PM-Testing: Manages 10 test agents
│   └── PM-Infra: Manages 10 infra agents
└── Shared Services
    ├── Coordination DB (SQLite)
    ├── Task Queue (Redis)
    ├── Resource Manager
    └── Cost Monitor
```

### Setup

```bash
#!/bin/bash
# setup-agent-farm.sh

FARM_ROOT=~/agent-farm
MAX_AGENTS=50

# 1. Create infrastructure
mkdir -p $FARM_ROOT/{agents,coordination,logs,scripts}

# 2. Setup coordination database
cat > $FARM_ROOT/coordination/schema.sql <<'EOF'
CREATE TABLE IF NOT EXISTS agents (
    id INTEGER PRIMARY KEY,
    name TEXT UNIQUE,
    role TEXT,
    status TEXT,
    current_task TEXT,
    assigned_pm TEXT,
    last_heartbeat TIMESTAMP,
    cpu_usage REAL,
    memory_usage REAL,
    api_cost_today REAL
);

CREATE TABLE IF NOT EXISTS tasks (
    id INTEGER PRIMARY KEY,
    description TEXT,
    priority INTEGER,
    assigned_to TEXT,
    status TEXT,
    created_at TIMESTAMP,
    completed_at TIMESTAMP,
    depends_on TEXT
);

CREATE TABLE IF NOT EXISTS resource_locks (
    resource_name TEXT PRIMARY KEY,
    locked_by TEXT,
    locked_at TIMESTAMP,
    expires_at TIMESTAMP
);
EOF

sqlite3 $FARM_ROOT/coordination/farm.db < $FARM_ROOT/coordination/schema.sql

# 3. Create agent spawner
cat > $FARM_ROOT/scripts/spawn-agent.sh <<'EOF'
#!/bin/bash

AGENT_ID=$1
AGENT_ROLE=$2
PM_NAME=$3

AGENT_DIR=$FARM_ROOT/agents/agent-$AGENT_ID
mkdir -p $AGENT_DIR

# Create agent workspace
cd $AGENT_DIR
git init

# Start agent in tmux
tmux new-session -d -s "agent-$AGENT_ID" \
    "claude -p 'You are agent $AGENT_ID with role: $AGENT_ROLE.
    Your PM is: $PM_NAME.
    Check coordination DB for tasks every 5 minutes: $FARM_ROOT/coordination/farm.db
    Report status via: bash $FARM_ROOT/scripts/report-status.sh $AGENT_ID
    Use coordination protocol from: $FARM_ROOT/coordination/protocol.json'"

echo "Agent $AGENT_ID spawned in tmux session agent-$AGENT_ID"

# Register in database
sqlite3 $FARM_ROOT/coordination/farm.db \
    "INSERT INTO agents (id, name, role, status, assigned_pm, last_heartbeat)
     VALUES ($AGENT_ID, 'agent-$AGENT_ID', '$AGENT_ROLE', 'idle', '$PM_NAME', datetime('now'))"
EOF

chmod +x $FARM_ROOT/scripts/spawn-agent.sh

# 4. Create resource manager
cat > $FARM_ROOT/scripts/resource-manager.sh <<'EOF'
#!/bin/bash

DB=$FARM_ROOT/coordination/farm.db

acquire_lock() {
    local resource=$1
    local agent=$2
    local duration=${3:-300}  # 5 minutes default

    # Try to acquire lock
    sqlite3 $DB "INSERT OR IGNORE INTO resource_locks
        (resource_name, locked_by, locked_at, expires_at)
        VALUES ('$resource', '$agent', datetime('now'), datetime('now', '+$duration seconds'))"

    # Check if we got it
    HOLDER=$(sqlite3 $DB "SELECT locked_by FROM resource_locks WHERE resource_name='$resource'")
    if [ "$HOLDER" == "$agent" ]; then
        echo "LOCK_ACQUIRED"
        return 0
    else
        echo "LOCK_HELD_BY:$HOLDER"
        return 1
    fi
}

release_lock() {
    local resource=$1
    local agent=$2
    sqlite3 $DB "DELETE FROM resource_locks WHERE resource_name='$resource' AND locked_by='$agent'"
}

cleanup_expired_locks() {
    sqlite3 $DB "DELETE FROM resource_locks WHERE expires_at < datetime('now')"
}

# Run cleanup every minute
while true; do
    cleanup_expired_locks
    sleep 60
done
EOF

chmod +x $FARM_ROOT/scripts/resource-manager.sh

# 5. Create farm controller
cat > $FARM_ROOT/scripts/farm-controller.sh <<'EOF'
#!/bin/bash

DB=$FARM_ROOT/coordination/farm.db

# Spawn Project Manager agents
for pm in web api mobile testing infra; do
    $FARM_ROOT/scripts/spawn-agent.sh "pm-$pm" "project_manager" "controller"
    sleep 2
done

# Spawn worker agents (10 per PM)
agent_id=1
for pm in web api mobile testing infra; do
    for i in {1..10}; do
        $FARM_ROOT/scripts/spawn-agent.sh $agent_id "worker" "pm-$pm"
        ((agent_id++))
        sleep 1
    done
done

echo "Agent Farm initialized with $agent_id agents"
EOF

chmod +x $FARM_ROOT/scripts/farm-controller.sh

# 6. Create monitoring dashboard
cat > $FARM_ROOT/scripts/dashboard.sh <<'EOF'
#!/bin/bash

DB=$FARM_ROOT/coordination/farm.db

while true; do
    clear
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                    AGENT FARM DASHBOARD                        ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""

    # Agent status summary
    echo "=== Agent Status ==="
    sqlite3 $DB "SELECT status, COUNT(*) FROM agents GROUP BY status" | \
        awk -F'|' '{printf "  %-15s: %d\n", $1, $2}'
    echo ""

    # Active tasks
    echo "=== Active Tasks ==="
    sqlite3 $DB "SELECT COUNT(*) FROM tasks WHERE status='in_progress'" | \
        xargs -I{} echo "  In Progress: {}"
    sqlite3 $DB "SELECT COUNT(*) FROM tasks WHERE status='pending'" | \
        xargs -I{} echo "  Pending: {}"
    echo ""

    # Resource usage
    echo "=== Resource Usage ==="
    sqlite3 $DB "SELECT AVG(cpu_usage), AVG(memory_usage), SUM(api_cost_today) FROM agents" | \
        awk -F'|' '{printf "  Avg CPU: %.1f%%\n  Avg Memory: %.1f%%\n  API Cost Today: $%.2f\n", $1, $2, $3}'
    echo ""

    # Resource locks
    echo "=== Resource Locks ==="
    sqlite3 $DB "SELECT resource_name, locked_by FROM resource_locks" | \
        awk -F'|' '{printf "  %-20s locked by %s\n", $1, $2}'

    # Top 5 busiest agents
    echo ""
    echo "=== Top 5 Busiest Agents ==="
    sqlite3 $DB "SELECT name, current_task, api_cost_today FROM agents
                 WHERE status='working'
                 ORDER BY api_cost_today DESC LIMIT 5" | \
        awk -F'|' '{printf "  %-15s: %s ($%.2f)\n", $1, substr($2,0,30), $3}'

    echo ""
    echo "Press Ctrl+C to exit | Refreshes every 5s"
    sleep 5
done
EOF

chmod +x $FARM_ROOT/scripts/dashboard.sh

echo "Agent Farm setup complete!"
echo ""
echo "Start farm:    bash $FARM_ROOT/scripts/farm-controller.sh"
echo "Dashboard:     bash $FARM_ROOT/scripts/dashboard.sh"
echo "Resource mgr:  bash $FARM_ROOT/scripts/resource-manager.sh &"
```

### Coordination Protocol

```json
{
  "protocol_version": "1.0",
  "communication": {
    "method": "sqlite_db",
    "heartbeat_interval": 60,
    "task_check_interval": 300
  },
  "agent_roles": {
    "project_manager": {
      "responsibilities": [
        "Task breakdown and assignment",
        "Monitor worker progress",
        "Resolve blockers",
        "Report to controller"
      ],
      "max_workers": 10
    },
    "worker": {
      "responsibilities": [
        "Execute assigned tasks",
        "Report progress every 15 min",
        "Request resources via locks",
        "Escalate blockers to PM"
      ]
    }
  },
  "resource_management": {
    "shared_resources": [
      "database",
      "test_environment",
      "deployment_pipeline",
      "api_rate_limits"
    ],
    "lock_duration_default": 300,
    "lock_auto_expire": true
  }
}
```

### Cost Management

```text
# Cost monitoring for 50-agent farm
# Typical costs (24/7 operation):

# Breakdown:
# - 40 workers on Haiku: 40 × $10/day = $400/day
# - 5 workers on Sonnet: 5 × $40/day = $200/day
# - 5 PMs on Sonnet: 5 × $30/day = $150/day

# Total: ~$750/day = $22,500/month

# With optimizations:
# - Prompt caching (90% reduction): ~$2,250/month
# - Off-peak scheduling: ~$1,800/month
# - Dynamic scaling: ~$1,200/month

# Target cost: $1,200-2,000/month for 50-agent farm
```

### Use Cases

- Enterprise monorepo development (multiple teams)
- Microservices architecture (one agent per service)
- Multi-platform apps (web, iOS, Android, API)
- Large-scale refactoring (parallel module upgrades)
- Comprehensive test generation (agents cover different test types)

## Example 10: Docker + Claude Code (Isolated Agents)

**Community Pattern**, 2025

### Concept

Run Claude Code agents in isolated Docker containers for security and portability.

### Complete Setup

```dockerfile
# Dockerfile
FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    nodejs \
    npm \
    tmux \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install Claude Code
RUN npm install -g @anthropic-ai/claude-code

# Create non-root user
RUN useradd -m -s /bin/bash agent && \
    mkdir -p /workspace && \
    chown agent:agent /workspace

# Copy entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER agent
WORKDIR /workspace

ENTRYPOINT ["/entrypoint.sh"]
```

```bash
#!/bin/bash
# entrypoint.sh

set -e

# Validate environment
if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "Error: ANTHROPIC_API_KEY not set"
    exit 1
fi

# Initialize git if needed
if [ ! -d .git ]; then
    git config --global user.email "agent@example.com"
    git config --global user.name "Claude Agent"
    git init
fi

# Start tmux session with agent
if [ -z "$AGENT_TASK" ]; then
    # Interactive mode
    exec tmux new-session -s agent "claude"
else
    # Autonomous mode
    exec tmux new-session -s agent "claude -p \"$AGENT_TASK\" $AGENT_FLAGS"
fi
```

### Usage

```bash
# Build image
docker build -t claude-agent:latest .

# Run interactive agent
docker run -it --rm \
    -e ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY" \
    -v $(pwd):/workspace \
    claude-agent:latest

# Run autonomous agent
docker run -d \
    --name agent-task-123 \
    -e ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY" \
    -e AGENT_TASK="Build REST API for user management" \
    -e AGENT_FLAGS="--dangerously-skip-permissions" \
    -v $(pwd)/output:/workspace \
    claude-agent:latest

# Attach to running agent
docker exec -it agent-task-123 tmux attach -t agent

# View logs
docker logs -f agent-task-123

# Stop agent
docker stop agent-task-123
```

### Docker Compose (Multi-Agent)

```yaml
# docker-compose.yml
version: '3.8'

services:
  agent-frontend:
    build: .
    container_name: agent-frontend
    environment:
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
      - AGENT_TASK=Build React frontend
      - AGENT_FLAGS=--dangerously-skip-permissions
    volumes:
      - ./frontend:/workspace
    restart: unless-stopped

  agent-backend:
    build: .
    container_name: agent-backend
    environment:
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
      - AGENT_TASK=Build Express backend
      - AGENT_FLAGS=--dangerously-skip-permissions
    volumes:
      - ./backend:/workspace
    restart: unless-stopped

  agent-tests:
    build: .
    container_name: agent-tests
    environment:
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
      - AGENT_TASK=Write comprehensive tests
      - AGENT_FLAGS=--dangerously-skip-permissions
    volumes:
      - ./tests:/workspace
    restart: unless-stopped
    depends_on:
      - agent-frontend
      - agent-backend
```

```bash
# Start all agents
docker-compose up -d

# View status
docker-compose ps

# Attach to specific agent
docker-compose exec agent-frontend tmux attach -t agent

# View all logs
docker-compose logs -f

# Stop all agents
docker-compose down
```

### Benefits

✅ Complete isolation per agent
✅ No dependency conflicts
✅ Easy to scale (spawn more containers)
✅ Portable (run anywhere Docker runs)
✅ Resource limits (CPU, memory)
✅ Easy cleanup (remove container)

## Example 11: Self-Healing Agent System

**Advanced Community Pattern**, 2025

### Concept

Agents that monitor themselves and automatically recover from failures.

```bash
#!/bin/bash
# self-healing-agent.sh

AGENT_NAME=$1
AGENT_TASK=$2
MAX_RETRIES=3
HEALTH_CHECK_INTERVAL=60
LOG_FILE=~/logs/agent-$AGENT_NAME.log

mkdir -p ~/logs

# Health check function
check_health() {
    local session=$1

    # Check if tmux session exists
    if ! tmux has-session -t "$session" 2>/dev/null; then
        echo "UNHEALTHY: Session not found"
        return 1
    fi

    # Check if session is responsive
    if ! tmux list-panes -t "$session" -F "#{pane_active}" | grep -q "1"; then
        echo "UNHEALTHY: Session unresponsive"
        return 1
    fi

    # Check for error patterns in recent output
    local recent_output=$(tmux capture-pane -t "$session" -p | tail -20)
    if echo "$recent_output" | grep -qE "(Error|Exception|FATAL)"; then
        echo "UNHEALTHY: Errors detected"
        return 1
    fi

    echo "HEALTHY"
    return 0
}

# Recovery function
recover_agent() {
    local session=$1
    local task=$2
    local attempt=$3

    echo "[$(date)] Recovery attempt $attempt for $session" >> "$LOG_FILE"

    # Kill existing session if present
    tmux kill-session -t "$session" 2>/dev/null || true

    # Wait a bit
    sleep 5

    # Restart agent
    tmux new-session -d -s "$session" \
        "claude -p '$task' --dangerously-skip-permissions"

    echo "[$(date)] Agent $session restarted" >> "$LOG_FILE"
}

# Main monitoring loop
start_agent() {
    local session="agent-$AGENT_NAME"
    local retry_count=0

    # Start initial agent
    tmux new-session -d -s "$session" \
        "claude -p '$AGENT_TASK' --dangerously-skip-permissions"

    echo "[$(date)] Agent $AGENT_NAME started" >> "$LOG_FILE"

    # Monitor loop
    while true; do
        sleep $HEALTH_CHECK_INTERVAL

        health_status=$(check_health "$session")
        echo "[$(date)] Health check: $health_status" >> "$LOG_FILE"

        if [ $? -ne 0 ]; then
            ((retry_count++))

            if [ $retry_count -le $MAX_RETRIES ]; then
                echo "[$(date)] Agent unhealthy, recovering..." >> "$LOG_FILE"
                recover_agent "$session" "$AGENT_TASK" $retry_count
                sleep 30  # Give it time to stabilize
            else
                echo "[$(date)] Max retries exceeded, sending alert" >> "$LOG_FILE"

                # Send alert (example: webhook)
                curl -X POST "$ALERT_WEBHOOK" \
                    -H "Content-Type: application/json" \
                    -d "{\"text\":\"Agent $AGENT_NAME failed after $MAX_RETRIES retries\"}"

                # Reset retry count and continue trying
                retry_count=0
            fi
        else
            # Reset retry count on successful health check
            retry_count=0
        fi
    done
}

# Start the agent
start_agent
```

### Advanced: Auto-Recovery with Checkpoints

```bash
#!/bin/bash
# self-healing-with-checkpoints.sh

CHECKPOINT_DIR=~/agent-checkpoints
CHECKPOINT_INTERVAL=1800  # 30 minutes

create_checkpoint() {
    local agent_name=$1
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local checkpoint_file="$CHECKPOINT_DIR/$agent_name-$timestamp.tar.gz"

    # Capture agent state
    mkdir -p "$CHECKPOINT_DIR"
    tar -czf "$checkpoint_file" \
        -C ~/agents/$agent_name \
        --exclude='.git' \
        --exclude='node_modules' \
        .

    echo "$checkpoint_file"
}

restore_checkpoint() {
    local agent_name=$1
    local checkpoint_file=$(ls -t $CHECKPOINT_DIR/$agent_name-*.tar.gz | head -1)

    if [ -n "$checkpoint_file" ]; then
        echo "Restoring from checkpoint: $checkpoint_file"
        tar -xzf "$checkpoint_file" -C ~/agents/$agent_name/
        return 0
    else
        echo "No checkpoint found"
        return 1
    fi
}

# Run checkpoint creation in background
while true; do
    create_checkpoint "$AGENT_NAME"
    sleep $CHECKPOINT_INTERVAL
done &

# Run main agent with recovery
# ... (same as above)
```

## Example 12: Cost Tracking and Budget Alerts

**Community Pattern**, 2025

```bash
#!/bin/bash
# cost-tracker.sh

COST_DB=~/.agent-costs.db
DAILY_BUDGET=100  # $100/day
MONTHLY_BUDGET=2000  # $2000/month

# Initialize database
sqlite3 $COST_DB <<'EOF'
CREATE TABLE IF NOT EXISTS api_calls (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    agent_name TEXT,
    model TEXT,
    input_tokens INTEGER,
    output_tokens INTEGER,
    cost_usd REAL
);

CREATE TABLE IF NOT EXISTS budget_alerts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    alert_type TEXT,
    message TEXT
);
EOF

# Log API call
log_api_call() {
    local agent=$1
    local model=$2
    local input_tokens=$3
    local output_tokens=$4

    # Calculate cost based on model
    local cost=0
    case $model in
        "claude-opus-4")
            cost=$(echo "scale=6; ($input_tokens * 0.000015) + ($output_tokens * 0.000075)" | bc)
            ;;
        "claude-sonnet-4")
            cost=$(echo "scale=6; ($input_tokens * 0.000003) + ($output_tokens * 0.000015)" | bc)
            ;;
        "claude-haiku-3-5")
            cost=$(echo "scale=6; ($input_tokens * 0.0000008) + ($output_tokens * 0.000004)" | bc)
            ;;
    esac

    sqlite3 $COST_DB "INSERT INTO api_calls (agent_name, model, input_tokens, output_tokens, cost_usd)
                      VALUES ('$agent', '$model', $input_tokens, $output_tokens, $cost)"
}

# Check budget
check_budget() {
    # Today's spending
    local today_cost=$(sqlite3 $COST_DB \
        "SELECT COALESCE(SUM(cost_usd), 0) FROM api_calls
         WHERE DATE(timestamp) = DATE('now')")

    # Month's spending
    local month_cost=$(sqlite3 $COST_DB \
        "SELECT COALESCE(SUM(cost_usd), 0) FROM api_calls
         WHERE strftime('%Y-%m', timestamp) = strftime('%Y-%m', 'now')")

    echo "Today: \$$today_cost / \$$DAILY_BUDGET"
    echo "Month: \$$month_cost / \$$MONTHLY_BUDGET"

    # Check thresholds
    if (( $(echo "$today_cost > $DAILY_BUDGET * 0.9" | bc -l) )); then
        send_alert "daily" "Approaching daily budget: \$$today_cost / \$$DAILY_BUDGET"
    fi

    if (( $(echo "$month_cost > $MONTHLY_BUDGET * 0.9" | bc -l) )); then
        send_alert "monthly" "Approaching monthly budget: \$$month_cost / \$$MONTHLY_BUDGET"
    fi
}

send_alert() {
    local alert_type=$1
    local message=$2

    sqlite3 $COST_DB "INSERT INTO budget_alerts (alert_type, message) VALUES ('$alert_type', '$message')"

    # Send webhook notification
    curl -X POST "$ALERT_WEBHOOK" \
        -H "Content-Type: application/json" \
        -d "{\"text\":\"💰 Budget Alert: $message\"}"
}

# Generate report
generate_report() {
    echo "╔══════════════════════════════════════════════════╗"
    echo "║         AGENT COST REPORT                        ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo ""

    echo "=== Today's Costs by Agent ==="
    sqlite3 $COST_DB \
        "SELECT agent_name, ROUND(SUM(cost_usd), 2) as cost
         FROM api_calls
         WHERE DATE(timestamp) = DATE('now')
         GROUP BY agent_name
         ORDER BY cost DESC" | \
        awk -F'|' '{printf "  %-20s: $%.2f\n", $1, $2}'

    echo ""
    echo "=== This Month by Model ==="
    sqlite3 $COST_DB \
        "SELECT model, ROUND(SUM(cost_usd), 2) as cost
         FROM api_calls
         WHERE strftime('%Y-%m', timestamp) = strftime('%Y-%m', 'now')
         GROUP BY model
         ORDER BY cost DESC" | \
        awk -F'|' '{printf "  %-20s: $%.2f\n", $1, $2}'

    echo ""
    check_budget
}

# Run continuous monitoring
while true; do
    check_budget
    sleep 300  # Check every 5 minutes
done
```

## Example 13: Automated Backup System

**Production Pattern**, 2025

```bash
#!/bin/bash
# backup-agents.sh

BACKUP_ROOT=~/backups
RETENTION_DAYS=30
S3_BUCKET="s3://my-agent-backups"

backup_agent() {
    local agent_name=$1
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_file="$BACKUP_ROOT/$agent_name-$timestamp.tar.gz"

    echo "[$(date)] Backing up $agent_name..."

    # Create backup
    tar -czf "$backup_file" \
        -C ~/agents/$agent_name \
        --exclude='.git/objects' \
        --exclude='node_modules' \
        --exclude='*.log' \
        .

    # Upload to S3 (if configured)
    if [ -n "$S3_BUCKET" ]; then
        aws s3 cp "$backup_file" "$S3_BUCKET/$agent_name/" \
            && echo "Uploaded to S3"
    fi

    # Cleanup old local backups
    find "$BACKUP_ROOT" -name "$agent_name-*.tar.gz" -mtime +$RETENTION_DAYS -delete

    echo "[$(date)] Backup complete: $backup_file"
}

# Backup all agents
mkdir -p "$BACKUP_ROOT"

for agent_dir in ~/agents/*; do
    if [ -d "$agent_dir" ]; then
        agent_name=$(basename "$agent_dir")
        backup_agent "$agent_name"
    fi
done

# Backup coordination data
tar -czf "$BACKUP_ROOT/coordination-$(date +%Y%m%d-%H%M%S).tar.gz" \
    -C ~ \
    .agent-costs.db \
    agent-farm/coordination/ \
    .claude-squad/

echo "[$(date)] All backups complete"
```

### Add to crontab

```text
# Daily backups at 3 AM
0 3 * * * ~/scripts/backup-agents.sh >> ~/logs/backup.log 2>&1

# Weekly full system backup at 4 AM Sunday
0 4 * * 0 tar -czf ~/backups/full-system-$(date +\%Y\%m\%d).tar.gz \
    ~/agents ~/scripts ~/.claude-squad ~/.config/claude-code
```

## Tool Comparison Matrix

| Feature | Claude Squad | Tmux Orchestrator | Agent Farm | Docker Setup | VibeTunnel |
|---------|--------------|-------------------|------------|--------------|------------|
| **Max Agents** | 5-10 | 10-20 | 50+ | Unlimited | 10-20 |
| **Git Integration** | ✅ Worktrees | ⚠️ Manual | ✅ Advanced | ✅ Per container | ❌ |
| **TUI** | ✅ Full | ❌ | ✅ Dashboard | ❌ | ✅ Web |
| **Coordination** | JSON files | Task files | SQLite DB | None built-in | None |
| **Resource Mgmt** | ⚠️ Basic | ❌ | ✅ Full locks | ✅ Docker limits | ❌ |
| **Cost Tracking** | ❌ | ❌ | ✅ Built-in | ⚠️ Manual | ❌ |
| **Auto-recovery** | ❌ | ⚠️ Basic | ✅ Advanced | ✅ Restart policy | ❌ |
| **Mobile Access** | Via tmux | Via tmux | Via tmux | Via Docker exec | ✅ Web browser |
| **Setup Complexity** | Low | Medium | High | Medium | Low |
| **Learning Curve** | Easy | Medium | Steep | Medium | Easy |
| **Best For** | Small teams | Solo dev | Enterprise | Isolation needed | Quick demos |
| **Cost (infra)** | $5-10/mo | $10-20/mo | $50-100/mo | $10-30/mo | $5-10/mo |
| **Maintenance** | Low | Medium | High | Low | Low |

### Recommendation Matrix

| Use Case | Recommended Tool | Alternative |
|----------|-----------------|-------------|
| Solo developer, 1-3 projects | Claude Squad | tmux + Mosh |
| Team, 5-10 projects | Tmux Orchestrator | Claude Squad |
| Enterprise, 20+ projects | Agent Farm | Docker Compose |
| High security requirements | Docker Setup | Agent Farm |
| Demo / Mobile access | VibeTunnel | Claude Squad |
| Cost-constrained | Claude Squad | Raw tmux |
| Maximum parallelism | Agent Farm | Docker Swarm |
| Learning / Experimentation | Claude Squad | VibeTunnel |

## Key Takeaways from Community Examples

### What Works Well

1. **tmux + Mosh + Tailscale**: Universal combination for persistence and remote access
2. **Prompt Caching**: Essential for cost control in continuous agents
3. **Model Selection**: Haiku for routine, Sonnet for standard, Opus for critical
4. **Checkpointing**: Git commits or Claude's checkpoint feature
5. **Monitoring**: Log aggregation, alert on anomalies

### Common Pitfalls

1. **No Loop Detection**: Agents get stuck repeating failed actions
2. **Unconstrained Costs**: Opus 24/7 with no caching = $$$
3. **No Rollback Plan**: Agent breaks something, no easy recovery
4. **Public Exposure**: SSH exposed to internet without fail2ban
5. **Shared Credentials**: Agent has access to production DB passwords

### Success Factors

1. **Well-Defined Scope**: Agents work best with clear, specific goals
2. **Human Oversight**: Regular check-ins, even for "autonomous" agents
3. **Progressive Enhancement**: Start simple, add autonomy gradually
4. **Cost Monitoring**: Track API usage daily
5. **Security First**: Isolation, restricted permissions, monitoring

## Next Steps

Now that you've reviewed working examples:
1. Review the knowledge base overview → See `README.md`
2. Pick a starting point based on your use case
3. Start with basic setup, iterate toward full automation
4. Join the community, share your learnings!

## Community Resources

- **X/Twitter**: Follow @levelsio, @ericzakariasson for latest updates
- **GitHub**: Search for "tmux claude", "claude-squad", "autonomous agent"
- **Discord/Slack**: Various AI coding communities
- **Blog Posts**: Many 2025 writeups on mobile coding, continuous agents

## Contributing

Found a great setup not listed here? Contributions welcome!
