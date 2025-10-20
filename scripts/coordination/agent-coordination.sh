#!/bin/bash

###############################################################################
# Multi-Agent Coordination Library
#
# Provides coordination functions for managing multiple parallel Claude Code
# agents to prevent conflicts and enable collaboration.
#
# Usage:
#   source scripts/coordination/agent-coordination.sh
#   init_coordination
#   claim_work "agent-1" "src/file.ts" "Fix bug"
#
# Features:
#   - File-level locking to prevent conflicts
#   - Task queue management
#   - Work tracking (active, completed, planned)
#   - Stale agent detection
#   - Statistics and monitoring
#
# Based on: Agent Farm coordination protocol
# See: 02-tmux-setup.md#multi-agent-coordination-protocol
###############################################################################

# Configuration
COORD_DIR="${COORD_DIR:-$HOME/agents/coordination}"
LOCK_TIMEOUT="${LOCK_TIMEOUT:-1800}"  # 30 minutes in seconds

###############################################################################
# Initialization
###############################################################################

init_coordination() {
    echo "[COORD] Initializing coordination system..."

    # Create directory structure
    mkdir -p "$COORD_DIR/agent-locks"

    # Initialize JSON files if they don't exist
    [ ! -f "$COORD_DIR/active-work.json" ] && echo "[]" > "$COORD_DIR/active-work.json"
    [ ! -f "$COORD_DIR/completed-work.json" ] && echo "[]" > "$COORD_DIR/completed-work.json"
    [ ! -f "$COORD_DIR/planned-work.json" ] && echo "[]" > "$COORD_DIR/planned-work.json"

    echo "[COORD] Coordination system initialized at: $COORD_DIR"
}

###############################################################################
# Work Claiming
###############################################################################

claim_work() {
    local agent=$1
    local file=$2
    local task=$3

    if [ -z "$agent" ] || [ -z "$file" ] || [ -z "$task" ]; then
        echo "[ERROR] claim_work requires: agent file task"
        return 1
    fi

    # Check if file is already claimed
    if jq -e ".[] | select(.file == \"$file\")" "$COORD_DIR/active-work.json" > /dev/null 2>&1; then
        local current_agent=$(jq -r ".[] | select(.file == \"$file\") | .agent" "$COORD_DIR/active-work.json")
        echo "[ERROR] File $file already claimed by $current_agent"
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

    echo "[COORD] Agent $agent claimed: $file"
    return 0
}

###############################################################################
# Work Completion
###############################################################################

complete_work() {
    local agent=$1
    local file=$2
    local commit_hash=${3:-"none"}

    if [ -z "$agent" ] || [ -z "$file" ]; then
        echo "[ERROR] complete_work requires: agent file [commit_hash]"
        return 1
    fi

    # Get the work entry
    local work_entry=$(jq ".[] | select(.agent == \"$agent\" and .file == \"$file\")" "$COORD_DIR/active-work.json")

    if [ -z "$work_entry" ]; then
        echo "[ERROR] No active work found for agent $agent on file $file"
        return 1
    fi

    # Add completion info
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

    echo "[COORD] Agent $agent completed: $file (commit: $commit_hash)"
    return 0
}

###############################################################################
# Work Release (without completion)
###############################################################################

release_work() {
    local agent=$1
    local file=$2
    local reason=${3:-"cancelled"}

    if [ -z "$agent" ] || [ -z "$file" ]; then
        echo "[ERROR] release_work requires: agent file [reason]"
        return 1
    fi

    # Remove from active work
    jq "map(select(.agent != \"$agent\" or .file != \"$file\"))" \
        "$COORD_DIR/active-work.json" > "$COORD_DIR/active-work.json.tmp"
    mv "$COORD_DIR/active-work.json.tmp" "$COORD_DIR/active-work.json"

    # Remove lock
    rm -f "$COORD_DIR/agent-locks/$agent.lock"

    echo "[COORD] Agent $agent released: $file (reason: $reason)"
    return 0
}

###############################################################################
# Task Queue Management
###############################################################################

add_task() {
    local file=$1
    local task=$2
    local priority=${3:-"medium"}

    if [ -z "$file" ] || [ -z "$task" ]; then
        echo "[ERROR] add_task requires: file task [priority]"
        return 1
    fi

    # Generate task ID
    local task_id="task-$(date +%s)-$RANDOM"

    # Create task entry
    local entry=$(jq -n \
        --arg id "$task_id" \
        --arg file "$file" \
        --arg task "$task" \
        --arg priority "$priority" \
        '{id: $id, file: $file, task: $task, priority: $priority, assigned: null}')

    jq ". += [$entry]" "$COORD_DIR/planned-work.json" > "$COORD_DIR/planned-work.json.tmp"
    mv "$COORD_DIR/planned-work.json.tmp" "$COORD_DIR/planned-work.json"

    echo "[COORD] Task added: $task_id - $file"
    echo "$task_id"
}

get_next_task() {
    local agent=$1

    if [ -z "$agent" ]; then
        echo "[ERROR] get_next_task requires: agent"
        return 1
    fi

    # Priority order: high > medium > low
    local task=$(jq -r '
        .[] |
        select(.assigned == null) |
        . + {priority_num: (if .priority == "high" then 3 elif .priority == "medium" then 2 else 1 end)} |
        .
    ' "$COORD_DIR/planned-work.json" | jq -s 'sort_by(-.priority_num) | .[0] | @json')

    if [ "$task" = "null" ] || [ -z "$task" ]; then
        echo "[COORD] No available tasks"
        return 1
    fi

    local task_id=$(echo "$task" | jq -r '.id')
    local file=$(echo "$task" | jq -r '.file')
    local description=$(echo "$task" | jq -r '.task')

    # Check if file is available
    if jq -e ".[] | select(.file == \"$file\")" "$COORD_DIR/active-work.json" > /dev/null 2>&1; then
        echo "[COORD] Task available but file is locked: $file"
        return 1
    fi

    # Mark as assigned in planned work
    jq "map(if .id == \"$task_id\" then .assigned = \"$agent\" else . end)" \
        "$COORD_DIR/planned-work.json" > "$COORD_DIR/planned-work.json.tmp"
    mv "$COORD_DIR/planned-work.json.tmp" "$COORD_DIR/planned-work.json"

    # Claim the work
    if claim_work "$agent" "$file" "$description"; then
        echo "$task"
        return 0
    else
        # Unclaim if claim failed
        jq "map(if .id == \"$task_id\" then .assigned = null else . end)" \
            "$COORD_DIR/planned-work.json" > "$COORD_DIR/planned-work.json.tmp"
        mv "$COORD_DIR/planned-work.json.tmp" "$COORD_DIR/planned-work.json"
        return 1
    fi
}

###############################################################################
# Status Checking
###############################################################################

check_active_work() {
    echo "=== Active Work ==="
    if [ "$(jq 'length' "$COORD_DIR/active-work.json")" -eq 0 ]; then
        echo "No active work"
        return
    fi

    jq -r '.[] | "\(.agent): \(.file) - \(.task) (started: \(.started))"' "$COORD_DIR/active-work.json"
}

check_completed_work() {
    local count=${1:-10}
    echo "=== Recently Completed Work (last $count) ==="
    jq -r ".[-$count:] | .[] | \"\(.agent): \(.file) - \(.task) (commit: \(.commit))\"" "$COORD_DIR/completed-work.json"
}

check_planned_work() {
    echo "=== Planned Work ==="
    if [ "$(jq 'length' "$COORD_DIR/planned-work.json")" -eq 0 ]; then
        echo "No planned work"
        return
    fi

    jq -r '.[] | "[\(.priority)] \(.file) - \(.task) (assigned: \(.assigned // "none"))"' "$COORD_DIR/planned-work.json"
}

###############################################################################
# Health Checks
###############################################################################

check_stale_agents() {
    local timeout=${1:-$LOCK_TIMEOUT}
    local now=$(date +%s)
    local found_stale=false

    echo "=== Stale Agent Check (timeout: ${timeout}s) ==="

    jq -r '.[] | "\(.agent)|\(.file)|\(.started)"' "$COORD_DIR/active-work.json" | while IFS='|' read -r agent file started; do
        # Parse ISO 8601 timestamp
        local start_time=$(date -d "$started" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%SZ" "$started" +%s 2>/dev/null)

        if [ -n "$start_time" ]; then
            local elapsed=$((now - start_time))

            if [ $elapsed -gt $timeout ]; then
                echo "⚠️  Agent $agent: $file (${elapsed}s elapsed)"
                found_stale=true
            fi
        fi
    done

    if [ "$found_stale" = false ]; then
        echo "No stale agents"
    fi
}

cleanup_stale_agents() {
    local timeout=${1:-$LOCK_TIMEOUT}
    local now=$(date +%s)

    echo "[COORD] Cleaning up stale agents..."

    jq -r '.[] | "\(.agent)|\(.file)|\(.started)"' "$COORD_DIR/active-work.json" | while IFS='|' read -r agent file started; do
        local start_time=$(date -d "$started" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%SZ" "$started" +%s 2>/dev/null)

        if [ -n "$start_time" ]; then
            local elapsed=$((now - start_time))

            if [ $elapsed -gt $timeout ]; then
                echo "[COORD] Releasing stale work: $agent - $file"
                release_work "$agent" "$file" "timeout"
            fi
        fi
    done
}

###############################################################################
# Statistics
###############################################################################

show_stats() {
    local total_active=$(jq 'length' "$COORD_DIR/active-work.json")
    local total_completed=$(jq 'length' "$COORD_DIR/completed-work.json")
    local total_planned=$(jq 'length' "$COORD_DIR/planned-work.json")

    echo "╔════════════════════════════════════════╗"
    echo "║  Multi-Agent Coordination Statistics  ║"
    echo "╠════════════════════════════════════════╣"
    echo "║                                        ║"
    echo "║  Active agents:     $total_active"
    echo "║  Completed tasks:   $total_completed"
    echo "║  Planned tasks:     $total_planned"
    echo "║                                        ║"
    echo "╚════════════════════════════════════════╝"
    echo ""

    # Show agent distribution
    if [ $total_active -gt 0 ]; then
        echo "Active agents:"
        jq -r '.[] | .agent' "$COORD_DIR/active-work.json" | sort | uniq -c | awk '{print "  "$2": "$1" tasks"}'
        echo ""
    fi

    # Show priority distribution of planned work
    if [ $total_planned -gt 0 ]; then
        echo "Planned work by priority:"
        jq -r '.[] | .priority' "$COORD_DIR/planned-work.json" | sort | uniq -c | awk '{print "  "$2": "$1" tasks"}'
        echo ""
    fi
}

###############################################################################
# Utility Functions
###############################################################################

# Get work by agent
get_agent_work() {
    local agent=$1

    if [ -z "$agent" ]; then
        echo "[ERROR] get_agent_work requires: agent"
        return 1
    fi

    jq ".[] | select(.agent == \"$agent\")" "$COORD_DIR/active-work.json"
}

# Check if file is locked
is_file_locked() {
    local file=$1

    if [ -z "$file" ]; then
        echo "[ERROR] is_file_locked requires: file"
        return 1
    fi

    if jq -e ".[] | select(.file == \"$file\")" "$COORD_DIR/active-work.json" > /dev/null 2>&1; then
        return 0  # File is locked
    else
        return 1  # File is not locked
    fi
}

# List all locks
list_locks() {
    echo "=== Active Locks ==="
    ls -lh "$COORD_DIR/agent-locks/" 2>/dev/null || echo "No locks"
}

###############################################################################
# Export functions
###############################################################################

# Make functions available to scripts that source this file
export -f init_coordination
export -f claim_work
export -f complete_work
export -f release_work
export -f add_task
export -f get_next_task
export -f check_active_work
export -f check_completed_work
export -f check_planned_work
export -f check_stale_agents
export -f cleanup_stale_agents
export -f show_stats
export -f get_agent_work
export -f is_file_locked
export -f list_locks
