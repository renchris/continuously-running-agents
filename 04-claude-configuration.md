# Claude Code Configuration for Continuous Agents

## Overview

This guide covers how to configure Claude Code for autonomous, continuous operation based on community best practices and official features (March-October 2025).

## Latest Claude Models (2025)

### Model Timeline

- **Claude Sonnet 4.5** (Sept 29, 2025)
  - Best coding model in the world
  - Strongest for building complex agents
  - Can maintain focus for 30+ hours on tasks
  - Best at using computers

- **Claude Opus 4 & Sonnet 4** (May 22, 2025)
  - Enhanced agent capabilities
  - Improved long-running task handling

- **Claude 3.7 Sonnet** (Feb 24, 2025)
  - First major 2025 release
  - Improved agentic behavior

### Model Selection for Continuous Agents

```bash
# Use Sonnet 4.5 for autonomous agents (recommended)
claude --model claude-sonnet-4-5

# Use Opus 4 for critical reasoning tasks
claude --model claude-opus-4

# Use Haiku 3.5 for routine/simple tasks (cost-effective)
claude --model claude-haiku-3-5
```

## Claude Code CLI Installation

### Basic Installation

```bash
# Install globally
npm install -g @anthropic-ai/claude-code

# Verify installation
claude --version

# Set API key
export ANTHROPIC_API_KEY="your-api-key-here"

# Or add to ~/.bashrc / ~/.zshrc for persistence
echo 'export ANTHROPIC_API_KEY="your-key"' >> ~/.bashrc
source ~/.bashrc
```

### Alternative: Cursor CLI

```bash
# Install Cursor CLI (for subagent patterns)
curl https://cli.cursor.com -fsS | bash

# Verify
cursor-agent --version

# Configure API keys
cursor-agent config set anthropic_api_key YOUR_KEY
```

## Basic Claude Code Usage

### Interactive Mode

```bash
# Start interactive session
claude

# In project directory
cd /path/to/project
claude

# With specific model
claude --model claude-sonnet-4-5
```

### Chat Mode (Quick Questions)

```bash
# Single prompt
claude chat "explain this codebase structure"

# From Cursor
cursor-agent chat "find and fix the bug in auth.js"
```

### Prompt Mode (Autonomous Tasks)

```bash
# Execute task autonomously
claude -p "build a REST API for user management"

# With output format
cursor-agent -p "refactor database layer" --output-format=text

# Force auto-approve (dangerous!)
cursor-agent -p "fix all linting errors" --force
```

## Autonomous Operation Modes

### The --dangerously-skip-permissions Flag

**What it does**: Bypasses all permission prompts, allowing fully autonomous execution.

⚠️ **WARNING**: Claude can execute ANY command without asking.

```bash
# Enable dangerous mode
claude --dangerously-skip-permissions

# Or set in config
claude config set dangerously-skip-permissions true
```

**When to use**:
- ✅ Docker containers (isolated environment)
- ✅ Dedicated development VMs
- ✅ Well-scoped tasks with limited blast radius
- ✅ Monitored continuous agents with checkpoints

**When NOT to use**:
- ❌ Production servers
- ❌ Systems with sensitive data
- ❌ Shared development machines
- ❌ Without proper backups/checkpoints

### Safer Alternative: allowedTools Configuration

Granular control over which tools Claude can use without prompts:

```json
// In .claude/config.json
{
  "allowedTools": [
    "read",
    "write",
    "edit",
    "bash",
    "grep",
    "glob"
  ],
  "requireApprovalFor": [
    "bash:rm -rf",
    "bash:sudo",
    "git:push"
  ]
}
```

This provides autonomy while preventing destructive actions.

## Infinite Agent Loops

### Basic Loop Pattern

```bash
#!/bin/bash
# continuous-agent.sh

while true; do
    echo "Starting agent cycle at $(date)"

    claude -p "$(cat <<EOF
Continue working on the project.
Current goals:
- Implement remaining features from roadmap
- Fix any failing tests
- Update documentation as needed

Review progress and continue with next logical task.
EOF
)" --dangerously-skip-permissions

    # Check exit status
    if [ $? -ne 0 ]; then
        echo "Agent encountered error, waiting 60s before retry"
        sleep 60
    else
        echo "Cycle complete, waiting 5 minutes before next check-in"
        sleep 300
    fi
done
```

### Supervised Loop with Human Check-ins

```bash
#!/bin/bash
# supervised-agent-loop.sh

CHECKPOINT_INTERVAL=900  # 15 minutes

while true; do
    echo "=== Agent Cycle Started at $(date) ==="

    # Run agent with time limit
    timeout ${CHECKPOINT_INTERVAL} claude -p "Continue with next task. Before making major changes, create a checkpoint and summarize progress."

    # Notify and wait for approval
    echo "Agent paused for review. Check progress and press Enter to continue, or Ctrl+C to stop."
    read -t 60  # 60 second timeout

    if [ $? -eq 0 ]; then
        echo "Continuing..."
    else
        echo "Auto-continuing after timeout..."
    fi
done
```

### Self-Scheduling Agent (Tmux Orchestrator Pattern)

```bash
#!/bin/bash
# self-scheduling-agent.sh

SESSION="autonomous-agent"

# Create tmux session
tmux new-session -d -s $SESSION

# Send initial task
tmux send-keys -t $SESSION "claude -p \"$(cat <<EOF
You are an autonomous agent working on this project.

Schedule your own check-ins every 15 minutes.
For each check-in:
1. Review progress since last check-in
2. Plan next tasks
3. Execute planned work
4. Commit changes with descriptive messages
5. Schedule next check-in

Use the spec/ folder to understand project requirements.
Use the task-manager/ folder to track your progress.

Begin working autonomously.
EOF
)\" --dangerously-skip-permissions" C-m

echo "Autonomous agent started in tmux session: $SESSION"
echo "Attach with: tmux attach -t $SESSION"
```

## Loop Prevention and Recovery

### The Loop Detection Problem

Claude Code can get stuck in infinite loops:
- Repeatedly trying the same failed action
- Compaction loops when conversation is too long
- Error recovery loops

### Official Solutions

#### 1. Max Turns Flag

```bash
# Limit conversation turns
claude --max-turns 50 -p "complete this task"

# Prevents infinite conversations
# Forces agent to complete within limit
```

#### 2. Timeout Command

```bash
# Hard timeout after 2 hours
timeout 7200 claude -p "long running task"

# With grace period
timeout -k 60 7200 claude -p "task"
```

### Community Solutions

#### Loop Detection Service (Feature Request #4277)

Inspired by Google's Gemini CLI:

```python
# Conceptual implementation
class LoopDetector:
    def __init__(self, window_size=5):
        self.recent_tool_calls = []
        self.window_size = window_size

    def detect_loop(self, tool_call):
        self.recent_tool_calls.append(tool_call)

        # Keep only recent history
        if len(self.recent_tool_calls) > self.window_size:
            self.recent_tool_calls.pop(0)

        # Detect identical consecutive calls
        if len(self.recent_tool_calls) == self.window_size:
            if len(set(self.recent_tool_calls)) == 1:
                return True  # Loop detected!

        return False
```

#### Wrapper Script with Loop Detection

```bash
#!/bin/bash
# claude-with-loop-detection.sh

LOG_FILE="/tmp/claude-tool-calls.log"
MAX_IDENTICAL_CALLS=3

# Monitor Claude output for repeated patterns
claude "$@" 2>&1 | tee $LOG_FILE | while read line; do
    echo "$line"

    # Check for repeated tool calls (simplified)
    RECENT_CALLS=$(tail -n 10 $LOG_FILE | grep "Tool:" | tail -n 3)
    UNIQUE_CALLS=$(echo "$RECENT_CALLS" | sort -u | wc -l)

    if [ "$UNIQUE_CALLS" -eq 1 ] && [ -n "$RECENT_CALLS" ]; then
        echo "⚠️  Loop detected! Stopping agent..."
        pkill -P $$ claude
        exit 1
    fi
done
```

## Checkpoints and Recovery

### Official Checkpointing Feature

Claude Code now includes automatic checkpointing (released 2025):

```bash
# Checkpoints are automatic during sessions
# Rewind to previous state:
# Press Esc twice, or use:
/rewind

# Rewind options:
# - Restore code only
# - Restore conversation only
# - Restore both
```

### Manual Checkpoint Strategy

```bash
# Before starting autonomous work
git commit -am "Checkpoint before autonomous agent run"
git tag checkpoint-$(date +%Y%m%d-%H%M%S)

# After agent completes
git diff HEAD~1  # Review changes
git commit -am "Agent completed: [summary]"
```

### Automated Checkpointing in Loops

```bash
#!/bin/bash
# agent-with-checkpoints.sh

ITERATION=0

while true; do
    ITERATION=$((ITERATION + 1))

    # Create checkpoint
    git add -A
    git commit -m "Auto-checkpoint before iteration $ITERATION" 2>/dev/null

    # Run agent
    echo "=== Iteration $ITERATION at $(date) ==="

    claude -p "Continue working. Current iteration: $ITERATION" \
        --max-turns 20 \
        --dangerously-skip-permissions

    EXIT_CODE=$?

    # If agent failed, option to rollback
    if [ $EXIT_CODE -ne 0 ]; then
        echo "Agent failed. Rollback? (y/n)"
        read -t 30 ANSWER

        if [ "$ANSWER" = "y" ]; then
            git reset --hard HEAD~1
            echo "Rolled back to checkpoint"
        fi
    fi

    sleep 300  # 5 minute pause between iterations
done
```

## Subagent Patterns (from Eric Zakariasson)

### What Are Subagents?

Subagents are recursive agents where you can apply different prompts and models depending on the task.

### Cursor CLI Subagent Spawning

```bash
# In a Cursor agent, spawn subagents via shell:
cursor-agent -p "implement feature X" \
    --output-format=text \
    --force \
    --model sonnet-4

# Dynamic model selection:
# - Use gpt-5 for reasoning/planning
# - Use sonnet-4 for implementation
```

### Subagent Orchestration Pattern

```markdown
<!-- .cursor/rules/subagents.mdc -->

When you need to parallelize work:

1. Identify independent tasks
2. For each task, spawn a subagent:
   ```bash
   cursor-agent -p "[task description]" --model [appropriate-model] --force
   ```
3. Fan-out: Launch all subagents in parallel
4. Fan-in: Collect results and integrate
```

### Example: Parallel Feature Implementation

```bash
#!/bin/bash
# parallel-features.sh

# Define features
FEATURES=(
    "implement user authentication"
    "create REST API endpoints"
    "build admin dashboard"
)

# Spawn subagent for each feature
PIDS=()
for i in "${!FEATURES[@]}"; do
    (
        echo "Starting subagent $i: ${FEATURES[$i]}"
        cursor-agent -p "${FEATURES[$i]}" \
            --model sonnet-4 \
            --force \
            --output-format=text \
            > /tmp/subagent-$i.log 2>&1
    ) &
    PIDS+=($!)
done

# Wait for all subagents
echo "Waiting for ${#PIDS[@]} subagents to complete..."
for pid in "${PIDS[@]}"; do
    wait $pid
    echo "Subagent with PID $pid completed"
done

echo "All subagents finished!"
```

## Monitoring and Observability

### Logging Agent Activity

```bash
# Create log directory
mkdir -p ~/agent-logs

# Run with logging
claude -p "task" 2>&1 | tee ~/agent-logs/agent-$(date +%Y%m%d-%H%M%S).log

# Structured logging wrapper
claude -p "task" 2>&1 | while read line; do
    echo "[$(date -Iseconds)] $line" >> ~/agent-logs/structured.log
    echo "$line"
done
```

### Real-time Monitoring Dashboard

```bash
# In one tmux pane: run agent
tmux new-session -d -s agent
tmux send-keys -t agent "claude -p 'build app'" C-m

# In another pane: monitor logs
tmux split-window -v
tmux send-keys "tail -f ~/agent-logs/*.log" C-m

# In another pane: monitor system
tmux split-window -h
tmux send-keys "htop" C-m

# Attach to dashboard
tmux attach -t agent
```

### Progress Tracking

Create `task-progress.sh`:
```bash
#!/bin/bash
# Track agent progress

TASKS_FILE="tasks.json"

function update_task() {
    TASK_ID=$1
    STATUS=$2

    echo "Task $TASK_ID: $STATUS at $(date)" >> task-progress.log

    # Could integrate with task manager, Notion API, etc.
}

# Use in agent prompts:
# "Before starting each task, log progress using: bash task-progress.sh update [id] [status]"
```

## Configuration Best Practices

### Recommended .claude/config.json

```json
{
  "model": "claude-sonnet-4-5",
  "maxTurns": 100,
  "temperature": 0.7,
  "checkpointingEnabled": true,
  "allowedTools": [
    "read",
    "write",
    "edit",
    "grep",
    "glob"
  ],
  "restrictedCommands": {
    "bash": {
      "blocklist": [
        "rm -rf /",
        ":(){ :|:& };:",
        "dd if=/dev/zero"
      ]
    }
  },
  "autoCommit": false,
  "requireApprovalForGitPush": true
}
```

### Project-Specific Rules

```markdown
<!-- .claude/rules/autonomous-agent.md -->

You are operating as an autonomous agent on this project.

## Guidelines:
1. Create checkpoints before major changes
2. Run tests after each implementation
3. Commit working changes incrementally
4. Document significant decisions
5. Report errors clearly and attempt recovery
6. Request human intervention for ambiguous situations

## Task Management:
- Check spec/ folder for requirements
- Update task-manager/ with progress
- Schedule check-ins every 15 minutes

## Error Handling:
- Max 3 retry attempts for failing tests
- Rollback and report if unable to resolve
- Never skip failing tests

Begin working autonomously within these guidelines.
```

## Handling Stuck Agents

### Detection

```bash
# Monitor if agent is stuck (no file changes in 10 minutes)
watch -n 60 'find . -mmin -10 -type f | wc -l'

# Monitor API usage (should be steady if agent is working)
# Use Anthropic Console: https://console.anthropic.com/usage
```

### Recovery Strategies

1. **Gentle Interrupt**:
   ```bash
   # In Claude session, send new prompt:
   /clear
   # Then: "Summarize what you've accomplished and start fresh on next task"
   ```

2. **Hard Restart**:
   ```bash
   # Kill Claude process
   pkill -f claude

   # Restart with fresh context
   claude -p "Review recent changes and continue from where we left off"
   ```

3. **Rollback and Retry**:
   ```bash
   # Restore to last checkpoint
   git reset --hard checkpoint-tag

   # Try again with different approach
   claude -p "Previous attempt encountered issues. Try alternative approach: [specifics]"
   ```

## Pieter Levels' /workers/ Folder Pattern

### Philosophy: "Automate Everything, Hire No One"

Pieter Levels (@levelsio) runs a $3M/year startup empire with zero employees using 700-2,000 cron jobs on a single $40/month VPS.

**Core Principle**: Most maintenance tasks can be automated as scheduled scripts (he calls them "robots").

### The /workers/ Folder Structure

```
workers/
├── email/
│   ├── send_queue.php          # Process email queue every 5 min
│   ├── process_bounces.php     # Handle bounce notifications
│   └── cleanup_old.php          # Delete old emails
├── data/
│   ├── scrape_sources.php      # Scrape data from external sources
│   ├── update_cache.php        # Refresh cached data
│   └── sync_external.php       # Sync with third-party APIs
├── maintenance/
│   ├── backup_database.sh      # Daily database backups
│   ├── cleanup_logs.sh         # Remove old logs
│   └── optimize_images.php     # Compress and optimize images
└── reporting/
    ├── daily_stats.php         # Generate daily statistics
    ├── weekly_report.php       # Weekly summary emails
    └── alert_anomalies.php     # Alert on unusual patterns
```

### Implementation Pattern

**Traditional PHP Worker** (Pieter's original approach):
```php
<?php
// workers/email/send_queue.php

// Get unsent emails from database
$emails = getUnsentEmails(100); // Batch of 100

foreach ($emails as $email) {
    try {
        sendEmail($email);
        markAsSent($email['id']);
        logSuccess($email['id']);
    } catch (Exception $e) {
        logError($email['id'], $e->getMessage());
        incrementRetryCount($email['id']);
    }

    sleep(1); // Rate limiting
}

// Schedule in cron:
// */5 * * * * /usr/bin/php ~/workers/email/send_queue.php >> ~/logs/email-queue.log 2>&1
?>
```

**Modern AI-Enhanced Worker** (with Claude Code):
```bash
#!/bin/bash
# workers/smart_cleanup.sh
# AI-powered intelligent cleanup

cd ~/project

# Get statistics about temporary files
FILE_STATS=$(find . -name "*.log" -o -name "*.tmp" -o -name "*.cache" | \
    xargs ls -lh 2>/dev/null | \
    awk '{sum+=$5; count++} END {print count " files, total: " sum/1024/1024 " MB"}')

# Ask Claude for cleanup strategy
claude -p "I have $FILE_STATS of temporary/cache files in the project.

Please analyze and:
1. Identify which files are safe to delete
2. Suggest which old logs should be compressed
3. Identify files that should be kept for debugging
4. Execute the cleanup safely

Use Read and Glob tools to analyze first, then Edit or Bash to implement." \
    --allowedTools Read,Glob,Bash \
    --output-format json \
    >> ~/logs/smart-cleanup.log 2>&1
```

### Crontab Configuration

```bash
# Edit crontab
crontab -e

# Email workers (high frequency)
*/5 * * * * ~/workers/email/send_queue.php >> ~/logs/cron-email.log 2>&1

# Data workers (moderate frequency)
0 */6 * * * ~/workers/data/scrape_sources.php >> ~/logs/cron-data.log 2>&1
*/30 * * * * ~/workers/data/update_cache.php >> ~/logs/cron-cache.log 2>&1

# Maintenance workers (daily)
0 3 * * * ~/workers/maintenance/backup_database.sh >> ~/logs/cron-backup.log 2>&1
0 4 * * * ~/workers/maintenance/cleanup_logs.sh >> ~/logs/cron-cleanup.log 2>&1

# Reporting workers (scheduled)
0 8 * * * ~/workers/reporting/daily_stats.php >> ~/logs/cron-stats.log 2>&1
0 9 * * 1 ~/workers/reporting/weekly_report.php >> ~/logs/cron-weekly.log 2>&1

# AI-enhanced workers (periodic optimization)
0 2 * * * ~/workers/smart_cleanup.sh >> ~/logs/cron-smart.log 2>&1
0 5 * * 0 ~/workers/ai_code_review.sh >> ~/logs/cron-review.log 2>&1
```

### AI-Enhanced Workers Examples

**1. Smart Database Optimizer**:
```bash
#!/bin/bash
# workers/ai_optimize_db.sh

DB_STATS=$(mysql -e "SHOW TABLE STATUS" | tail -n +2)

claude -p "Database statistics:
$DB_STATS

Please:
1. Identify tables that need optimization
2. Suggest appropriate indexes
3. Recommend partitioning strategies
4. Execute safe optimizations

Focus on tables with high row count or data size." \
    --allowedTools Bash \
    >> ~/logs/db-optimization.log 2>&1
```

**2. Intelligent Log Analyzer**:
```bash
#!/bin/bash
# workers/analyze_errors.sh

# Get error summary from last 24 hours
ERROR_SUMMARY=$(grep -i "ERROR\|WARN\|FATAL" ~/logs/app-$(date +%Y%m%d).log | \
    head -n 100)

if [ -n "$ERROR_SUMMARY" ]; then
    claude -p "Application errors from last 24 hours:

$ERROR_SUMMARY

Please:
1. Categorize errors by type and severity
2. Identify patterns or recurring issues
3. Suggest root causes
4. Recommend fixes for top 3 issues
5. Create GitHub issues for critical problems

Provide actionable recommendations." \
        --allowedTools Read,Write \
        >> ~/logs/error-analysis.log 2>&1
fi
```

**3. Automated Code Quality Worker**:
```bash
#!/bin/bash
# workers/code_quality_check.sh

# Run only if there were commits in last 24 hours
RECENT_COMMITS=$(git log --since="24 hours ago" --oneline)

if [ -n "$RECENT_COMMITS" ]; then
    claude -p "Recent commits:
$RECENT_COMMITS

Please:
1. Review code changes from last 24 hours
2. Check for code quality issues
3. Identify potential bugs or vulnerabilities
4. Suggest improvements
5. Update tests if needed
6. Update documentation if public APIs changed

Focus on maintaining code quality standards." \
        --allowedTools Read,Edit,Bash \
        >> ~/logs/code-quality.log 2>&1
fi
```

### Hybrid Approach: Workers + Always-On Agents

Combine cron-scheduled workers with persistent agents:

```bash
#!/bin/bash
# workers/ensure_agent_running.sh
# Cron job to ensure main agent is always running

if ! tmux has-session -t main-agent 2>/dev/null; then
    echo "$(date): Main agent not running, starting..." >> ~/logs/agent-restarts.log

    tmux new-session -d -s main-agent \
        "cd ~/project && claude -p 'You are the main continuous agent.
        Monitor the project and respond to events.
        Check for:
        - Failed tests
        - Deployment issues
        - High error rates
        - Performance degradation

        Take corrective action when needed.' \
        --dangerously-skip-permissions"

    echo "$(date): Main agent restarted successfully" >> ~/logs/agent-restarts.log
fi

# Cron: */5 * * * * ~/workers/ensure_agent_running.sh
```

### Worker Best Practices

1. **Idempotency**: Workers should be safe to run multiple times
   ```bash
   # BAD: Assumes file doesn't exist
   echo "data" > output.txt

   # GOOD: Checks first
   if [ ! -f output.txt ]; then
       echo "data" > output.txt
   fi
   ```

2. **Logging**: Always log to dedicated files
   ```bash
   # Every worker should log
   echo "$(date): Starting worker" >> ~/logs/worker-name.log
   # ... work ...
   echo "$(date): Worker completed" >> ~/logs/worker-name.log
   ```

3. **Error Handling**: Graceful failure
   ```bash
   #!/bin/bash
   set -euo pipefail  # Exit on error

   trap 'echo "$(date): Worker failed at line $LINENO" >> ~/logs/errors.log' ERR
   ```

4. **Resource Limits**: Prevent runaway workers
   ```bash
   # Limit memory and CPU
   ulimit -v 1048576  # 1GB memory
   timeout 300 ~/workers/some-task.sh  # 5 minute max
   ```

5. **Lock Files**: Prevent concurrent execution
   ```bash
   #!/bin/bash
   LOCK_FILE="/tmp/worker-name.lock"

   if [ -f "$LOCK_FILE" ]; then
       echo "Worker already running, exiting"
       exit 0
   fi

   touch "$LOCK_FILE"
   trap "rm -f $LOCK_FILE" EXIT

   # Do work...
   ```

### Monitoring Workers

**Simple Status Dashboard**:
```bash
#!/bin/bash
# monitor-workers.sh

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║              Worker Status Dashboard                      ║"
echo "╠═══════════════════════════════════════════════════════════╣"

for log in ~/logs/cron-*.log; do
    NAME=$(basename $log .log | sed 's/cron-//')
    LAST_RUN=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" $log 2>/dev/null || stat -c "%y" $log 2>/dev/null | cut -d'.' -f1)
    ERRORS=$(grep -c "ERROR\|FAIL" $log 2>/dev/null || echo "0")

    printf "%-20s Last: %-16s Errors: %s\n" "$NAME" "$LAST_RUN" "$ERRORS"
done

echo "╚═══════════════════════════════════════════════════════════╝"

# Cron: 0 * * * * ~/monitor-workers.sh | mail -s "Worker Status" admin@example.com
```

### Scaling Workers

As your system grows:

1. **Level 1**: Single VPS, < 100 workers
   - Simple cron jobs
   - File-based logging
   - Basic monitoring

2. **Level 2**: Single VPS, 100-500 workers
   - Organized by category
   - Centralized logging
   - Status dashboard
   - Error alerting

3. **Level 3**: Single VPS, 500-2000 workers (Pieter Levels scale)
   - Worker management script
   - Database-backed queue system
   - Automated recovery
   - Performance monitoring

4. **Level 4**: Multiple VPS, distributed workers
   - Message queue (RabbitMQ, Redis)
   - Orchestration platform
   - High availability setup
   - Cost at this point may exceed Pieter's $40/mo!

### Advantages of Workers Pattern

✅ **Simple**: Just bash scripts and cron
✅ **Reliable**: Cron has decades of stability
✅ **Resource Efficient**: Workers only run when needed
✅ **Easy to Debug**: Each worker is independent
✅ **Scalable**: Proven to handle thousands of jobs
✅ **Cost Effective**: Single VPS can handle massive automation

### When to Use Workers vs Always-On Agents

**Use Workers (Cron Jobs)**:
- Scheduled tasks (backups, reports)
- Batch processing
- Periodic maintenance
- Data synchronization
- Low-frequency tasks

**Use Always-On Agents**:
- Real-time responses
- Interactive tasks
- Continuous monitoring
- Complex workflows requiring context
- Event-driven automation

**Best Approach**: Hybrid
- Workers handle scheduled tasks
- Workers ensure agents stay running
- Agents handle interactive/complex work
- Workers supplement agents with batch tasks

## Next Steps

1. Understand cost optimization → See `05-cost-optimization.md`
2. Implement security measures → See `06-security.md`
3. Review working examples → See `07-examples.md`

## References

- Anthropic Claude 3.7 Sonnet announcement (Feb 2025)
- Anthropic Claude Sonnet 4.5 release (Sept 2025)
- GitHub Issue #4277: Loop Detection Feature Request
- Eric Zakariasson's subagent pattern tweets
- Tmux Orchestrator autonomous agent setup
- Pieter Levels' automation philosophy and /workers/ pattern
- Community experiences with dangerous mode
