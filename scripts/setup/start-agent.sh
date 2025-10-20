#!/bin/bash

###############################################################################
# Claude Code Agent Startup Script
#
# This script starts a continuous Claude Code agent in a tmux session with
# proper logging, monitoring, and configuration.
#
# Usage:
#   bash start-agent.sh [session-name] [project-path] [task-description]
#
# Examples:
#   bash start-agent.sh                                    # Interactive mode
#   bash start-agent.sh main-agent ~/projects/webapp       # With project path
#   bash start-agent.sh frontend ~/projects/app "Build React components"
#
# Features:
#   - Creates persistent tmux session
#   - Sets up logging
#   - Configures monitoring windows
#   - Handles session conflicts
#   - Provides easy reattachment
###############################################################################

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_prompt() {
    echo -e "${BLUE}[INPUT]${NC} $1"
}

# Check if tmux is installed
check_tmux() {
    if ! command -v tmux &> /dev/null; then
        log_error "tmux is not installed. Please install it first."
        log_error "Run: sudo apt install tmux"
        exit 1
    fi
}

# Check if Claude Code is installed
check_claude() {
    if ! command -v claude &> /dev/null; then
        log_error "Claude Code CLI is not installed"
        log_error "Run: bash scripts/setup/02-install-claude.sh"
        exit 1
    fi
}

# Check if API key is set
check_api_key() {
    if [ -z "$ANTHROPIC_API_KEY" ]; then
        log_error "ANTHROPIC_API_KEY is not set"
        log_error "Please set your API key:"
        log_error "  export ANTHROPIC_API_KEY='your-key-here'"
        log_error "Or add it to ~/.bashrc and run: source ~/.bashrc"
        exit 1
    fi
}

# Get session name
get_session_name() {
    if [ -n "$1" ]; then
        echo "$1"
        return
    fi

    log_prompt "Enter session name (default: claude-agent):"
    read -r session_name
    echo "${session_name:-claude-agent}"
}

# Get project path
get_project_path() {
    if [ -n "$1" ]; then
        echo "$1"
        return
    fi

    log_prompt "Enter project path (default: ~/projects/main):"
    read -r project_path
    project_path="${project_path:-~/projects/main}"

    # Expand tilde
    project_path="${project_path/#\~/$HOME}"

    # Create if doesn't exist
    if [ ! -d "$project_path" ]; then
        log_warn "Directory doesn't exist: $project_path"
        read -p "Create it? (Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            mkdir -p "$project_path"
            cd "$project_path"
            git init
            log_info "Created and initialized: $project_path"
        fi
    fi

    echo "$project_path"
}

# Get task description
get_task_description() {
    if [ -n "$1" ]; then
        echo "$1"
        return
    fi

    log_prompt "Enter initial task for agent (press Enter for interactive mode):"
    read -r task_desc
    echo "$task_desc"
}

# Check if session already exists
check_existing_session() {
    local session=$1

    if tmux has-session -t "$session" 2>/dev/null; then
        log_warn "Session '$session' already exists"
        echo ""
        echo "Options:"
        echo "  1) Attach to existing session"
        echo "  2) Kill and recreate session"
        echo "  3) Choose different name"
        echo "  4) Cancel"
        echo ""
        read -p "Choose option (1-4): " -n 1 -r
        echo

        case $REPLY in
            1)
                log_info "Attaching to existing session..."
                tmux attach -t "$session"
                exit 0
                ;;
            2)
                log_info "Killing existing session..."
                tmux kill-session -t "$session"
                ;;
            3)
                log_prompt "Enter new session name:"
                read -r new_session
                echo "$new_session"
                return
                ;;
            4)
                log_info "Cancelled"
                exit 0
                ;;
            *)
                log_error "Invalid option"
                exit 1
                ;;
        esac
    fi

    echo "$session"
}

# Create log directory
setup_logging() {
    local session=$1
    local log_dir="$HOME/agents/logs"

    mkdir -p "$log_dir"

    # Create session-specific log file
    local log_file="$log_dir/${session}.log"
    touch "$log_file"

    log_info "Logs will be saved to: $log_file"
    echo "$log_file"
}

# Create tmux session with windows
create_agent_session() {
    local session=$1
    local project_path=$2
    local task_desc=$3
    local log_file=$4

    log_info "Creating tmux session: $session"

    # Create new detached session
    tmux new-session -d -s "$session" -c "$project_path"

    # Window 0: Main agent
    tmux rename-window -t "$session:0" 'agent'

    # Build Claude command
    local claude_cmd="claude"
    if [ -n "$task_desc" ]; then
        claude_cmd="claude -p '$task_desc'"
    fi

    # Start Claude with logging
    tmux send-keys -t "$session:0" "$claude_cmd 2>&1 | tee -a $log_file" C-m

    # Window 1: Logs viewer
    tmux new-window -t "$session:1" -n 'logs' -c "$HOME/agents/logs"
    tmux send-keys -t "$session:1" "tail -f $log_file" C-m

    # Window 2: System monitoring
    tmux new-window -t "$session:2" -n 'system' -c "$project_path"
    tmux send-keys -t "$session:2" "htop" C-m

    # Window 3: Git status
    tmux new-window -t "$session:3" -n 'git' -c "$project_path"
    tmux send-keys -t "$session:3" "git status" C-m

    # Split pane for git log
    tmux split-window -h -t "$session:3" -c "$project_path"
    tmux send-keys -t "$session:3.1" "git log --oneline --graph --all -20" C-m

    # Select main agent window
    tmux select-window -t "$session:0"

    log_info "Agent session created successfully"
}

# Print session info
print_session_info() {
    local session=$1
    local project_path=$2
    local log_file=$3

    echo ""
    log_info "======================================"
    log_info "Agent started successfully!"
    log_info "======================================"
    echo ""
    echo "Session: $session"
    echo "Project: $project_path"
    echo "Logs: $log_file"
    echo ""
    echo "Commands:"
    echo "  Attach:     tmux attach -t $session"
    echo "  Detach:     Ctrl+b, then d"
    echo "  Kill:       tmux kill-session -t $session"
    echo "  List all:   tmux ls"
    echo ""
    echo "Windows (Ctrl+b, then number to switch):"
    echo "  0: Agent (main Claude Code interface)"
    echo "  1: Logs (live log viewer)"
    echo "  2: System (htop monitoring)"
    echo "  3: Git (status and history)"
    echo ""
    log_prompt "Attach to session now? (Y/n):"
    read -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        log_info "Attaching to session..."
        tmux attach -t "$session"
    else
        log_info "Session is running in background"
        log_info "Attach later with: tmux attach -t $session"
    fi
}

# Save session info to file
save_session_info() {
    local session=$1
    local project_path=$2
    local task_desc=$3
    local log_file=$4

    local info_file="$HOME/agents/.sessions/${session}.info"
    mkdir -p "$(dirname "$info_file")"

    cat > "$info_file" <<EOF
{
  "session": "$session",
  "project_path": "$project_path",
  "task": "$task_desc",
  "log_file": "$log_file",
  "created": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "pid": $(tmux list-sessions -F '#{session_name} #{session_id}' | grep "^$session " | awk '{print $2}')
}
EOF

    log_info "Session info saved to: $info_file"
}

# Main execution
main() {
    log_info "Starting Claude Code Agent..."
    echo ""

    # Checks
    check_tmux
    check_claude
    check_api_key

    # Get parameters (from args or prompt)
    SESSION_NAME=$(get_session_name "$1")
    SESSION_NAME=$(check_existing_session "$SESSION_NAME")

    PROJECT_PATH=$(get_project_path "$2")
    TASK_DESC=$(get_task_description "$3")

    # Setup
    LOG_FILE=$(setup_logging "$SESSION_NAME")

    # Create session
    create_agent_session "$SESSION_NAME" "$PROJECT_PATH" "$TASK_DESC" "$LOG_FILE"

    # Save info
    save_session_info "$SESSION_NAME" "$PROJECT_PATH" "$TASK_DESC" "$LOG_FILE"

    # Print info and attach
    print_session_info "$SESSION_NAME" "$PROJECT_PATH" "$LOG_FILE"
}

# Run main function
main "$@"
