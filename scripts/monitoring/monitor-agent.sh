#!/bin/bash

###############################################################################
# Agent Monitoring Script
#
# Real-time monitoring dashboard for Claude Code agents running on OVHCloud.
# Displays system resources, agent status, and recent activity.
#
# Usage:
#   bash monitor-agent.sh [refresh-interval]
#
# Examples:
#   bash monitor-agent.sh           # Default 5 second refresh
#   bash monitor-agent.sh 10        # 10 second refresh
#
# Features:
#   - Real-time resource usage (CPU, RAM, Disk)
#   - Active tmux sessions
#   - Recent log entries
#   - Agent health status
#   - API usage tracking (if available)
###############################################################################

# Configuration
REFRESH_INTERVAL="${1:-5}"  # Default 5 seconds
LOG_DIR="$HOME/agents/logs"
SESSION_INFO_DIR="$HOME/agents/.sessions"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Display header
show_header() {
    echo -e "${BOLD}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║        Claude Code Agent Monitoring Dashboard                 ║${NC}"
    echo -e "${BOLD}║        OVHCloud Instance                                      ║${NC}"
    echo -e "${BOLD}╠═══════════════════════════════════════════════════════════════╣${NC}"
}

# Display system resources
show_system_resources() {
    echo -e "${CYAN}${BOLD}System Resources:${NC}"

    # CPU Usage
    if command -v mpstat &> /dev/null; then
        CPU_USAGE=$(mpstat 1 1 | awk '/Average/ {print 100 - $NF"%"}')
    else
        CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')
    fi
    echo -e "  CPU:  ${GREEN}$CPU_USAGE${NC}"

    # Memory Usage
    MEM_TOTAL=$(free -h | awk '/^Mem:/ {print $2}')
    MEM_USED=$(free -h | awk '/^Mem:/ {print $3}')
    MEM_PERCENT=$(free | awk '/^Mem:/ {printf("%.1f%%"), ($3/$2) * 100}')
    echo -e "  RAM:  ${GREEN}$MEM_USED / $MEM_TOTAL ($MEM_PERCENT)${NC}"

    # Disk Usage
    DISK_USED=$(df -h / | awk 'NR==2 {print $3}')
    DISK_TOTAL=$(df -h / | awk 'NR==2 {print $2}')
    DISK_PERCENT=$(df -h / | awk 'NR==2 {print $5}')
    echo -e "  Disk: ${GREEN}$DISK_USED / $DISK_TOTAL ($DISK_PERCENT)${NC}"

    # Load Average
    LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | xargs)
    echo -e "  Load: ${GREEN}$LOAD_AVG${NC}"

    # Network (if nethogs is available)
    if command -v vnstat &> /dev/null; then
        NETWORK=$(vnstat -tr 2 -i eth0 2>/dev/null | tail -n 1 | awk '{print "↓"$2" "$3" ↑"$5" "$6}' || echo "N/A")
        echo -e "  Net:  ${GREEN}$NETWORK${NC}"
    fi

    echo ""
}

# Display active tmux sessions
show_active_sessions() {
    echo -e "${CYAN}${BOLD}Active Agent Sessions:${NC}"

    if ! tmux list-sessions &>/dev/null; then
        echo -e "  ${YELLOW}No active sessions${NC}"
        echo ""
        return
    fi

    # Get session info
    tmux list-sessions -F '#{session_name}|#{session_created}|#{session_windows}|#{session_attached}' 2>/dev/null | while IFS='|' read -r name created windows attached; do
        # Calculate uptime
        now=$(date +%s)
        uptime_sec=$((now - created))
        uptime_str=$(printf '%dd %dh %dm' $((uptime_sec/86400)) $((uptime_sec%86400/3600)) $((uptime_sec%3600/60)))

        # Attached status
        if [ "$attached" = "1" ]; then
            status="${GREEN}●${NC} attached"
        else
            status="${YELLOW}○${NC} detached"
        fi

        echo -e "  ${BOLD}$name${NC} - $status - ${windows} windows - up ${uptime_str}"

        # Show session info if available
        if [ -f "$SESSION_INFO_DIR/$name.info" ]; then
            project=$(jq -r '.project_path' "$SESSION_INFO_DIR/$name.info" 2>/dev/null || echo "N/A")
            task=$(jq -r '.task' "$SESSION_INFO_DIR/$name.info" 2>/dev/null || echo "N/A")
            echo -e "    Project: $project"
            [ "$task" != "null" ] && [ -n "$task" ] && echo -e "    Task: $task"
        fi
        echo ""
    done
}

# Show recent log activity
show_recent_logs() {
    echo -e "${CYAN}${BOLD}Recent Activity (last 10 lines):${NC}"

    if [ ! -d "$LOG_DIR" ] || [ -z "$(ls -A $LOG_DIR 2>/dev/null)" ]; then
        echo -e "  ${YELLOW}No logs found${NC}"
        echo ""
        return
    fi

    # Get most recent log file
    LATEST_LOG=$(ls -t $LOG_DIR/*.log 2>/dev/null | head -n 1)

    if [ -z "$LATEST_LOG" ]; then
        echo -e "  ${YELLOW}No log files${NC}"
        echo ""
        return
    fi

    echo -e "  ${BLUE}File: $(basename $LATEST_LOG)${NC}"
    echo ""

    # Show last 10 lines with basic formatting
    tail -n 10 "$LATEST_LOG" 2>/dev/null | while IFS= read -r line; do
        # Highlight errors
        if echo "$line" | grep -iq "error"; then
            echo -e "  ${RED}$line${NC}"
        # Highlight warnings
        elif echo "$line" | grep -iq "warn"; then
            echo -e "  ${YELLOW}$line${NC}"
        # Highlight success
        elif echo "$line" | grep -iq "success\|complete\|done"; then
            echo -e "  ${GREEN}$line${NC}"
        else
            echo -e "  $line"
        fi
    done

    echo ""
}

# Show agent health status
show_health_status() {
    echo -e "${CYAN}${BOLD}Health Status:${NC}"

    # Check if API key is set
    if [ -n "$ANTHROPIC_API_KEY" ]; then
        echo -e "  ${GREEN}✓${NC} API Key configured"
    else
        echo -e "  ${RED}✗${NC} API Key not set"
    fi

    # Check if Claude is installed
    if command -v claude &> /dev/null; then
        CLAUDE_VERSION=$(claude --version 2>&1 | head -n 1)
        echo -e "  ${GREEN}✓${NC} Claude Code CLI: $CLAUDE_VERSION"
    else
        echo -e "  ${RED}✗${NC} Claude Code CLI not installed"
    fi

    # Check if tmux is running
    if tmux list-sessions &>/dev/null; then
        SESSION_COUNT=$(tmux list-sessions 2>/dev/null | wc -l)
        echo -e "  ${GREEN}✓${NC} tmux: $SESSION_COUNT active sessions"
    else
        echo -e "  ${YELLOW}○${NC} tmux: No sessions"
    fi

    # Check disk space (warn if < 10%)
    DISK_AVAIL=$(df / | awk 'NR==2 {print $4}')
    DISK_TOTAL=$(df / | awk 'NR==2 {print $2}')
    DISK_PERCENT=$(awk "BEGIN {printf \"%.0f\", ($DISK_AVAIL/$DISK_TOTAL)*100}")

    if [ "$DISK_PERCENT" -lt 10 ]; then
        echo -e "  ${RED}⚠${NC}  Disk space low: ${DISK_PERCENT}% available"
    else
        echo -e "  ${GREEN}✓${NC} Disk space: ${DISK_PERCENT}% available"
    fi

    # Check memory (warn if > 90% used)
    MEM_PERCENT_NUM=$(free | awk '/^Mem:/ {printf("%.0f"), ($3/$2) * 100}')

    if [ "$MEM_PERCENT_NUM" -gt 90 ]; then
        echo -e "  ${RED}⚠${NC}  Memory usage high: ${MEM_PERCENT_NUM}%"
    else
        echo -e "  ${GREEN}✓${NC} Memory usage: ${MEM_PERCENT_NUM}%"
    fi

    echo ""
}

# Show footer with commands
show_footer() {
    echo -e "${BOLD}╠═══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${BOLD}║ Commands:${NC} (q)uit | (a)ttach | (l)ogs | (r)efresh"
    echo -e "${BOLD}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo -e "Refreshing in ${REFRESH_INTERVAL}s... (Ctrl+C to exit)"
}

# Interactive mode - attach to session
attach_to_session() {
    clear
    echo "Available sessions:"
    tmux list-sessions 2>/dev/null || echo "No sessions"
    echo ""
    read -p "Enter session name to attach: " session_name

    if [ -n "$session_name" ]; then
        tmux attach -t "$session_name"
    fi
}

# View full logs
view_logs() {
    clear
    echo "Available log files:"
    ls -lh $LOG_DIR/*.log 2>/dev/null || echo "No logs"
    echo ""
    read -p "Enter log file name (or press Enter for latest): " log_file

    if [ -z "$log_file" ]; then
        log_file=$(ls -t $LOG_DIR/*.log 2>/dev/null | head -n 1)
    else
        log_file="$LOG_DIR/$log_file"
    fi

    if [ -f "$log_file" ]; then
        less +G "$log_file"
    else
        echo "Log file not found"
        sleep 2
    fi
}

# Main monitoring loop
monitor_loop() {
    while true; do
        clear
        show_header
        echo ""
        show_system_resources
        show_active_sessions
        show_health_status
        show_recent_logs
        show_footer

        # Wait for refresh or user input
        read -t $REFRESH_INTERVAL -n 1 key

        case $key in
            q|Q)
                clear
                echo "Monitoring stopped."
                exit 0
                ;;
            a|A)
                attach_to_session
                ;;
            l|L)
                view_logs
                ;;
            r|R)
                # Refresh immediately
                continue
                ;;
        esac
    done
}

# Check if running in interactive terminal
if [ -t 0 ]; then
    # Interactive mode
    monitor_loop
else
    # Non-interactive - single output
    clear
    show_header
    echo ""
    show_system_resources
    show_active_sessions
    show_health_status
    show_recent_logs
fi
