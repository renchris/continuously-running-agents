#!/bin/bash
###############################################################################
# Resume Monitoring - Conversation Starter
#
# Reads agent status files and generates a formatted report for pasting into
# a new Claude Code conversation. Bridges the gap across conversation boundaries.
#
# Usage:
#   bash ~/scripts/resume-monitoring.sh
#
# Output:
#   Human-readable status report with:
#   - Agent completion status
#   - Duration and resource usage
#   - PRs and files created
#   - Suggested next actions
#
# Workflow:
#   1. Run this script on the server
#   2. Copy the output
#   3. Paste into new Claude Code conversation
#   4. Claude can immediately see what happened and take action
###############################################################################

set -euo pipefail

# Configuration
STATUS_DIR="$HOME/agents/status"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Check if status directory exists
if [ ! -d "$STATUS_DIR" ]; then
    echo -e "${RED}✗ Status directory not found: $STATUS_DIR${NC}"
    echo ""
    echo "The agent completion watcher may not be running."
    echo "Start it with:"
    echo "  tmux new -d -s agent-watcher \"bash ~/scripts/monitoring/agent-completion-watcher.sh\""
    exit 1
fi

# Check if summary file exists
if [ ! -f "$STATUS_DIR/LATEST-RUN.json" ]; then
    echo -e "${YELLOW}⚠ No agent run data found${NC}"
    echo ""
    echo "No agents have been monitored yet."
    exit 0
fi

# Read summary
SUMMARY=$(cat "$STATUS_DIR/LATEST-RUN.json")
TIMESTAMP=$(echo "$SUMMARY" | jq -r '.timestamp')
TOTAL=$(echo "$SUMMARY" | jq -r '.summary.total_agents')
RUNNING=$(echo "$SUMMARY" | jq -r '.summary.running')
COMPLETED=$(echo "$SUMMARY" | jq -r '.summary.completed')
ERRORS=$(echo "$SUMMARY" | jq -r '.summary.errors')

# Header
echo ""
echo -e "${BOLD}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║          Agent Monitoring Status Report                        ║${NC}"
echo -e "${BOLD}╠════════════════════════════════════════════════════════════════╣${NC}"
echo ""
echo -e "${CYAN}Last Updated:${NC} $TIMESTAMP"
echo -e "${CYAN}Total Agents:${NC} $TOTAL"
echo ""

# Summary badges
echo -e "${BOLD}Status Summary:${NC}"
if [ "$RUNNING" -gt 0 ]; then
    echo -e "  🔄 ${YELLOW}$RUNNING running${NC}"
fi
if [ "$COMPLETED" -gt 0 ]; then
    echo -e "  ✅ ${GREEN}$COMPLETED completed${NC}"
fi
if [ "$ERRORS" -gt 0 ]; then
    echo -e "  ❌ ${RED}$ERRORS with errors${NC}"
fi
echo ""

# Agent details
echo -e "${BOLD}╠════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${BOLD}║ Agent Details                                                  ║${NC}"
echo -e "${BOLD}╠════════════════════════════════════════════════════════════════╣${NC}"
echo ""

# Process each agent
AGENT_COUNT=$(echo "$SUMMARY" | jq '.agents | length')

if [ "$AGENT_COUNT" -eq 0 ]; then
    echo -e "${YELLOW}No agents found${NC}"
else
    for i in $(seq 0 $((AGENT_COUNT - 1))); do
        AGENT=$(echo "$SUMMARY" | jq ".agents[$i]")

        AGENT_NUM=$(echo "$AGENT" | jq -r '.agent_number')
        STATUS=$(echo "$AGENT" | jq -r '.status')
        DURATION_SEC=$(echo "$AGENT" | jq -r '.duration_seconds')
        DURATION_MIN=$((DURATION_SEC / 60))
        CPU=$(echo "$AGENT" | jq -r '.resources.cpu_percent')
        RAM=$(echo "$AGENT" | jq -r '.resources.ram_mb')
        PEAK_CPU=$(echo "$AGENT" | jq -r '.resources.peak_cpu')
        PEAK_RAM=$(echo "$AGENT" | jq -r '.resources.peak_ram_mb')
        PRS=$(echo "$AGENT" | jq -r '.pr_created | join(", ")')
        FILES=$(echo "$AGENT" | jq -r '.files_created | join(", ")')

        # Status icon and color
        case "$STATUS" in
            "completed")
                STATUS_ICON="${GREEN}✅ COMPLETED${NC}"
                ;;
            "running")
                STATUS_ICON="${YELLOW}🔄 RUNNING${NC}"
                ;;
            "error")
                STATUS_ICON="${RED}❌ ERROR${NC}"
                ;;
            *)
                STATUS_ICON="${CYAN}● UNKNOWN${NC}"
                ;;
        esac

        echo -e "${BOLD}Agent $AGENT_NUM:${NC} $STATUS_ICON"
        echo -e "  Duration:  ${DURATION_MIN} minutes (${DURATION_SEC}s)"

        if [ "$STATUS" = "running" ]; then
            echo -e "  Resources: ${CPU}% CPU, ${RAM} MB RAM (current)"
            echo -e "  Peak:      ${PEAK_CPU}% CPU, ${PEAK_RAM} MB RAM"
        else
            echo -e "  Peak:      ${PEAK_CPU}% CPU, ${PEAK_RAM} MB RAM"
        fi

        if [ -n "$PRS" ] && [ "$PRS" != "" ]; then
            echo -e "  ${GREEN}PRs:${NC}       $PRS"
        fi

        if [ -n "$FILES" ] && [ "$FILES" != "" ]; then
            echo -e "  ${GREEN}Files:${NC}     $FILES"
        fi

        # Show errors if any
        ERROR_COUNT=$(echo "$AGENT" | jq '.errors | length')
        if [ "$ERROR_COUNT" -gt 0 ]; then
            echo -e "  ${RED}Errors:${NC}"
            echo "$AGENT" | jq -r '.errors[] | "    - \(.)"'
        fi

        echo ""
    done
fi

# Footer with suggested actions
echo -e "${BOLD}╠════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${BOLD}║ Suggested Next Actions                                        ║${NC}"
echo -e "${BOLD}╠════════════════════════════════════════════════════════════════╣${NC}"
echo ""

# Suggest actions based on status
if [ "$COMPLETED" -gt 0 ]; then
    echo -e "${GREEN}✓${NC} Review and merge completed agent PRs"
    echo -e "  ${CYAN}cd ~/projects/continuously-running-agents && gh pr list${NC}"
    echo ""
fi

if [ "$RUNNING" -gt 0 ]; then
    echo -e "${YELLOW}⏳${NC} Monitor running agents"
    echo -e "  ${CYAN}bash ~/scripts/monitor-agents-yolo.sh${NC}"
    echo ""
fi

if [ "$ERRORS" -gt 0 ]; then
    echo -e "${RED}⚠${NC}  Investigate agent errors"
    echo -e "  ${CYAN}Check logs in: ~/agents/logs/${NC}"
    echo ""
fi

if [ "$RUNNING" -eq 0 ] && [ "$TOTAL" -gt 0 ]; then
    echo -e "${BLUE}🚀${NC} Deploy new agents for next phase"
    echo -e "  ${CYAN}bash ~/scripts/start-agent-yolo.sh <N> \"<task>\"${NC}"
    echo ""
fi

# Resource status
echo -e "${BOLD}╠════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${BOLD}║ System Resources                                              ║${NC}"
echo -e "${BOLD}╠════════════════════════════════════════════════════════════════╣${NC}"
echo ""

MEM_USED=$(free -h | awk '/^Mem:/ {print $3}')
MEM_TOTAL=$(free -h | awk '/^Mem:/ {print $2}')
MEM_PERCENT=$(free | awk '/^Mem:/ {printf("%.1f%%"), ($3/$2) * 100}')

DISK_USED=$(df -h / | awk 'NR==2 {print $3}')
DISK_TOTAL=$(df -h / | awk 'NR==2 {print $2}')
DISK_PERCENT=$(df -h / | awk 'NR==2 {print $5}')

echo -e "  RAM:  ${MEM_USED} / ${MEM_TOTAL} (${MEM_PERCENT})"
echo -e "  Disk: ${DISK_USED} / ${DISK_TOTAL} (${DISK_PERCENT})"
echo ""

# Calculate capacity for more agents
MEM_AVAIL_GB=$(free -g | awk '/^Mem:/ {print $7}')
# Assume 220MB per agent
AGENTS_CAPACITY=$((MEM_AVAIL_GB * 1024 / 220))

if [ "$AGENTS_CAPACITY" -gt 0 ]; then
    echo -e "${GREEN}✓${NC} Capacity for approximately ${BOLD}${AGENTS_CAPACITY} more agents${NC}"
else
    echo -e "${YELLOW}⚠${NC} Low memory - consider killing stopped agents"
fi

echo ""

# Footer
echo -e "${BOLD}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Paste instructions
echo -e "${CYAN}${BOLD}📋 Usage in Claude Code:${NC}"
echo ""
echo "1. Copy this entire output"
echo "2. Start a new Claude Code conversation"
echo "3. Paste this output into the conversation"
echo "4. Claude will see the status and suggest next actions"
echo ""

# JSON export option
echo -e "${CYAN}For machine-readable format:${NC}"
echo "  cat $STATUS_DIR/LATEST-RUN.json | jq"
echo ""
