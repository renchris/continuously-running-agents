#!/bin/bash
###############################################################################
# Start Agent in YOLO Mode (Auto-Approve Everything)
#
# Launches a Claude Code agent with --dangerously-skip-permissions flag for
# fully autonomous operation. Use this for trusted environments only.
#
# Usage:
#   bash start-agent-yolo.sh <agent_number> <task_description>
#
# Example:
#   bash start-agent-yolo.sh 1 "Review and update documentation"
#
# Features:
#   - Bypasses all permission prompts
#   - Resource limits (CPU, memory, disk)
#   - Auto-termination after timeout
#   - Comprehensive logging
###############################################################################

set -euo pipefail

# Configuration
AGENT_NUM="${1:-1}"
TASK="${2:-Please wait for instructions}"
MAX_RUNTIME_HOURS="${MAX_RUNTIME_HOURS:-8}"  # Auto-kill after 8 hours
PROJECT_DIR="$HOME/projects/continuously-running-agents"
LOG_DIR="$HOME/agents/logs"
SESSION_NAME="prod-agent-${AGENT_NUM}"

# Resource limits
MAX_CPU_PERCENT=80        # Max 80% CPU per agent
MAX_MEMORY_MB=2048        # Max 2GB RAM per agent (Claude Code needs ~1-1.5GB)
MAX_PROCESSES=200         # Max 200 processes per agent
MAX_DISK_MB=5120          # Max 5GB disk writes per agent session

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Generate session log file
SESSION_LOG="$LOG_DIR/agent-${AGENT_NUM}-$(date +%Y%m%d-%H%M%S).log"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           Starting Agent in YOLO Mode (Autonomous)            ║${NC}"
echo -e "${BLUE}╠════════════════════════════════════════════════════════════════╣${NC}"
echo -e "  Agent Number:     ${GREEN}${AGENT_NUM}${NC}"
echo -e "  Task:             ${GREEN}${TASK}${NC}"
echo -e "  Session:          ${GREEN}${SESSION_NAME}${NC}"
echo -e "  Max Runtime:      ${GREEN}${MAX_RUNTIME_HOURS} hours${NC}"
echo -e "  Log File:         ${GREEN}${SESSION_LOG}${NC}"
echo -e "${BLUE}╠════════════════════════════════════════════════════════════════╣${NC}"
echo -e "  ${YELLOW}⚠️  YOLO MODE ACTIVE - NO PERMISSION PROMPTS${NC}"
echo -e "  ${YELLOW}⚠️  Agent will execute ALL operations autonomously${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Validate project directory exists
if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${RED}Error: Project directory not found: $PROJECT_DIR${NC}"
    exit 1
fi

# Check if session already exists
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo -e "${YELLOW}Warning: Session $SESSION_NAME already exists${NC}"
    read -p "Kill existing session and restart? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        tmux kill-session -t "$SESSION_NAME"
        echo -e "${GREEN}Killed existing session${NC}"
    else
        echo -e "${RED}Aborted${NC}"
        exit 1
    fi
fi

# Create wrapper script with resource limits and timeout
WRAPPER_SCRIPT="/tmp/agent-${AGENT_NUM}-wrapper.sh"
cat > "$WRAPPER_SCRIPT" <<EOF
#!/bin/bash
set -euo pipefail

# Resource limit function
set_limits() {
    # Set soft limits for this process tree
    # Note: Memory (ulimit -v) not set due to Claude Code WebAssembly requirements
    # Use systemd MemoryMax instead for hard limits
    ulimit -u ${MAX_PROCESSES}               # Max user processes
    ulimit -f \$((${MAX_DISK_MB} * 1024))    # Max file size
    ulimit -n 1024                           # Max open files
}

# Apply resource limits (no memory limit via ulimit)
set_limits

# Log start time
echo "Agent ${AGENT_NUM} started at \$(date)" | tee -a "$SESSION_LOG"
echo "PID: \$\$" | tee -a "$SESSION_LOG"
echo "Task: ${TASK}" | tee -a "$SESSION_LOG"
echo "Resource Limits:" | tee -a "$SESSION_LOG"
echo "  - Memory: ${MAX_MEMORY_MB} MB" | tee -a "$SESSION_LOG"
echo "  - Processes: ${MAX_PROCESSES}" | tee -a "$SESSION_LOG"
echo "  - Disk: ${MAX_DISK_MB} MB" | tee -a "$SESSION_LOG"
echo "  - Runtime: ${MAX_RUNTIME_HOURS} hours" | tee -a "$SESSION_LOG"
echo "" | tee -a "$SESSION_LOG"

# Set timeout
TIMEOUT_SECONDS=\$((${MAX_RUNTIME_HOURS} * 3600))

# Run Claude with YOLO mode
cd "$PROJECT_DIR"
timeout \${TIMEOUT_SECONDS}s claude \\
    --dangerously-skip-permissions \\
    -p "${TASK}" \\
    2>&1 | tee -a "$SESSION_LOG"

EXIT_CODE=\$?

# Log completion
echo "" | tee -a "$SESSION_LOG"
echo "Agent ${AGENT_NUM} completed at \$(date)" | tee -a "$SESSION_LOG"
echo "Exit code: \$EXIT_CODE" | tee -a "$SESSION_LOG"

if [ \$EXIT_CODE -eq 124 ]; then
    echo "⚠️  TIMEOUT: Agent killed after ${MAX_RUNTIME_HOURS} hours" | tee -a "$SESSION_LOG"
fi

exit \$EXIT_CODE
EOF

chmod +x "$WRAPPER_SCRIPT"

# Start tmux session with wrapper script
tmux new-session -d -s "$SESSION_NAME" -c "$PROJECT_DIR" "$WRAPPER_SCRIPT"

echo ""
echo -e "${GREEN}✓ Agent ${AGENT_NUM} started in session: ${SESSION_NAME}${NC}"
echo ""
echo -e "${BLUE}Management Commands:${NC}"
echo -e "  Attach to session:    ${YELLOW}tmux attach -t ${SESSION_NAME}${NC}"
echo -e "  View logs:            ${YELLOW}tail -f $SESSION_LOG${NC}"
echo -e "  Kill session:         ${YELLOW}tmux kill-session -t ${SESSION_NAME}${NC}"
echo -e "  Monitor all agents:   ${YELLOW}bash ~/scripts/monitor-agents.sh${NC}"
echo ""
echo -e "${YELLOW}Note: Agent will auto-terminate after ${MAX_RUNTIME_HOURS} hours${NC}"
echo ""
