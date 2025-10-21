#!/bin/bash
###############################################################################
# Production Agent Monitoring Dashboard
#
# Comprehensive real-time monitoring for autonomous agents in production.
# Provides health status, resource usage, cost tracking, and task monitoring.
#
# Features:
#   - Real-time agent health (running/stopped/error)
#   - Resource usage per agent (CPU%, RAM MB, runtime)
#   - Cost tracking (€/hour rate based on Claude Max plan)
#   - Task status (commits, PRs, activity)
#   - Color-coded alerts (green=healthy, yellow=warning, red=error)
#   - Auto-refresh every 5 seconds
#
# Usage:
#   bash scripts/monitoring/production-dashboard.sh
#   bash scripts/monitoring/production-dashboard.sh --no-refresh  # Single run
#   bash scripts/monitoring/production-dashboard.sh --json       # JSON output
###############################################################################

set -euo pipefail

# Configuration
REFRESH_INTERVAL=5
AUTO_REFRESH=true
JSON_OUTPUT=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-refresh) AUTO_REFRESH=false; shift ;;
        --json) JSON_OUTPUT=true; AUTO_REFRESH=false; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# Colors (only for non-JSON output)
if [ "$JSON_OUTPUT" = false ]; then
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    RED='\033[0;31m'
    CYAN='\033[0;36m'
    MAGENTA='\033[0;35m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    GREEN=''
    YELLOW=''
    BLUE=''
    RED=''
    CYAN=''
    MAGENTA=''
    BOLD=''
    NC=''
fi

# Thresholds
WARN_CPU_PERCENT=60
ERROR_CPU_PERCENT=80
WARN_RAM_PERCENT=70
ERROR_RAM_PERCENT=85
WARN_RUNTIME_HOURS=6
ERROR_RUNTIME_HOURS=8
WARN_IDLE_MINUTES=30
ERROR_IDLE_MINUTES=60

# Cost calculation (Claude Max plan: €100/mo for ~225 messages/5hrs)
# Assumes typical agent uses ~45 messages per hour
COST_PER_AGENT_HOUR=0.40  # €0.40/hour approximate

# Directory paths
LOG_DIR="$HOME/agents/logs"
PROJECT_DIR="$HOME/projects/continuously-running-agents"

###############################################################################
# Helper Functions
###############################################################################

# Convert seconds to human-readable time
human_time() {
    local total_seconds=$1
    local hours=$((total_seconds / 3600))
    local minutes=$(((total_seconds % 3600) / 60))

    if [ $hours -gt 0 ]; then
        echo "${hours}h ${minutes}m"
    else
        echo "${minutes}m"
    fi
}

# Get color based on value and thresholds
get_color() {
    local value=$1
    local warn_threshold=$2
    local error_threshold=$3

    if (( $(echo "$value >= $error_threshold" | bc -l) )); then
        echo "$RED"
    elif (( $(echo "$value >= $warn_threshold" | bc -l) )); then
        echo "$YELLOW"
    else
        echo "$GREEN"
    fi
}

# Get status icon
get_status_icon() {
    local status=$1
    case "$status" in
        healthy) echo "✓" ;;
        warning) echo "⚠" ;;
        error) echo "✗" ;;
        *) echo "?" ;;
    esac
}

###############################################################################
# Data Collection Functions
###############################################################################

# Get agent process info
get_agent_process_info() {
    local agent_num=$1
    ps aux | grep -E "claude.*dangerously-skip.*agent-${agent_num}" | grep -v grep || echo ""
}

# Get tmux session info
get_session_info() {
    local session_name=$1
    if tmux has-session -t "$session_name" 2>/dev/null; then
        tmux list-sessions -F '#{session_name}:#{session_created}:#{session_activity}' 2>/dev/null | grep "^${session_name}:" || echo ""
    else
        echo ""
    fi
}

# Get recent commits by agent
get_recent_commits() {
    local hours=${1:-1}
    cd "$PROJECT_DIR" 2>/dev/null || return 0
    git log --since="${hours} hours ago" --author='renchris-agent' --oneline 2>/dev/null | wc -l || echo "0"
}

# Get open PRs
get_open_prs() {
    cd "$PROJECT_DIR" 2>/dev/null || return 0
    gh pr list 2>/dev/null | wc -l || echo "0"
}

# Get agent health status
get_agent_health() {
    local session_exists=$1
    local process_exists=$2
    local cpu_percent=$3
    local ram_percent=$4
    local idle_minutes=$5

    # Critical errors
    if [ "$session_exists" = false ] || [ "$process_exists" = false ]; then
        echo "error"
        return
    fi

    # Resource errors
    if (( $(echo "$cpu_percent >= $ERROR_CPU_PERCENT" | bc -l) )) || \
       (( $(echo "$ram_percent >= $ERROR_RAM_PERCENT" | bc -l) )) || \
       (( idle_minutes >= ERROR_IDLE_MINUTES )); then
        echo "error"
        return
    fi

    # Warnings
    if (( $(echo "$cpu_percent >= $WARN_CPU_PERCENT" | bc -l) )) || \
       (( $(echo "$ram_percent >= $WARN_RAM_PERCENT" | bc -l) )) || \
       (( idle_minutes >= WARN_IDLE_MINUTES )); then
        echo "warning"
        return
    fi

    echo "healthy"
}

###############################################################################
# Main Dashboard Function
###############################################################################

display_dashboard() {
    local current_time=$(date +%s)

    # Collect system-wide stats
    local total_ram_mb=$(free -m | grep Mem | awk '{print $2}')
    local used_ram_mb=$(free -m | grep Mem | awk '{print $3}')
    local ram_percent=$(free | grep Mem | awk '{printf "%.0f", ($3/$2)*100}')
    local disk_info=$(df -h / | tail -1)
    local disk_percent=$(echo "$disk_info" | awk '{print $5}' | tr -d '%')
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')

    # Find all agent sessions
    local agent_sessions=$(tmux list-sessions -F '#{session_name}' 2>/dev/null | grep '^prod-agent-' || echo "")
    local agent_count=$(echo "$agent_sessions" | grep -c 'prod-agent-' || echo "0")

    # JSON output structure
    if [ "$JSON_OUTPUT" = true ]; then
        echo "{"
        echo "  \"timestamp\": \"$(date -Iseconds)\","
        echo "  \"agents\": ["
    fi

    # Clear screen for regular output
    if [ "$JSON_OUTPUT" = false ]; then
        clear
        echo -e "${BOLD}${BLUE}╔════════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${BOLD}${BLUE}║                    PRODUCTION AGENT DASHBOARD                              ║${NC}"
        echo -e "${BOLD}${BLUE}╠════════════════════════════════════════════════════════════════════════════╣${NC}"
        echo -e "  ${CYAN}Timestamp:${NC}  $(date '+%Y-%m-%d %H:%M:%S')"
        echo -e "  ${CYAN}Refresh:${NC}    Every ${REFRESH_INTERVAL}s (Ctrl+C to exit)"
        echo -e "${BOLD}${BLUE}╚════════════════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
    fi

    # Agent monitoring
    local total_cost_hour=0
    local healthy_count=0
    local warning_count=0
    local error_count=0
    local first_agent=true

    if [ "$JSON_OUTPUT" = false ]; then
        echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${BOLD}${CYAN}║  AGENT STATUS                                                            ║${NC}"
        echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
    fi

    if [ -z "$agent_sessions" ] || [ "$agent_count" -eq 0 ]; then
        if [ "$JSON_OUTPUT" = false ]; then
            echo -e "  ${YELLOW}No agents currently running${NC}"
            echo ""
        fi
    else
        while IFS= read -r session_name; do
            [ -z "$session_name" ] && continue

            local agent_num="${session_name#prod-agent-}"

            # Get session info
            local session_info=$(get_session_info "$session_name")
            if [ -z "$session_info" ]; then
                continue
            fi

            local created=$(echo "$session_info" | cut -d: -f2)
            local activity=$(echo "$session_info" | cut -d: -f3)

            # Calculate runtime
            local runtime_seconds=$((current_time - created))
            local runtime_hours=$((runtime_seconds / 3600))
            local runtime_human=$(human_time $runtime_seconds)

            # Calculate idle time
            local idle_seconds=$((current_time - activity))
            local idle_minutes=$((idle_seconds / 60))
            local idle_human=$(human_time $idle_seconds)

            # Get process info
            local process_info=$(get_agent_process_info "$agent_num")
            local process_exists=true
            local cpu_percent=0
            local mem_percent=0
            local mem_mb=0
            local pid="N/A"

            if [ -n "$process_info" ]; then
                cpu_percent=$(echo "$process_info" | awk '{print $3}' | cut -d. -f1)
                mem_percent=$(echo "$process_info" | awk '{print $4}' | cut -d. -f1)
                mem_mb=$(echo "$process_info" | awk '{print $6/1024}' | cut -d. -f1)
                pid=$(echo "$process_info" | awk '{print $2}')
            else
                process_exists=false
            fi

            # Get recent activity
            local commits_1h=$(get_recent_commits 1)
            local commits_24h=$(get_recent_commits 24)

            # Calculate cost
            local agent_cost_hour=$COST_PER_AGENT_HOUR
            local agent_cost_total=$(echo "scale=2; $runtime_hours * $agent_cost_hour" | bc)
            total_cost_hour=$(echo "scale=2; $total_cost_hour + $agent_cost_hour" | bc)

            # Determine health status
            local health=$(get_agent_health true $process_exists $cpu_percent $mem_percent $idle_minutes)
            local health_icon=$(get_status_icon "$health")

            # Update counters
            case "$health" in
                healthy) healthy_count=$((healthy_count + 1)) ;;
                warning) warning_count=$((warning_count + 1)) ;;
                error) error_count=$((error_count + 1)) ;;
            esac

            # Get health color
            local health_color=$GREEN
            [ "$health" = "warning" ] && health_color=$YELLOW
            [ "$health" = "error" ] && health_color=$RED

            # JSON output
            if [ "$JSON_OUTPUT" = true ]; then
                [ "$first_agent" = false ] && echo ","
                first_agent=false
                cat <<EOF
    {
      "agent_number": $agent_num,
      "session_name": "$session_name",
      "health": "$health",
      "runtime": {
        "seconds": $runtime_seconds,
        "hours": $runtime_hours,
        "human": "$runtime_human"
      },
      "idle": {
        "seconds": $idle_seconds,
        "minutes": $idle_minutes,
        "human": "$idle_human"
      },
      "resources": {
        "cpu_percent": $cpu_percent,
        "ram_mb": $mem_mb,
        "ram_percent": $mem_percent,
        "pid": "$pid"
      },
      "activity": {
        "commits_1h": $commits_1h,
        "commits_24h": $commits_24h
      },
      "cost": {
        "per_hour": $agent_cost_hour,
        "total": $agent_cost_total
      }
    }
EOF
            else
                # Regular output with colors
                echo -e "${BOLD}  Agent #${agent_num}${NC} ${health_color}[${health_icon} ${health^^}]${NC}"
                echo -e "  ├─ Runtime:     ${runtime_human} ($([ $runtime_hours -ge $WARN_RUNTIME_HOURS ] && echo -n "${YELLOW}" || echo -n "${NC}")${runtime_hours}h${NC})"

                if [ "$process_exists" = true ]; then
                    local cpu_color=$(get_color $cpu_percent $WARN_CPU_PERCENT $ERROR_CPU_PERCENT)
                    local ram_color=$(get_color $mem_percent $WARN_RAM_PERCENT $ERROR_RAM_PERCENT)
                    echo -e "  ├─ Resources:   ${cpu_color}${cpu_percent}% CPU${NC}, ${ram_color}${mem_mb} MB RAM (${mem_percent}%)${NC}"
                    echo -e "  ├─ PID:         ${pid}"
                else
                    echo -e "  ├─ Resources:   ${RED}PROCESS NOT FOUND${NC}"
                fi

                local idle_color=$GREEN
                [ $idle_minutes -ge $WARN_IDLE_MINUTES ] && idle_color=$YELLOW
                [ $idle_minutes -ge $ERROR_IDLE_MINUTES ] && idle_color=$RED
                echo -e "  ├─ Last Active: ${idle_color}${idle_human} ago${NC}"

                echo -e "  ├─ Commits:     ${commits_1h} (1h) | ${commits_24h} (24h)"
                echo -e "  └─ Cost:        €${agent_cost_total} total (€${agent_cost_hour}/hour)"
                echo ""
            fi
        done <<< "$agent_sessions"
    fi

    # Close JSON agents array
    if [ "$JSON_OUTPUT" = true ]; then
        echo ""
        echo "  ],"
    fi

    # System resources
    if [ "$JSON_OUTPUT" = true ]; then
        local open_prs=$(get_open_prs)
        local recent_commits=$(get_recent_commits 2)

        cat <<EOF
  "system": {
    "ram": {
      "used_mb": $used_ram_mb,
      "total_mb": $total_ram_mb,
      "percent": $ram_percent
    },
    "disk": {
      "percent": $disk_percent
    },
    "load_average": $load_avg,
    "agents": {
      "total": $agent_count,
      "healthy": $healthy_count,
      "warning": $warning_count,
      "error": $error_count
    }
  },
  "work_output": {
    "open_prs": $open_prs,
    "commits_2h": $recent_commits
  },
  "cost": {
    "per_hour": $total_cost_hour,
    "per_day": $(echo "scale=2; $total_cost_hour * 24" | bc),
    "per_month": $(echo "scale=2; $total_cost_hour * 24 * 30" | bc)
  }
}
EOF
    else
        # Regular output
        echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${BOLD}${CYAN}║  SYSTEM RESOURCES                                                        ║${NC}"
        echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════════════════╝${NC}"
        echo ""

        local ram_color=$(get_color $ram_percent $WARN_RAM_PERCENT $ERROR_RAM_PERCENT)
        local disk_color=$(get_color $disk_percent 70 85)

        echo -e "  RAM:          ${ram_color}${used_ram_mb} MB / ${total_ram_mb} MB (${ram_percent}%)${NC}"
        echo -e "  Disk:         ${disk_color}${disk_percent}% used${NC}"
        echo -e "  Load Avg:     ${load_avg}"
        echo ""

        # Work output
        echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${BOLD}${CYAN}║  WORK OUTPUT                                                             ║${NC}"
        echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════════════════╝${NC}"
        echo ""

        local open_prs=$(get_open_prs)
        local recent_commits=$(get_recent_commits 2)

        echo -e "  Open PRs:     ${open_prs}"
        echo -e "  Commits (2h): ${recent_commits}"
        echo ""

        # Cost summary
        echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${BOLD}${CYAN}║  COST TRACKING (Claude Max Plan Estimate)                               ║${NC}"
        echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════════════════╝${NC}"
        echo ""

        local cost_day=$(echo "scale=2; $total_cost_hour * 24" | bc)
        local cost_month=$(echo "scale=2; $total_cost_hour * 24 * 30" | bc)

        echo -e "  Current Rate: ${BOLD}€${total_cost_hour}/hour${NC}"
        echo -e "  Projected:    €${cost_day}/day | €${cost_month}/month"
        echo -e "  ${CYAN}Note: Based on ~45 messages/hour per agent, Max plan limits${NC}"
        echo ""

        # Agent summary with health indicators
        echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${BOLD}${CYAN}║  SUMMARY                                                                 ║${NC}"
        echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════════════════╝${NC}"
        echo ""

        echo -e "  Total Agents: ${BOLD}$agent_count${NC}"
        echo -e "  ├─ ${GREEN}Healthy:${NC}  $healthy_count"
        echo -e "  ├─ ${YELLOW}Warning:${NC}  $warning_count"
        echo -e "  └─ ${RED}Error:${NC}    $error_count"
        echo ""

        # Alerts section
        if [ $warning_count -gt 0 ] || [ $error_count -gt 0 ]; then
            echo -e "${BOLD}${RED}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${BOLD}${RED}║  ALERTS                                                                  ║${NC}"
            echo -e "${BOLD}${RED}╚══════════════════════════════════════════════════════════════════════════╝${NC}"
            echo ""

            if [ $error_count -gt 0 ]; then
                echo -e "  ${RED}✗ ${error_count} agent(s) in ERROR state - immediate attention required${NC}"
            fi
            if [ $warning_count -gt 0 ]; then
                echo -e "  ${YELLOW}⚠ ${warning_count} agent(s) in WARNING state - check resource usage${NC}"
            fi
            if [ $ram_percent -ge $ERROR_RAM_PERCENT ]; then
                echo -e "  ${RED}✗ System RAM critical: ${ram_percent}%${NC}"
            elif [ $ram_percent -ge $WARN_RAM_PERCENT ]; then
                echo -e "  ${YELLOW}⚠ System RAM high: ${ram_percent}%${NC}"
            fi
            echo ""
        else
            echo -e "${GREEN}✓ All systems healthy - no alerts${NC}"
            echo ""
        fi

        echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════════════╗${NC}"
        if [ "$AUTO_REFRESH" = true ]; then
            echo -e "${BLUE}║ Refreshing in ${REFRESH_INTERVAL}s... (Ctrl+C to exit)                                     ║${NC}"
        else
            echo -e "${BLUE}║ Run without --no-refresh for auto-refresh                                 ║${NC}"
        fi
        echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════════════╝${NC}"
    fi
}

###############################################################################
# Main Loop
###############################################################################

if [ "$AUTO_REFRESH" = true ]; then
    while true; do
        display_dashboard
        sleep $REFRESH_INTERVAL
    done
else
    display_dashboard
fi
