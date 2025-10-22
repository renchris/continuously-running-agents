#!/bin/bash
###############################################################################
# Agent Completion Watcher
#
# Continuously monitors running Claude Code agents and detects completion.
# Writes status to JSON files that persist across conversation boundaries.
#
# Usage:
#   tmux new -d -s agent-watcher "bash ~/scripts/monitoring/agent-completion-watcher.sh"
#
# Features:
#   - Detects completion via multiple signals (exit, files, PRs, logs)
#   - Tracks resource usage and duration
#   - Writes detailed JSON status files
#   - Low overhead monitoring (<0.1% CPU)
#
# Output:
#   ~/agents/status/agent-{N}-status.json - Per-agent detailed status
#   ~/agents/status/LATEST-RUN.json       - Summary of current monitoring run
###############################################################################

set -euo pipefail

# Configuration
STATUS_DIR="$HOME/agents/status"
LOG_DIR="$HOME/agents/logs"
TASKS_DIR="$HOME/agents/tasks"
PROJECT_DIR="$HOME/projects/continuously-running-agents"
SCRIPTS_DIR="$HOME/scripts"
CHECK_INTERVAL=60  # Check every 60 seconds

# Auto-restart configuration
AUTO_RESTART="${AUTO_RESTART:-true}"  # Enable by default, set to false to disable
MAX_RESTART_ATTEMPTS=3
RESTART_DELAY=10  # Seconds between restart attempts

# Ensure directories exist
mkdir -p "$STATUS_DIR"
mkdir -p "$LOG_DIR"
mkdir -p "$TASKS_DIR"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] ✓${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] ⚠${NC} $*"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ✗${NC} $*"
}

# Get list of agent sessions
get_agent_sessions() {
    tmux list-sessions 2>/dev/null | grep -E '^prod-agent-[0-9]+:' | cut -d':' -f1 || true
}

# Get agent number from session name
get_agent_number() {
    local session=$1
    echo "$session" | sed 's/prod-agent-//'
}

# Check if session is still running
is_session_running() {
    local session=$1
    tmux has-session -t "$session" 2>/dev/null
}

# Get session start time
get_session_start_time() {
    local session=$1
    tmux list-sessions 2>/dev/null | grep "^$session:" | awk '{print $6" "$7" "$8" "$9}' || echo "unknown"
}

# Get session uptime in seconds
get_session_uptime_seconds() {
    local session=$1
    local created=$(tmux list-sessions -F '#{session_name}|#{session_created}' 2>/dev/null | grep "^$session|" | cut -d'|' -f2)
    if [ -n "$created" ]; then
        local now=$(date +%s)
        echo $((now - created))
    else
        echo "0"
    fi
}

# Get latest log file for agent
get_agent_log() {
    local agent_num=$1
    ls -t "$LOG_DIR/agent-${agent_num}-"*.log 2>/dev/null | head -1 || echo ""
}

# Check if log shows completion
check_log_completion() {
    local log_file=$1
    if [ ! -f "$log_file" ]; then
        echo "unknown"
        return
    fi

    # Look for completion indicators in last 50 lines
    if tail -50 "$log_file" 2>/dev/null | grep -qi "session.*end\|agent.*complete\|exiting\|finished"; then
        echo "completed"
    elif tail -50 "$log_file" 2>/dev/null | grep -qi "error\|failed\|timeout"; then
        echo "error"
    else
        echo "running"
    fi
}

# Get resource usage for agent process
get_agent_resources() {
    local session=$1
    local pane_pid=$(tmux list-panes -t "$session" -F '#{pane_pid}' 2>/dev/null | head -1)

    if [ -z "$pane_pid" ]; then
        echo "{\"cpu\": 0, \"ram_mb\": 0}"
        return
    fi

    # Find claude process (child of tmux pane)
    local claude_pid=$(pgrep -P "$pane_pid" claude 2>/dev/null | head -1)

    if [ -z "$claude_pid" ]; then
        echo "{\"cpu\": 0, \"ram_mb\": 0}"
        return
    fi

    # Get CPU and RAM from ps
    local stats=$(ps -p "$claude_pid" -o %cpu=,%mem= 2>/dev/null || echo "0 0")
    local cpu=$(echo "$stats" | awk '{print $1}')
    local mem_percent=$(echo "$stats" | awk '{print $2}')

    # Calculate RAM in MB (total RAM * mem_percent / 100)
    local total_ram_mb=$(free -m | awk '/^Mem:/ {print $2}')
    local ram_mb=$(awk "BEGIN {printf \"%.0f\", $total_ram_mb * $mem_percent / 100}")

    echo "{\"cpu\": $cpu, \"ram_mb\": $ram_mb, \"pid\": $claude_pid}"
}

# Check for created PRs
check_created_prs() {
    cd "$PROJECT_DIR" || return

    # Get PRs created in last 24 hours by renchris-agent
    local prs=$(gh pr list --author renchris-agent --limit 20 --json number,title,createdAt 2>/dev/null | \
        jq -r '.[] | select((now - (.createdAt | fromdateiso8601)) < 86400) | "#\(.number)"' 2>/dev/null | \
        tr '\n' ' ' | sed 's/ $//')

    echo "$prs"
}

# Check for created files
check_created_files() {
    cd "$PROJECT_DIR" || return

    # Check for files created in last 2 hours
    local files=$(find . -maxdepth 1 -type f -name "*.md" -mmin -120 2>/dev/null | \
        grep -E "(DOCUMENTATION-GAPS|WILDCARD-VALIDATION|production-dashboard)" | \
        sed 's|^\./||' | tr '\n' ' ' | sed 's/ $//')

    echo "$files"
}

# Get task metadata for agent
get_agent_task() {
    local agent_num=$1
    local task_file="$TASKS_DIR/agent-${agent_num}-task.txt"

    if [ -f "$task_file" ]; then
        cat "$task_file"
    else
        echo "Unknown task"
    fi
}

# Determine failure reason from log
determine_failure_reason() {
    local log_file=$1

    if [ ! -f "$log_file" ]; then
        echo "Log file not found"
        return
    fi

    # Check last 100 lines for error patterns
    local log_tail=$(tail -100 "$log_file" 2>/dev/null)

    if echo "$log_tail" | grep -qi "authentication\|login\|unauthorized\|invalid.*key"; then
        echo "Authentication failure"
    elif echo "$log_tail" | grep -qi "timeout\|timed out"; then
        echo "Timeout"
    elif echo "$log_tail" | grep -qi "out of memory\|oom\|memory.*exhausted"; then
        echo "Out of memory"
    elif echo "$log_tail" | grep -qi "connection.*refused\|network.*error\|api.*unavailable"; then
        echo "Network/API error"
    elif echo "$log_tail" | grep -qi "rate.*limit\|quota.*exceeded"; then
        echo "Rate limit exceeded"
    elif echo "$log_tail" | grep -qi "permission.*denied\|access.*denied"; then
        echo "Permission denied"
    elif [ -n "$log_file" ]; then
        local log_size=$(stat -c%s "$log_file" 2>/dev/null || stat -f%z "$log_file" 2>/dev/null || echo 0)
        if [ "$log_size" -lt 500 ]; then
            echo "Startup failure (silent crash)"
        else
            echo "Unknown error"
        fi
    else
        echo "Unknown error"
    fi
}

# Restart agent
restart_agent() {
    local agent_num=$1
    local status_file="$STATUS_DIR/agent-${agent_num}-status.json"

    # Get current restart attempts
    local restart_attempts=$(jq -r '.restart_attempts // 0' "$status_file")

    # Check if we've exceeded max attempts
    if [ "$restart_attempts" -ge "$MAX_RESTART_ATTEMPTS" ]; then
        log_error "Agent $agent_num: Max restart attempts ($MAX_RESTART_ATTEMPTS) reached, giving up"
        return 1
    fi

    # Get task description
    local task=$(get_agent_task "$agent_num")

    if [ "$task" = "Unknown task" ]; then
        log_error "Agent $agent_num: Cannot restart - task metadata not found"
        return 1
    fi

    # Increment restart attempts
    restart_attempts=$((restart_attempts + 1))
    local restart_time=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

    # Update status file with restart info
    jq \
        --argjson attempts "$restart_attempts" \
        --arg restart_time "$restart_time" \
        '.restart_attempts = $attempts |
         .last_restart = $restart_time |
         .recovery_successful = null' \
        "$status_file" > "${status_file}.tmp"
    mv "${status_file}.tmp" "$status_file"

    log_warning "Agent $agent_num: Attempting restart ($restart_attempts/$MAX_RESTART_ATTEMPTS) in ${RESTART_DELAY}s..."
    log "Agent $agent_num: Task: $task"

    # Wait before restart
    sleep "$RESTART_DELAY"

    # Kill existing session if still exists
    local session="prod-agent-${agent_num}"
    if tmux has-session -t "$session" 2>/dev/null; then
        log "Agent $agent_num: Killing existing session"
        tmux kill-session -t "$session" 2>/dev/null || true
        sleep 2
    fi

    # Start new agent session
    log "Agent $agent_num: Starting new session..."

    # Call start-agent-yolo.sh script
    if [ -f "$SCRIPTS_DIR/start-agent-yolo.sh" ]; then
        bash "$SCRIPTS_DIR/start-agent-yolo.sh" "$agent_num" "$task" > /dev/null 2>&1
        log_success "Agent $agent_num: Restart initiated"
        return 0
    else
        log_error "Agent $agent_num: Cannot find start-agent-yolo.sh script"
        return 1
    fi
}

# Initialize agent status file
init_agent_status() {
    local agent_num=$1
    local session=$2
    local status_file="$STATUS_DIR/agent-${agent_num}-status.json"

    # Only init if doesn't exist
    if [ -f "$status_file" ]; then
        return
    fi

    local start_time=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

    cat > "$status_file" <<EOF
{
  "agent_number": $agent_num,
  "session": "$session",
  "status": "running",
  "started": "$start_time",
  "completed": null,
  "duration_seconds": 0,
  "pr_created": [],
  "files_created": [],
  "exit_code": null,
  "errors": [],
  "restart_attempts": 0,
  "last_restart": null,
  "failure_reason": null,
  "recovery_successful": null,
  "resources": {
    "cpu_percent": 0,
    "ram_mb": 0,
    "peak_cpu": 0,
    "peak_ram_mb": 0
  }
}
EOF

    log "Initialized status for agent-$agent_num"
}

# Inject metrics into PR if newly created
inject_pr_metrics() {
    local agent_num=$1
    local pr_number=$2
    local inject_script="$(dirname "$0")/inject-pr-metrics.sh"

    if [ ! -f "$inject_script" ]; then
        log_warning "Metrics injection script not found: $inject_script"
        return 1
    fi

    # Check if metrics already injected (tracked in status file)
    local status_file="$STATUS_DIR/agent-${agent_num}-status.json"
    local injected=$(jq -r '.metrics_injected // false' "$status_file" 2>/dev/null)

    if [ "$injected" = "true" ]; then
        return 0  # Already injected
    fi

    log "Agent-$agent_num: Injecting metrics into PR #$pr_number..."

    if bash "$inject_script" "$pr_number" "$agent_num" 2>&1 | tee -a "$LOG_DIR/metrics-injection.log"; then
        log_success "Agent-$agent_num: Metrics injected into PR #$pr_number"

        # Mark as injected in status file
        jq '.metrics_injected = true' "$status_file" > "${status_file}.tmp"
        mv "${status_file}.tmp" "$status_file"

        return 0
    else
        log_error "Agent-$agent_num: Failed to inject metrics into PR #$pr_number"
        return 1
    fi
}

# Update agent status
update_agent_status() {
    local agent_num=$1
    local session=$2
    local status_file="$STATUS_DIR/agent-${agent_num}-status.json"

    # Initialize if needed
    if [ ! -f "$status_file" ]; then
        init_agent_status "$agent_num" "$session"
    fi

    # Check if session still running
    local status="running"
    local exit_code=null

    if ! is_session_running "$session"; then
        status="completed"
        exit_code=0

        # Check log for errors
        local log_file=$(get_agent_log "$agent_num")
        if [ -n "$log_file" ]; then
            local log_status=$(check_log_completion "$log_file")
            if [ "$log_status" = "error" ]; then
                status="error"
                exit_code=1
            fi
        fi
    fi

    # Detect Startup Failures (v2.7.0+)
    # Silent failures: log <500 bytes after 30+ seconds indicates pre-Claude-init failure
    local failure_detected=false
    local failure_reason=""

    if [ -n "$log_file" ] && [ -f "$log_file" ]; then
        local uptime=$(get_session_uptime_seconds "$session")
        if [ "$uptime" -gt 30 ]; then
            local log_size=$(stat -c%s "$log_file" 2>/dev/null || stat -f%z "$log_file" 2>/dev/null || echo 0)
            if [ "$log_size" -lt 500 ]; then
                status="error"
                exit_code=1
                failure_detected=true
                failure_reason=$(determine_failure_reason "$log_file")
                log_warning "Agent $agent_num: Startup failure detected (log ${log_size}B after ${uptime}s) - Reason: $failure_reason"
            fi
        fi
    fi

    # Detect other failure modes
    if [ "$status" = "error" ] && [ "$failure_detected" = false ]; then
        failure_detected=true
        failure_reason=$(determine_failure_reason "$log_file")
        log_warning "Agent $agent_num: Failure detected - Reason: $failure_reason"
    fi

    # Get current resources
    local resources=$(get_agent_resources "$session")
    local cpu=$(echo "$resources" | jq -r '.cpu // 0')
    local ram_mb=$(echo "$resources" | jq -r '.ram_mb // 0')

    # Get existing peak values
    local peak_cpu=$(jq -r '.resources.peak_cpu // 0' "$status_file")
    local peak_ram=$(jq -r '.resources.peak_ram_mb // 0' "$status_file")

    # Update peaks
    peak_cpu=$(awk "BEGIN {print ($cpu > $peak_cpu) ? $cpu : $peak_cpu}")
    peak_ram=$(awk "BEGIN {print ($ram_mb > $peak_ram) ? $ram_mb : $peak_ram}")

    # Calculate duration
    local started=$(jq -r '.started' "$status_file")
    local started_epoch=$(date -d "$started" +%s 2>/dev/null || echo "0")
    local now_epoch=$(date +%s)
    local duration=$((now_epoch - started_epoch))

    # Check for PRs and files
    local prs=$(check_created_prs)
    local files=$(check_created_files)

    # Update status file
    local completed_time="null"
    if [ "$status" != "running" ]; then
        completed_time="\"$(date -u '+%Y-%m-%dT%H:%M:%SZ')\""
    fi

    jq \
        --arg status "$status" \
        --argjson exit_code "$exit_code" \
        --arg completed "$completed_time" \
        --argjson duration "$duration" \
        --argjson cpu "$cpu" \
        --argjson ram_mb "$ram_mb" \
        --argjson peak_cpu "$peak_cpu" \
        --argjson peak_ram "$peak_ram" \
        --arg prs "$prs" \
        --arg files "$files" \
        --arg failure_reason "$failure_reason" \
        '.status = $status |
         .exit_code = $exit_code |
         .completed = $completed |
         .duration_seconds = $duration |
         .pr_created = ($prs | split(" ") | map(select(length > 0))) |
         .files_created = ($files | split(" ") | map(select(length > 0))) |
         .resources.cpu_percent = $cpu |
         .resources.ram_mb = $ram_mb |
         .resources.peak_cpu = $peak_cpu |
         .resources.peak_ram_mb = $peak_ram |
         .failure_reason = (if $failure_reason != "" then $failure_reason else .failure_reason end)' \
        "$status_file" > "${status_file}.tmp"

    mv "${status_file}.tmp" "$status_file"

    # Auto-inject metrics into PRs when detected
    if [ -n "$prs" ]; then
        # Get previous PR list to detect new PRs
        local prev_prs=$(jq -r '.pr_created | join(" ")' "$status_file" 2>/dev/null || echo "")

        # Extract PR numbers from the current list
        for pr in $prs; do
            # Extract number from "#123" format
            local pr_num=$(echo "$pr" | sed 's/#//')

            # Check if this PR was in previous list
            if ! echo "$prev_prs" | grep -q "#${pr_num}"; then
                log "Agent-$agent_num: New PR detected: #$pr_num"
                # Inject metrics (function handles idempotency)
                inject_pr_metrics "$agent_num" "$pr_num" || true
            fi
        done
    fi

    # Auto-restart logic
    if [ "$AUTO_RESTART" = "true" ] && [ "$failure_detected" = "true" ] && [ "$status" = "error" ]; then
        log_warning "Agent $agent_num: Auto-restart enabled, attempting recovery..."

        if restart_agent "$agent_num"; then
            # Mark recovery as successful
            jq '.recovery_successful = true' "$status_file" > "${status_file}.tmp"
            mv "${status_file}.tmp" "$status_file"
        else
            # Mark recovery as failed
            jq '.recovery_successful = false' "$status_file" > "${status_file}.tmp"
            mv "${status_file}.tmp" "$status_file"
        fi
    fi
}

# Update summary file
update_summary() {
    local summary_file="$STATUS_DIR/LATEST-RUN.json"

    # Collect all agent statuses
    local agent_statuses="[]"
    for status_file in "$STATUS_DIR"/agent-*-status.json; do
        if [ -f "$status_file" ]; then
            local agent_status=$(cat "$status_file")
            agent_statuses=$(echo "$agent_statuses" | jq --argjson agent "$agent_status" '. + [$agent]')
        fi
    done

    # Count by status
    local running_count=$(echo "$agent_statuses" | jq '[.[] | select(.status == "running")] | length')
    local completed_count=$(echo "$agent_statuses" | jq '[.[] | select(.status == "completed")] | length')
    local error_count=$(echo "$agent_statuses" | jq '[.[] | select(.status == "error")] | length')
    local total_count=$(echo "$agent_statuses" | jq 'length')

    # Create summary
    cat > "$summary_file" <<EOF
{
  "timestamp": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')",
  "summary": {
    "total_agents": $total_count,
    "running": $running_count,
    "completed": $completed_count,
    "errors": $error_count
  },
  "agents": $agent_statuses
}
EOF
}

# Main monitoring loop
main() {
    log "Starting agent completion watcher"
    log "Status directory: $STATUS_DIR"
    log "Check interval: ${CHECK_INTERVAL}s"
    echo ""

    while true; do
        # Get all current agent sessions
        local sessions=$(get_agent_sessions)

        if [ -z "$sessions" ]; then
            log_warning "No active agent sessions found"
        else
            for session in $sessions; do
                local agent_num=$(get_agent_number "$session")
                log "Checking agent-$agent_num ($session)..."

                update_agent_status "$agent_num" "$session"

                # Show status
                local status=$(jq -r '.status' "$STATUS_DIR/agent-${agent_num}-status.json")
                if [ "$status" = "completed" ]; then
                    log_success "Agent-$agent_num: COMPLETED"
                elif [ "$status" = "error" ]; then
                    log_error "Agent-$agent_num: ERROR"
                else
                    local duration=$(jq -r '.duration_seconds' "$STATUS_DIR/agent-${agent_num}-status.json")
                    local duration_min=$((duration / 60))
                    log "Agent-$agent_num: RUNNING (${duration_min}m)"
                fi
            done
        fi

        # Update summary
        update_summary

        # Show summary
        echo ""
        log "Summary: $(jq -r '.summary | "Total: \(.total_agents) | Running: \(.running) | Completed: \(.completed) | Errors: \(.errors)"' "$STATUS_DIR/LATEST-RUN.json")"
        echo ""

        # Sleep
        sleep "$CHECK_INTERVAL"
    done
}

# Run main loop
main
