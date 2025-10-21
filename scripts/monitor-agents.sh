#!/bin/bash
###############################################################################
# Non-Intrusive Agent Monitor
#
# Monitors all agents without attaching to sessions or interrupting work.
# Uses tmux metadata, process info, and log analysis.
#
# Usage:
#   bash monitor-agents.sh
#   bash monitor-agents.sh --watch  # Continuous monitoring
###############################################################################

SERVER="claude-agent@5.78.152.238"
SSH_KEY="$HOME/.ssh/hetzner_claude_agent"
WATCH_MODE=false

# Parse arguments
if [[ "$1" == "--watch" ]]; then
    WATCH_MODE=true
fi

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

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

# Main monitoring function
monitor_agents() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║          Agent Monitoring Dashboard (Non-Intrusive)            ║${NC}"
    echo -e "${BLUE}╠════════════════════════════════════════════════════════════════╣${NC}"
    echo ""

    # Get current time on server
    CURRENT_TIME=$(ssh -i "$SSH_KEY" "$SERVER" "date +%s")

    # Get session info
    SESSION_INFO=$(ssh -i "$SSH_KEY" "$SERVER" "tmux list-sessions -F '#{session_name}:#{session_created}:#{session_activity}' 2>/dev/null | grep prod-agent")

    # Get process info
    PROCESS_INFO=$(ssh -i "$SSH_KEY" "$SERVER" "ps aux | grep -E '^claude-agent.*claude$' | grep -v grep")

    echo -e "${GREEN}Active Agents:${NC}"
    echo ""

    # Parse and display each agent
    echo "$SESSION_INFO" | while IFS=: read -r session_name created activity; do
        agent_num="${session_name#prod-agent-}"

        # Calculate runtime
        runtime=$(human_time "$created")

        # Calculate time since last activity
        if [ "$activity" != "$created" ]; then
            last_active=$(human_time "$activity")
            activity_status="${GREEN}Active ${last_active} ago${NC}"
        else
            activity_status="${YELLOW}No activity yet${NC}"
        fi

        # Get CPU and memory usage for this agent's process
        cpu_mem=$(echo "$PROCESS_INFO" | grep -A1 "pts/${agent_num}" | head -1 | awk '{print $3"% CPU, "$4"% RAM"}')
        if [ -z "$cpu_mem" ]; then
            cpu_mem="0.0% CPU, 0.0% RAM"
        fi

        echo -e "  ${BLUE}Agent ${agent_num}:${NC}"
        echo -e "    Runtime:       ${runtime}"
        echo -e "    Status:        ${activity_status}"
        echo -e "    Resources:     ${cpu_mem}"
        echo ""
    done

    # System resources
    echo -e "${GREEN}System Resources:${NC}"
    RAM_INFO=$(ssh -i "$SSH_KEY" "$SERVER" "free -h | grep Mem")
    RAM_USED=$(echo "$RAM_INFO" | awk '{print $3}')
    RAM_TOTAL=$(echo "$RAM_INFO" | awk '{print $2}')
    RAM_PERCENT=$(echo "$RAM_INFO" | awk '{printf "%.0f", ($3/$2)*100}' | bc)

    DISK_INFO=$(ssh -i "$SSH_KEY" "$SERVER" "df -h / | tail -1")
    DISK_USED=$(echo "$DISK_INFO" | awk '{print $3}')
    DISK_TOTAL=$(echo "$DISK_INFO" | awk '{print $2}')
    DISK_PERCENT=$(echo "$DISK_INFO" | awk '{print $5}')

    echo -e "  RAM:   ${RAM_USED} / ${RAM_TOTAL} (${RAM_PERCENT}%)"
    echo -e "  Disk:  ${DISK_USED} / ${DISK_TOTAL} (${DISK_PERCENT})"
    echo ""

    # Check for new PRs (non-intrusive)
    PR_COUNT=$(ssh -i "$SSH_KEY" "$SERVER" "cd ~/projects/continuously-running-agents && gh pr list 2>/dev/null | wc -l" 2>/dev/null || echo "0")

    echo -e "${GREEN}Work Output:${NC}"
    echo -e "  Pull Requests:  ${PR_COUNT}"
    echo ""

    # Check recent git activity
    RECENT_COMMITS=$(ssh -i "$SSH_KEY" "$SERVER" "cd ~/projects/continuously-running-agents && git log --oneline --since='2 hours ago' 2>/dev/null | wc -l" 2>/dev/null || echo "0")
    echo -e "  Recent Commits: ${RECENT_COMMITS} (last 2 hours)"
    echo ""

    echo -e "${BLUE}╠════════════════════════════════════════════════════════════════╣${NC}"

    if [ "$WATCH_MODE" = true ]; then
        echo -e "${BLUE}║ Refreshing in 30 seconds... (Ctrl+C to exit)                  ║${NC}"
        echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    else
        echo -e "${BLUE}║ Run with --watch for continuous monitoring                     ║${NC}"
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
