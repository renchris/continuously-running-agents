#!/bin/bash
###############################################################################
# Auto-Approve Agent Permissions
#
# Continuously sends approval commands to all running Claude agents to bypass
# permission prompts and allow autonomous operation.
#
# Usage:
#   bash auto-approve-agents.sh [duration_seconds]
#
# Example:
#   bash auto-approve-agents.sh 300  # Run for 5 minutes
###############################################################################

SERVER="claude-agent@5.78.152.238"
SSH_KEY="$HOME/.ssh/hetzner_claude_agent"
DURATION=${1:-300}  # Default 5 minutes
AGENTS=(1 2 3 4 5)

echo "Auto-approving agents for $DURATION seconds..."
echo "Press Ctrl+C to stop"
echo ""

START_TIME=$(date +%s)
ITERATION=0

while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))

    if [ $ELAPSED -ge $DURATION ]; then
        echo ""
        echo "✓ Completed $ITERATION iterations over $ELAPSED seconds"
        break
    fi

    ITERATION=$((ITERATION + 1))

    # Send Down+Enter to each agent to select "allow all" option
    for agent in "${AGENTS[@]}"; do
        ssh -i "$SSH_KEY" "$SERVER" \
            "tmux send-keys -t prod-agent-$agent Down Enter" 2>/dev/null
    done

    # Progress indicator
    if [ $((ITERATION % 10)) -eq 0 ]; then
        echo "  [$ELAPSED/${DURATION}s] Iteration $ITERATION - Sent approvals to ${#AGENTS[@]} agents"
    fi

    sleep 2
done

echo ""
echo "Checking final status..."
ssh -i "$SSH_KEY" "$SERVER" \
    "cd ~/projects/continuously-running-agents && gh pr list --limit 10"
