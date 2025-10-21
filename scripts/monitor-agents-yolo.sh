#!/bin/bash
###############################################################################
# Enhanced Agent Monitor for YOLO Mode
#
# Monitors autonomous agents running with --dangerously-skip-permissions
# Provides detailed metrics, safety alerts, and resource usage tracking.
#
# Usage:
#   bash monitor-agents-yolo.sh
#   bash monitor-agents-yolo.sh --watch  # Continuous monitoring
#   bash monitor-agents-yolo.sh --alerts # Show only safety alerts
###############################################################################

SERVER="claude-agent@5.78.152.238"
SSH_KEY="$HOME/.ssh/hetzner_claude_agent"
WATCH_MODE=false
ALERTS_ONLY=false

# Parse arguments
case "$1" in
    --watch) WATCH_MODE=true ;;
    --alerts) ALERTS_ONLY=true ;;
esac

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Alert thresholds
MAX_CPU_PERCENT=75
MAX_MEMORY_PERCENT=85
MAX_AGENT_RUNTIME_HOURS=8
MIN_ACTIVITY_MINUTES=30

# Function to convert Unix timestamp to human-readable
human_time() {
    local timestamp=$1
    local current=$(date +%s)
    local diff=$((current - timestamp))

    local hours=$((diff / 3600))
    local minutes=$(((diff % 3600) / 60))

    if [ $hours -gt 0 ]; then
        echo "${hours}h ${minutes}m"
    else
        echo "${minutes}m"
    fi
}

# Function to check if value exceeds threshold
check_threshold() {
    local value=$1
    local threshold=$2
    local comparison=${3:-gt}  # gt or lt

    if [ "$comparison" = "gt" ]; then
        [ "$value" -gt "$threshold" ] && return 0 || return 1
    else
        [ "$value" -lt "$threshold" ] && return 0 || return 1
    fi
}

# Main monitoring function
monitor_agents() {
    if [ "$ALERTS_ONLY" = false ]; then
        clear
        echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║       Agent Monitoring Dashboard (YOLO Mode Enhanced)         ║${NC}"
        echo -e "${BLUE}╠════════════════════════════════════════════════════════════════╣${NC}"
        echo ""
    fi

    # Get current time on server
    CURRENT_TIME=$(ssh -i "$SSH_KEY" "$SERVER" "date +%s" 2>/dev/null)

    # Get session info
    SESSION_INFO=$(ssh -i "$SSH_KEY" "$SERVER" \
        "tmux list-sessions -F '#{session_name}:#{session_created}:#{session_activity}' 2>/dev/null | grep prod-agent" 2>/dev/null)

    # Get detailed process info
    PROCESS_INFO=$(ssh -i "$SSH_KEY" "$SERVER" \
        "ps aux | grep -E 'claude.*dangerously-skip' | grep -v grep" 2>/dev/null)

    # Get recent log info
    LOG_INFO=$(ssh -i "$SSH_KEY" "$SERVER" \
        "find ~/agents/logs -name 'agent-*' -type f -mmin -30 2>/dev/null | wc -l" 2>/dev/null)

    # Safety alerts array
    declare -a ALERTS

    if [ "$ALERTS_ONLY" = false ]; then
        echo -e "${GREEN}Active Agents:${NC}"
        echo ""
    fi

    # Parse and display each agent
    AGENT_COUNT=0
    while IFS=: read -r session_name created activity; do
        [ -z "$session_name" ] && continue

        agent_num="${session_name#prod-agent-}"
        AGENT_COUNT=$((AGENT_COUNT + 1))

        # Calculate runtime
        runtime=$(human_time "$created")
        runtime_hours=$(( (CURRENT_TIME - created) / 3600 ))

        # Calculate time since last activity
        if [ "$activity" != "$created" ]; then
            last_active_seconds=$((CURRENT_TIME - activity))
            last_active=$(human_time "$activity")
            activity_status="${GREEN}Active ${last_active} ago${NC}"

            # Alert if no activity for too long
            last_active_minutes=$((last_active_seconds / 60))
            if [ "$last_active_minutes" -gt "$MIN_ACTIVITY_MINUTES" ]; then
                activity_status="${RED}Idle ${last_active} ago (⚠️  STALE)${NC}"
                ALERTS+=("Agent $agent_num: No activity for $last_active")
            fi
        else
            activity_status="${YELLOW}No activity yet${NC}"
            ALERTS+=("Agent $agent_num: Never active since startup")
        fi

        # Get CPU and memory usage for this agent's process
        agent_ps=$(echo "$PROCESS_INFO" | grep "tmux.*agent-${agent_num}" | head -1)
        if [ -n "$agent_ps" ]; then
            cpu=$(echo "$agent_ps" | awk '{print $3}' | cut -d. -f1)
            mem=$(echo "$agent_ps" | awk '{print $4}' | cut -d. -f1)
            pid=$(echo "$agent_ps" | awk '{print $2}')
            cpu_mem="${cpu}% CPU, ${mem}% RAM"

            # Check CPU threshold
            if [ -n "$cpu" ] && [ "$cpu" -gt "$MAX_CPU_PERCENT" ]; then
                cpu_mem="${RED}${cpu}% CPU (⚠️  HIGH), ${mem}% RAM${NC}"
                ALERTS+=("Agent $agent_num: High CPU usage ($cpu%)")
            fi

            # Check memory threshold
            if [ -n "$mem" ] && [ "$mem" -gt "$MAX_MEMORY_PERCENT" ]; then
                cpu_mem="${cpu}% CPU, ${RED}${mem}% RAM (⚠️  HIGH)${NC}"
                ALERTS+=("Agent $agent_num: High memory usage ($mem%)")
            fi
        else
            cpu_mem="${YELLOW}Not running (⚠️  DEAD)${NC}"
            ALERTS+=("Agent $agent_num: Process not found")
            pid="N/A"
        fi

        # Check runtime threshold
        runtime_status="$runtime"
        if [ "$runtime_hours" -gt "$MAX_AGENT_RUNTIME_HOURS" ]; then
            runtime_status="${RED}$runtime (⚠️  OVERTIME)${NC}"
            ALERTS+=("Agent $agent_num: Running for $runtime (> ${MAX_AGENT_RUNTIME_HOURS}h)")
        fi

        # Get recent commits from this agent
        recent_commits=$(ssh -i "$SSH_KEY" "$SERVER" \
            "cd ~/projects/continuously-running-agents && git log --since='1 hour ago' --author='renchris-agent' --oneline 2>/dev/null | wc -l" 2>/dev/null || echo "0")

        if [ "$ALERTS_ONLY" = false ]; then
            echo -e "  ${BLUE}Agent ${agent_num}:${NC}"
            echo -e "    Runtime:       ${runtime_status}"
            echo -e "    Status:        ${activity_status}"
            echo -e "    Resources:     ${cpu_mem}"
            echo -e "    PID:           ${pid}"
            echo -e "    Commits (1h):  ${recent_commits}"
            echo ""
        fi
    done <<< "$SESSION_INFO"

    # System resources
    if [ "$ALERTS_ONLY" = false ]; then
        echo -e "${GREEN}System Resources:${NC}"
        RAM_INFO=$(ssh -i "$SSH_KEY" "$SERVER" "free -h | grep Mem" 2>/dev/null)
        RAM_USED=$(echo "$RAM_INFO" | awk '{print $3}')
        RAM_TOTAL=$(echo "$RAM_INFO" | awk '{print $2}')
        RAM_PERCENT=$(ssh -i "$SSH_KEY" "$SERVER" "free | grep Mem | awk '{printf \"%.0f\", (\$3/\$2)*100}'" 2>/dev/null)

        DISK_INFO=$(ssh -i "$SSH_KEY" "$SERVER" "df -h / | tail -1" 2>/dev/null)
        DISK_USED=$(echo "$DISK_INFO" | awk '{print $3}')
        DISK_TOTAL=$(echo "$DISK_INFO" | awk '{print $2}')
        DISK_PERCENT=$(echo "$DISK_INFO" | awk '{print $5}' | tr -d '%')

        RAM_DISPLAY="${RAM_USED} / ${RAM_TOTAL} (${RAM_PERCENT}%)"
        if [ "$RAM_PERCENT" -gt "$MAX_MEMORY_PERCENT" ]; then
            RAM_DISPLAY="${RED}${RAM_DISPLAY} (⚠️  HIGH)${NC}"
            ALERTS+=("System: High RAM usage ($RAM_PERCENT%)")
        fi

        echo -e "  RAM:   ${RAM_DISPLAY}"
        echo -e "  Disk:  ${DISK_USED} / ${DISK_TOTAL} (${DISK_PERCENT}%)"
        echo ""
    fi

    # Work Output
    if [ "$ALERTS_ONLY" = false ]; then
        PR_COUNT=$(ssh -i "$SSH_KEY" "$SERVER" \
            "cd ~/projects/continuously-running-agents && gh pr list 2>/dev/null | wc -l" 2>/dev/null || echo "0")

        RECENT_COMMITS=$(ssh -i "$SSH_KEY" "$SERVER" \
            "cd ~/projects/continuously-running-agents && git log --since='2 hours ago' --oneline 2>/dev/null | wc -l" 2>/dev/null || echo "0")

        echo -e "${GREEN}Work Output:${NC}"
        echo -e "  Pull Requests:  ${PR_COUNT}"
        echo -e "  Recent Commits: ${RECENT_COMMITS} (last 2 hours)"
        echo -e "  Active Agents:  ${AGENT_COUNT}"
        echo ""
    fi

    # Safety Alerts
    if [ ${#ALERTS[@]} -gt 0 ]; then
        echo -e "${RED}╔════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║                       SAFETY ALERTS                            ║${NC}"
        echo -e "${RED}╠════════════════════════════════════════════════════════════════╣${NC}"
        for alert in "${ALERTS[@]}"; do
            echo -e "${RED}  ⚠️  ${alert}${NC}"
        done
        echo -e "${RED}╚════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
    elif [ "$ALERTS_ONLY" = false ]; then
        echo -e "${GREEN}✓ No safety alerts - all agents operating normally${NC}"
        echo ""
    fi

    if [ "$ALERTS_ONLY" = false ]; then
        echo -e "${BLUE}╠════════════════════════════════════════════════════════════════╣${NC}"
        if [ "$WATCH_MODE" = true ]; then
            echo -e "${BLUE}║ Refreshing in 30 seconds... (Ctrl+C to exit)                  ║${NC}"
        else
            echo -e "${BLUE}║ Run with --watch for continuous monitoring                     ║${NC}"
            echo -e "${BLUE}║ Run with --alerts to see only safety alerts                    ║${NC}"
        fi
        echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    fi
}

# Main execution
if [ "$WATCH_MODE" = true ]; then
    while true; do
        monitor_agents
        sleep 30
    done
else
    monitor_agents
fi
