#!/bin/bash

###############################################################################
# Multi-Agent Spawner Script
#
# Spawns multiple Claude Code agents with coordination enabled.
#
# Usage:
#   bash spawn-agents.sh [num-agents] [project-path]
#
# Examples:
#   bash spawn-agents.sh 5                        # Spawn 5 agents in default project
#   bash spawn-agents.sh 10 ~/projects/webapp     # Spawn 10 agents for webapp
#
# Features:
#   - Automatic task distribution
#   - Coordination between agents
#   - Staggered startup to avoid overload
#   - Health monitoring
###############################################################################

# Configuration
NUM_AGENTS=${1:-5}
PROJECT_PATH=${2:-$HOME/projects/main}
STAGGER_DELAY=5  # seconds between spawns

# Source coordination library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/agent-coordination.sh"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    if ! command -v tmux &> /dev/null; then
        log_error "tmux is not installed"
        exit 1
    fi

    if ! command -v claude &> /dev/null; then
        log_error "Claude Code CLI is not installed"
        exit 1
    fi

    if [ -z "$ANTHROPIC_API_KEY" ]; then
        log_error "ANTHROPIC_API_KEY is not set"
        exit 1
    fi

    if [ ! -d "$PROJECT_PATH" ]; then
        log_error "Project path does not exist: $PROJECT_PATH"
        exit 1
    fi

    log_info "Prerequisites check passed"
}

# Initialize coordination system
setup_coordination() {
    log_info "Setting up coordination system..."
    init_coordination
    log_info "Coordination system ready"
}

# Spawn single agent
spawn_agent() {
    local agent_id=$1
    local agent_name="agent-$agent_id"

    log_info "Spawning $agent_name..."

    # Create tmux session for agent
    tmux new-session -d -s "$agent_name" -c "$PROJECT_PATH"

    # Send agent command
    tmux send-keys -t "$agent_name" "
# Source coordination functions
source $SCRIPT_DIR/agent-coordination.sh

# Agent loop
while true; do
    echo '[$agent_name] Getting next task...'

    # Get next available task
    TASK_JSON=\$(get_next_task '$agent_name')

    if [ \$? -ne 0 ]; then
        echo '[$agent_name] No tasks available, waiting...'
        sleep 30
        continue
    fi

    # Extract task details
    FILE=\$(echo \"\$TASK_JSON\" | jq -r '.file')
    TASK=\$(echo \"\$TASK_JSON\" | jq -r '.task')
    TASK_ID=\$(echo \"\$TASK_JSON\" | jq -r '.id')

    echo '[$agent_name] Working on: \$FILE - \$TASK'

    # Execute task with Claude
    claude -p \"Task: \$TASK
File: \$FILE

Please complete this task and commit your changes when done.\" 2>&1 | tee ~/agents/logs/$agent_name.log

    # Get commit hash if git repo
    if [ -d .git ]; then
        COMMIT=\$(git log -1 --format=%H 2>/dev/null || echo 'no-commit')
    else
        COMMIT='no-git'
    fi

    # Mark as complete
    complete_work '$agent_name' \"\$FILE\" \"\$COMMIT\"

    # Remove from planned work
    jq \"map(select(.id != \\\"\$TASK_ID\\\"))\" \"$COORD_DIR/planned-work.json\" > \"$COORD_DIR/planned-work.json.tmp\"
    mv \"$COORD_DIR/planned-work.json.tmp\" \"$COORD_DIR/planned-work.json\"

    echo '[$agent_name] Task completed!'

    # Brief pause before next task
    sleep 10
done
" C-m

    log_info "$agent_name spawned in tmux session"
}

# Spawn all agents
spawn_all_agents() {
    log_info "Spawning $NUM_AGENTS agents..."

    for i in $(seq 1 $NUM_AGENTS); do
        spawn_agent $i

        # Stagger spawns to avoid overload
        if [ $i -lt $NUM_AGENTS ]; then
            log_info "Waiting ${STAGGER_DELAY}s before next spawn..."
            sleep $STAGGER_DELAY
        fi
    done

    log_info "All agents spawned successfully"
}

# Create monitoring dashboard
create_dashboard() {
    log_info "Creating monitoring dashboard..."

    tmux new-session -d -s agent-dashboard

    # Run monitoring script
    tmux send-keys -t agent-dashboard "
while true; do
    clear
    echo '╔════════════════════════════════════════════════════════════════╗'
    echo '║          Multi-Agent Dashboard                                 ║'
    echo '╠════════════════════════════════════════════════════════════════╣'
    echo ''

    # Source coordination functions
    source $SCRIPT_DIR/agent-coordination.sh

    # Show stats
    show_stats
    echo ''

    # Show active work
    check_active_work
    echo ''

    # Show planned work
    check_planned_work
    echo ''

    # Check for stale agents
    check_stale_agents
    echo ''

    echo '╠════════════════════════════════════════════════════════════════╣'
    echo '║ Press Ctrl+C to exit                                           ║'
    echo '╚════════════════════════════════════════════════════════════════╝'
    echo 'Refreshing in 10 seconds...'

    sleep 10
done
" C-m

    log_info "Dashboard created: tmux attach -t agent-dashboard"
}

# Add sample tasks (for testing)
add_sample_tasks() {
    log_info "Adding sample tasks..."

    add_task "src/auth.ts" "Implement user authentication" "high"
    add_task "src/api.ts" "Add rate limiting to API" "medium"
    add_task "src/database.ts" "Optimize database queries" "high"
    add_task "tests/integration.test.ts" "Add integration tests" "medium"
    add_task "docs/README.md" "Update documentation" "low"

    log_info "Sample tasks added"
}

# Print summary
print_summary() {
    echo ""
    log_info "======================================"
    log_info "Multi-Agent System Deployed!"
    log_info "======================================"
    echo ""
    echo "Configuration:"
    echo "  Agents: $NUM_AGENTS"
    echo "  Project: $PROJECT_PATH"
    echo "  Coordination: $COORD_DIR"
    echo ""
    echo "Commands:"
    echo "  Dashboard:  tmux attach -t agent-dashboard"
    echo "  Agent:      tmux attach -t agent-1"
    echo "  List all:   tmux ls"
    echo ""
    echo "Management:"
    echo "  Add task:   source $SCRIPT_DIR/agent-coordination.sh && add_task <file> <description> <priority>"
    echo "  Show stats: source $SCRIPT_DIR/agent-coordination.sh && show_stats"
    echo "  Check stale: source $SCRIPT_DIR/agent-coordination.sh && check_stale_agents"
    echo ""
    echo "To stop all agents:"
    echo "  for i in {1..$NUM_AGENTS}; do tmux kill-session -t agent-\$i; done"
    echo "  tmux kill-session -t agent-dashboard"
    echo ""
}

# Main execution
main() {
    log_info "Starting multi-agent system..."
    echo ""

    check_prerequisites
    setup_coordination
    add_sample_tasks
    spawn_all_agents
    create_dashboard

    print_summary
}

# Run main function
main
