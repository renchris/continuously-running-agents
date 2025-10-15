# TMUX Setup for Continuous Agent Operation

## Overview

Tmux (terminal multiplexer) is essential for running Claude Code agents continuously. It allows sessions to persist even when you disconnect, enables multiple parallel agents, and provides the foundation for autonomous agent orchestration.

## Why TMUX for AI Agents?

### Key Benefits

1. **Session Persistence**: Agents keep running even if SSH disconnects
2. **Parallel Execution**: Run multiple agents simultaneously in different panes/windows
3. **Observability**: Monitor multiple agent sessions at once
4. **Recovery**: Reattach to running sessions from anywhere
5. **Scripting**: Automate agent startup and orchestration

### Community Adoption

- **Brian Sunter**: "Tmux keeps CC running if you disconnect"
- **camsoft2000**: "Terminal multiplexing is game-changing when using agents like Claude Code"
- **Multiple projects**: Tmux Orchestrator, Claude Squad, tmux-mcp

## Basic TMUX Setup

### Installation

```bash
# Ubuntu/Debian
sudo apt install tmux

# macOS
brew install tmux

# Verify installation
tmux -V
```

### Essential TMUX Commands

```bash
# Start a new named session
tmux new -s agent-session

# List all sessions
tmux ls

# Attach to an existing session
tmux attach -t agent-session

# Detach from current session (inside tmux)
Ctrl+b, then d

# Kill a session
tmux kill-session -t agent-session

# Create new window
Ctrl+b, then c

# Switch between windows
Ctrl+b, then 0-9 (window number)
Ctrl+b, then n (next)
Ctrl+b, then p (previous)

# Split pane horizontally
Ctrl+b, then "

# Split pane vertically
Ctrl+b, then %

# Navigate between panes
Ctrl+b, then arrow keys
```

### Recommended TMUX Configuration

Create/edit `~/.tmux.conf`:

```tmux
# Enable mouse support (easier navigation)
set -g mouse on

# Increase scrollback buffer
set-option -g history-limit 10000

# Start window numbering at 1
set -g base-index 1
set -g pane-base-index 1

# Renumber windows when one is closed
set -g renumber-windows on

# Faster command sequences
set -s escape-time 0

# Enable activity alerts
setw -g monitor-activity on
set -g visual-activity on

# Better status bar
set -g status-position bottom
set -g status-bg colour234
set -g status-fg colour137
set -g status-left ''
set -g status-right '#[fg=colour233,bg=colour241,bold] %d/%m #[fg=colour233,bg=colour245,bold] %H:%M:%S '
set -g status-right-length 50
set -g status-left-length 20

# Reload config easily
bind r source-file ~/.tmux.conf \; display-message "Config reloaded!"
```

Apply configuration:
```bash
tmux source-file ~/.tmux.conf
```

## Running Claude Code in TMUX

### Basic Session

```bash
# Start a new tmux session for Claude
tmux new -s claude-main

# Inside tmux, start Claude Code
claude

# Work with Claude as normal
# When done, detach: Ctrl+b, d
# Session keeps running in background

# Later, reattach from anywhere
tmux attach -t claude-main
```

### Persistent Agent Session

Create a startup script `~/start-agent.sh`:

```bash
#!/bin/bash

SESSION_NAME="claude-agent"
PROJECT_DIR="/home/your-username/your-project"

# Check if session exists
tmux has-session -t $SESSION_NAME 2>/dev/null

if [ $? != 0 ]; then
    # Create new session
    tmux new-session -d -s $SESSION_NAME -c $PROJECT_DIR

    # Set up window 1: Main agent
    tmux rename-window -t $SESSION_NAME:1 'main'
    tmux send-keys -t $SESSION_NAME:1 'claude' C-m

    # Create window 2: Logs/monitoring
    tmux new-window -t $SESSION_NAME:2 -n 'logs'
    tmux send-keys -t $SESSION_NAME:2 'tail -f ~/agent-logs/*.log' C-m

    # Create window 3: System monitoring
    tmux new-window -t $SESSION_NAME:3 -n 'system'
    tmux send-keys -t $SESSION_NAME:3 'htop' C-m

    # Focus on main window
    tmux select-window -t $SESSION_NAME:1

    echo "Agent session created. Attach with: tmux attach -t $SESSION_NAME"
else
    echo "Agent session already running. Attach with: tmux attach -t $SESSION_NAME"
fi
```

Make it executable:
```bash
chmod +x ~/start-agent.sh
```

## TMUX MCP Integration

### tmux-mcp Server

The tmux-mcp (Model Context Protocol) server allows Claude to interact with tmux sessions programmatically.

#### Installation

```bash
# Clone the repository
git clone https://github.com/nickgnd/tmux-mcp.git
cd tmux-mcp

# Install dependencies
npm install

# Configure in Claude Desktop settings
# Add to MCP servers configuration
```

#### Capabilities

- List and search tmux sessions
- View and navigate windows and panes
- Capture terminal content from any pane
- Execute commands in tmux panes
- Create new sessions and windows

#### Use Cases

- AI agent monitoring other agent sessions
- Orchestration agent managing worker agents
- Debugging agent behavior in real-time
- Automated testing with terminal output validation

## Advanced: Multi-Agent Orchestration

### Claude Squad Setup

Claude Squad manages multiple AI agents (Claude Code, Aider, Codex) in separate tmux sessions.

```bash
# Install Claude Squad
npm install -g claude-squad

# Start with multiple agents
claude-squad start

# Features:
# - Separate tmux session per agent
# - Git worktrees for isolated branches
# - Background task execution
# - Auto-accept mode (yolo mode)
```

### Tmux Orchestrator

The Tmux Orchestrator enables autonomous agent operation with self-scheduling.

#### Installation

```bash
# Clone repository
git clone https://github.com/Jedward23/Tmux-Orchestrator.git
cd Tmux-Orchestrator

# Follow setup instructions
# Modify config files for your directory structure
```

#### Features

- **Self-Trigger**: Agents schedule their own check-ins
- **Coordination**: Project managers assign tasks across multiple codebases
- **Persistence**: Work continues even when laptop is closed
- **Scaling**: Run multiple teams on different projects

#### Configuration

Key requirements:
1. Enable `--dangerously-skip-permissions` for autonomous execution
2. Set up spec folder for project documentation
3. Configure task manager folder for progress tracking
4. Set 15-minute automated check-in intervals

## Parallel Agent Execution

### Using Git Worktrees + TMUX

Based on the worksfornow gist, here's a pattern for parallel task execution:

```bash
# Script: parallel-agents.sh
#!/bin/bash

# List of task IDs
TASK_IDS="$@"

for TASK_ID in $TASK_IDS; do
    # Get task details
    TASK_DETAILS=$(task-master get $TASK_ID)

    # Skip if already done
    STATUS=$(echo $TASK_DETAILS | jq -r '.status')
    if [ "$STATUS" == "done" ]; then
        echo "Task $TASK_ID already completed"
        continue
    fi

    # Create feature branch worktree
    BRANCH="task-${TASK_ID}"
    git worktree add "../worktrees/$BRANCH" -b $BRANCH

    # Update task status to in-progress
    task-master update $TASK_ID --status in-progress

    # Launch tmux session with Claude agent
    tmux new-session -d -s "agent-$TASK_ID" -c "../worktrees/$BRANCH"
    tmux send-keys -t "agent-$TASK_ID" "claude -p \"$(cat <<EOF
Task: $TASK_DETAILS

1. Accomplish this task
2. When ready, request approval before committing
3. Commit with descriptive message
4. Update task status to done
EOF
)\"" C-m

    echo "Started agent for task $TASK_ID in tmux session agent-$TASK_ID"
done

# Usage: ./parallel-agents.sh 1 3 5
# Launches agents for tasks 1, 3, and 5 in parallel
```

### Monitoring Multiple Agents

```bash
# Create a monitoring dashboard
#!/bin/bash
# monitor-agents.sh

SESSION="agent-monitor"

tmux new-session -d -s $SESSION

# Split into 4 panes
tmux split-window -h -t $SESSION
tmux split-window -v -t $SESSION:1.1
tmux split-window -v -t $SESSION:1.2

# Attach to different agent sessions
tmux send-keys -t $SESSION:1.1 'tmux attach -t agent-1' C-m
tmux send-keys -t $SESSION:1.2 'tmux attach -t agent-2' C-m
tmux send-keys -t $SESSION:1.3 'tmux attach -t agent-3' C-m
tmux send-keys -t $SESSION:1.4 'tmux attach -t agent-4' C-m

tmux attach -t $SESSION
```

## TMUX with Mosh for Mobile

Mosh works seamlessly with tmux for mobile access:

```bash
# On mobile (using Blink or Termius):
mosh user@server

# Once connected, attach to tmux session
tmux attach -t claude-agent

# Benefits:
# - Survives network changes
# - Instant responsiveness
# - Background-safe (can close app)
# - Tmux persists even if mosh disconnects
```

## Automation and Scheduling

### Auto-start on Server Boot

Create systemd service `/etc/systemd/system/claude-agent.service`:

```ini
[Unit]
Description=Claude Agent in TMUX
After=network.target

[Service]
Type=forking
User=claude-agent
WorkingDirectory=/home/claude-agent
ExecStart=/usr/bin/tmux new-session -d -s claude-agent 'claude'
ExecStop=/usr/bin/tmux kill-session -t claude-agent
Restart=on-failure
RestartSec=10s

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl daemon-reload
sudo systemctl enable claude-agent
sudo systemctl start claude-agent
```

### Scheduled Check-ins

Using cron for periodic agent tasks:

```bash
# Edit crontab
crontab -e

# Add scheduled agent task (every 15 minutes)
*/15 * * * * tmux send-keys -t claude-agent 'continue with next task' C-m
```

## Best Practices

### Session Naming

```bash
# Use descriptive names
tmux new -s agent-frontend
tmux new -s agent-backend
tmux new -s agent-testing
tmux new -s monitor-dashboard
```

### Window Organization

```bash
# Window 0: Main agent
# Window 1: Logs
# Window 2: System monitoring
# Window 3: Git operations
# Window 4: Database/API testing
```

### Pane Layouts

```bash
# Horizontal split for agent + logs
tmux split-window -h

# Vertical split for multiple agents
tmux split-window -v

# Even distribution
tmux select-layout even-horizontal
tmux select-layout tiled
```

### Session Cleanup

```bash
# List all sessions
tmux ls

# Kill inactive sessions
tmux kill-session -t old-session

# Kill all sessions except current
tmux kill-session -a
```

## Troubleshooting

### Session Not Persisting

```bash
# Check if tmux server is running
ps aux | grep tmux

# Ensure session is detached, not killed
# Use: Ctrl+b, d (not Ctrl+c or exit)
```

### Can't Reattach

```bash
# List sessions
tmux ls

# Force detach if session is "attached" elsewhere
tmux attach -d -t session-name
```

### High Memory Usage

```bash
# Reduce scrollback buffer
tmux set-option -g history-limit 5000

# Kill unused sessions
tmux kill-session -t unused-session
```

### Tmux Not Starting

```bash
# Check for corrupted socket
rm -rf /tmp/tmux-*

# Start new session
tmux new -s test
```

## Multi-Agent Coordination Protocol

For systems running 20+ parallel agents (like Agent Farm), a coordination protocol prevents conflicts and enables collaboration.

### Directory Structure

```
/coordination/
├── active-work.json       # What each agent is currently working on
├── completed-work.json    # Historical record of finished tasks
├── agent-locks/          # File-level locks to prevent conflicts
│   ├── agent-1.lock
│   ├── agent-2.lock
│   └── agent-N.lock
└── planned-work.json     # Upcoming tasks queue
```

### JSON Schema

**active-work.json**:
```json
[
  {
    "agent": "agent-1",
    "file": "src/auth.ts",
    "task": "Fix authentication bug",
    "started": "2025-10-15T10:30:00Z",
    "pid": 12345
  },
  {
    "agent": "agent-2",
    "file": "src/api.ts",
    "task": "Add rate limiting",
    "started": "2025-10-15T10:35:00Z",
    "pid": 12346
  }
]
```

**completed-work.json**:
```json
[
  {
    "agent": "agent-1",
    "file": "src/utils.ts",
    "task": "Refactor helper functions",
    "started": "2025-10-15T09:00:00Z",
    "completed": "2025-10-15T09:45:00Z",
    "commit": "abc123"
  }
]
```

**planned-work.json**:
```json
[
  {
    "id": "task-001",
    "file": "src/database.ts",
    "task": "Optimize queries",
    "priority": "high",
    "assigned": null
  },
  {
    "id": "task-002",
    "file": "tests/integration.test.ts",
    "task": "Add integration tests",
    "priority": "medium",
    "assigned": null
  }
]
```

### Coordination Functions

Create `~/scripts/agent-coordination.sh`:

```bash
#!/bin/bash
COORD_DIR="/coordination"

# Initialize coordination directory
init_coordination() {
    mkdir -p "$COORD_DIR/agent-locks"
    echo "[]" > "$COORD_DIR/active-work.json"
    echo "[]" > "$COORD_DIR/completed-work.json"
    echo "[]" > "$COORD_DIR/planned-work.json"
}

# Check what's currently being worked on
check_active_work() {
    jq -r '.[] | "\(.agent): \(.file) - \(.task)"' "$COORD_DIR/active-work.json"
}

# Claim a file for work (returns 0 if successful, 1 if already claimed)
claim_work() {
    local agent=$1
    local file=$2
    local task=$3

    # Check if anyone else is working on it
    if jq -e ".[] | select(.file == \"$file\")" "$COORD_DIR/active-work.json" > /dev/null 2>&1; then
        echo "File $file already claimed by another agent"
        return 1
    fi

    # Create lock file
    touch "$COORD_DIR/agent-locks/$agent.lock"

    # Add to active work
    local entry=$(jq -n \
        --arg agent "$agent" \
        --arg file "$file" \
        --arg task "$task" \
        --arg started "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --arg pid "$$" \
        '{agent: $agent, file: $file, task: $task, started: $started, pid: $pid}')

    jq ". += [$entry]" "$COORD_DIR/active-work.json" > "$COORD_DIR/active-work.json.tmp"
    mv "$COORD_DIR/active-work.json.tmp" "$COORD_DIR/active-work.json"

    echo "Agent $agent claimed $file"
    return 0
}

# Mark work as complete
complete_work() {
    local agent=$1
    local file=$2
    local commit_hash=$3

    # Get the work entry
    local work_entry=$(jq ".[] | select(.agent == \"$agent\" and .file == \"$file\")" "$COORD_DIR/active-work.json")

    if [ -z "$work_entry" ]; then
        echo "No active work found for agent $agent on file $file"
        return 1
    fi

    # Add completion timestamp and commit hash
    local completed_entry=$(echo "$work_entry" | jq \
        --arg completed "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --arg commit "$commit_hash" \
        '. + {completed: $completed, commit: $commit}')

    # Move to completed work
    jq ". += [$completed_entry]" "$COORD_DIR/completed-work.json" > "$COORD_DIR/completed-work.json.tmp"
    mv "$COORD_DIR/completed-work.json.tmp" "$COORD_DIR/completed-work.json"

    # Remove from active work
    jq "map(select(.agent != \"$agent\" or .file != \"$file\"))" \
        "$COORD_DIR/active-work.json" > "$COORD_DIR/active-work.json.tmp"
    mv "$COORD_DIR/active-work.json.tmp" "$COORD_DIR/active-work.json"

    # Remove lock
    rm -f "$COORD_DIR/agent-locks/$agent.lock"

    echo "Agent $agent completed work on $file (commit: $commit_hash)"
    return 0
}

# Get next available task from planned work
get_next_task() {
    local agent=$1

    # Get highest priority unassigned task
    local task=$(jq -r '.[] | select(.assigned == null) | . | @json' "$COORD_DIR/planned-work.json" | head -n 1)

    if [ -z "$task" ]; then
        echo "No available tasks"
        return 1
    fi

    local task_id=$(echo "$task" | jq -r '.id')
    local file=$(echo "$task" | jq -r '.file')
    local description=$(echo "$task" | jq -r '.task')

    # Mark as assigned
    jq "map(if .id == \"$task_id\" then .assigned = \"$agent\" else . end)" \
        "$COORD_DIR/planned-work.json" > "$COORD_DIR/planned-work.json.tmp"
    mv "$COORD_DIR/planned-work.json.tmp" "$COORD_DIR/planned-work.json"

    # Claim the work
    claim_work "$agent" "$file" "$description"

    echo "$task"
}

# Check for stale agents (not updated in > 30 minutes)
check_stale_agents() {
    local now=$(date +%s)

    jq -r '.[] | "\(.agent)|\(.started)"' "$COORD_DIR/active-work.json" | while IFS='|' read -r agent started; do
        local start_time=$(date -d "$started" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%SZ" "$started" +%s)
        local elapsed=$((now - start_time))

        if [ $elapsed -gt 1800 ]; then  # 30 minutes
            echo "WARNING: Agent $agent has been working for $((elapsed / 60)) minutes"
        fi
    done
}

# Show agent statistics
show_stats() {
    local total_active=$(jq 'length' "$COORD_DIR/active-work.json")
    local total_completed=$(jq 'length' "$COORD_DIR/completed-work.json")
    local total_planned=$(jq 'length' "$COORD_DIR/planned-work.json")

    echo "=== Agent Coordination Statistics ==="
    echo "Active agents: $total_active"
    echo "Completed tasks: $total_completed"
    echo "Planned tasks: $total_planned"
    echo ""

    echo "Currently active:"
    check_active_work
}
```

### Using Coordination in Agent Scripts

```bash
#!/bin/bash
# coordinated-agent.sh

AGENT_ID="agent-$RANDOM"
source ~/scripts/agent-coordination.sh

# Initialize if needed
if [ ! -d "$COORD_DIR" ]; then
    init_coordination
fi

while true; do
    # Get next available task
    TASK=$(get_next_task "$AGENT_ID")

    if [ $? -ne 0 ]; then
        echo "No tasks available, waiting..."
        sleep 60
        continue
    fi

    FILE=$(echo "$TASK" | jq -r '.file')
    DESCRIPTION=$(echo "$TASK" | jq -r '.task')

    echo "Agent $AGENT_ID working on: $FILE - $DESCRIPTION"

    # Execute task with Claude
    cd /workspace
    claude -p "Task: $DESCRIPTION
File: $FILE

Complete this task and commit your changes." --dangerously-skip-permissions

    # Get commit hash
    COMMIT=$(git log -1 --format=%H)

    # Mark as complete
    complete_work "$AGENT_ID" "$FILE" "$COMMIT"

    # Brief pause before next task
    sleep 10
done
```

### Monitoring Dashboard

Create a live dashboard to monitor all agents:

```bash
#!/bin/bash
# agent-dashboard.sh

source ~/scripts/agent-coordination.sh

while true; do
    clear
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║          Multi-Agent Coordination Dashboard                   ║"
    echo "╠════════════════════════════════════════════════════════════════╣"

    show_stats

    echo ""
    echo "╠════════════════════════════════════════════════════════════════╣"
    echo "║ Stale Agent Check                                              ║"
    echo "╠════════════════════════════════════════════════════════════════╣"
    check_stale_agents

    echo ""
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo "Refreshing in 10 seconds... (Ctrl+C to exit)"

    sleep 10
done
```

### Integration with TMUX

Launch coordinated agents in tmux:

```bash
#!/bin/bash
# launch-agent-team.sh

NUM_AGENTS=${1:-5}  # Default to 5 agents

for i in $(seq 1 $NUM_AGENTS); do
    AGENT_ID="agent-$i"

    tmux new-session -d -s "$AGENT_ID" \
        "bash ~/scripts/coordinated-agent.sh"

    echo "Started $AGENT_ID in tmux session"
done

# Launch dashboard in separate session
tmux new-session -d -s "agent-dashboard" \
    "bash ~/scripts/agent-dashboard.sh"

echo ""
echo "Started $NUM_AGENTS agents"
echo "View dashboard: tmux attach -t agent-dashboard"
echo "View specific agent: tmux attach -t agent-1"
```

### Benefits of Coordination Protocol

1. **Conflict Prevention**: No two agents work on same file simultaneously
2. **Progress Tracking**: Real-time visibility into what each agent is doing
3. **Task Distribution**: Automatic fair distribution of work
4. **Recovery**: Can detect and recover from stale agents
5. **Scalability**: Proven to work with 50+ parallel agents
6. **Historical Record**: Complete audit trail of all work

### Best Practices for Coordinated Agents

1. **Lock Timeouts**: Implement automatic lock release after timeout
2. **Heartbeats**: Agents should update their timestamp periodically
3. **Priority Queues**: Use priority field in planned-work.json
4. **Dead Letter Queue**: Move repeatedly failed tasks to separate queue
5. **Monitoring**: Always run dashboard to catch issues early

## Resources and References

- **tmux-mcp**: https://github.com/nickgnd/tmux-mcp
- **Claude Squad**: https://github.com/smtg-ai/claude-squad
- **Tmux Orchestrator**: https://github.com/Jedward23/Tmux-Orchestrator
- **Agent Farm**: https://github.com/Dicklesworthstone/claude_code_agent_farm (coordination protocol source)
- **Community setup**: worksfornow gist on parallel agents
- **Mobile setup guides**: Multiple from 2025 community

## Next Steps

1. Set up remote access with Tailscale/Mosh → See `03-remote-access.md`
2. Configure Claude for autonomous operation → See `04-claude-configuration.md`
3. Review community examples → See `07-examples.md`
