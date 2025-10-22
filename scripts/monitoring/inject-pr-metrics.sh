#!/bin/bash
###############################################################################
# PR Runtime Metrics Injection
#
# Extracts agent runtime metrics from status JSON and appends formatted
# markdown table to agent-created pull requests with actionable insights.
#
# Usage:
#   bash scripts/monitoring/inject-pr-metrics.sh <pr_number> <agent_number>
#   bash scripts/monitoring/inject-pr-metrics.sh 42 3
#
# Features:
#   - Extracts metrics from ~/agents/status/agent-{N}-status.json
#   - Formats as markdown table with duration, CPU/RAM peaks
#   - Adds actionable warnings (>1hr runtime, >1500MB RAM, restarts)
#   - Idempotent: won't inject metrics twice
#   - Auto-called by agent-completion-watcher.sh when PR detected
#
# Requirements:
#   - gh CLI authenticated
#   - jq for JSON parsing
#   - Agent status JSON file exists
###############################################################################

set -euo pipefail

# Configuration
STATUS_DIR="$HOME/agents/status"
PROJECT_DIR="$HOME/projects/continuously-running-agents"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] ✓${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] ⚠${NC} $*"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ✗${NC} $*"
}

# Usage
usage() {
    cat <<EOF
Usage: $0 <pr_number> <agent_number>

Arguments:
  pr_number     - GitHub PR number (e.g., 42)
  agent_number  - Agent number (e.g., 3)

Example:
  $0 42 3

EOF
    exit 1
}

# Validate arguments
if [ $# -ne 2 ]; then
    log_error "Invalid arguments"
    usage
fi

PR_NUMBER=$1
AGENT_NUMBER=$2
STATUS_FILE="$STATUS_DIR/agent-${AGENT_NUMBER}-status.json"

# Validate inputs
if ! [[ "$PR_NUMBER" =~ ^[0-9]+$ ]]; then
    log_error "PR number must be numeric: $PR_NUMBER"
    exit 1
fi

if ! [[ "$AGENT_NUMBER" =~ ^[0-9]+$ ]]; then
    log_error "Agent number must be numeric: $AGENT_NUMBER"
    exit 1
fi

if [ ! -f "$STATUS_FILE" ]; then
    log_error "Status file not found: $STATUS_FILE"
    exit 1
fi

# Change to project directory
cd "$PROJECT_DIR" || {
    log_error "Failed to cd to $PROJECT_DIR"
    exit 1
}

log "Injecting metrics for PR #$PR_NUMBER from agent-$AGENT_NUMBER"

# Check if PR exists and get current body
PR_BODY=$(gh pr view "$PR_NUMBER" --json body -q '.body' 2>/dev/null) || {
    log_error "Failed to fetch PR #$PR_NUMBER (does it exist?)"
    exit 1
}

# Check if metrics already injected
if echo "$PR_BODY" | grep -q "## 🤖 Agent Runtime Metrics"; then
    log_warning "Metrics already injected in PR #$PR_NUMBER - skipping"
    exit 0
fi

# Extract metrics from status JSON
STATUS_JSON=$(cat "$STATUS_FILE")

AGENT_NUM=$(echo "$STATUS_JSON" | jq -r '.agent_number')
SESSION=$(echo "$STATUS_JSON" | jq -r '.session')
STATUS=$(echo "$STATUS_JSON" | jq -r '.status')
STARTED=$(echo "$STATUS_JSON" | jq -r '.started')
COMPLETED=$(echo "$STATUS_JSON" | jq -r '.completed')
DURATION_SEC=$(echo "$STATUS_JSON" | jq -r '.duration_seconds')
EXIT_CODE=$(echo "$STATUS_JSON" | jq -r '.exit_code')
PEAK_CPU=$(echo "$STATUS_JSON" | jq -r '.resources.peak_cpu // 0')
PEAK_RAM=$(echo "$STATUS_JSON" | jq -r '.resources.peak_ram_mb // 0')
PR_LIST=$(echo "$STATUS_JSON" | jq -r '.pr_created | join(", ")')
FILES_LIST=$(echo "$STATUS_JSON" | jq -r '.files_created | join(", ")')

# Calculate duration in human-readable format
DURATION_MIN=$((DURATION_SEC / 60))
DURATION_HR=$((DURATION_MIN / 60))
DURATION_MIN_REMAINDER=$((DURATION_MIN % 60))

if [ "$DURATION_HR" -gt 0 ]; then
    DURATION_HUMAN="${DURATION_HR}h ${DURATION_MIN_REMAINDER}m"
else
    DURATION_HUMAN="${DURATION_MIN}m"
fi

# Format completed time
if [ "$COMPLETED" = "null" ] || [ -z "$COMPLETED" ]; then
    COMPLETED_HUMAN="In progress"
else
    COMPLETED_HUMAN="$COMPLETED"
fi

# Detect restart attempts (session kill + restart pattern)
# Check if there are multiple status files with same agent number but different timestamps
RESTART_COUNT=0
if [ -d "$STATUS_DIR" ]; then
    # Count status files for this agent (assuming backups exist)
    RESTART_COUNT=$(find "$STATUS_DIR" -name "agent-${AGENT_NUMBER}-status*.json" 2>/dev/null | wc -l)
    RESTART_COUNT=$((RESTART_COUNT - 1))  # Subtract current file
    if [ "$RESTART_COUNT" -lt 0 ]; then
        RESTART_COUNT=0
    fi
fi

# Build actionable insights
INSIGHTS=""
INSIGHT_COUNT=0

# Warning: >1hr runtime
if [ "$DURATION_MIN" -gt 60 ]; then
    INSIGHTS="${INSIGHTS}- ⚠️ **Long runtime detected** (${DURATION_HUMAN}): Consider breaking task into smaller chunks\n"
    ((INSIGHT_COUNT++))
fi

# Warning: >1500MB RAM
if [ "$PEAK_RAM" -gt 1500 ]; then
    INSIGHTS="${INSIGHTS}- ⚠️ **High memory usage** (${PEAK_RAM}MB peak): Agent may be processing large files or holding too much context\n"
    ((INSIGHT_COUNT++))
fi

# Warning: >80% CPU sustained
if awk "BEGIN {exit !($PEAK_CPU > 80)}"; then
    INSIGHTS="${INSIGHTS}- ⚠️ **High CPU usage** (${PEAK_CPU}% peak): Intensive computation detected\n"
    ((INSIGHT_COUNT++))
fi

# Warning: restarts detected
if [ "$RESTART_COUNT" -gt 0 ]; then
    INSIGHTS="${INSIGHTS}- ⚠️ **Agent restarts detected** (${RESTART_COUNT}x): Check logs for crash/timeout patterns\n"
    ((INSIGHT_COUNT++))
fi

# Warning: error status
if [ "$STATUS" = "error" ] || [ "$EXIT_CODE" = "1" ]; then
    INSIGHTS="${INSIGHTS}- ❌ **Agent terminated with errors**: Review logs for failure details\n"
    ((INSIGHT_COUNT++))
fi

# Success message if no warnings
if [ "$INSIGHT_COUNT" -eq 0 ]; then
    INSIGHTS="✅ No performance issues detected - agent executed efficiently"
fi

# Build metrics table in temp file
TMP_METRICS=$(mktemp)
cat > "$TMP_METRICS" <<EOF

---

## 🤖 Agent Runtime Metrics

Auto-generated performance data from agent-${AGENT_NUMBER} execution.

| Metric | Value |
|--------|-------|
| **Agent** | agent-${AGENT_NUMBER} (\`${SESSION}\`) |
| **Status** | ${STATUS} |
| **Started** | ${STARTED} |
| **Completed** | ${COMPLETED_HUMAN} |
| **Duration** | ${DURATION_HUMAN} (${DURATION_SEC}s) |
| **Peak CPU** | ${PEAK_CPU}% |
| **Peak RAM** | ${PEAK_RAM} MB |
| **Exit Code** | ${EXIT_CODE} |
| **Restart Attempts** | ${RESTART_COUNT} |

### 📊 Actionable Insights

${INSIGHTS}

### 📝 Deliverables

${PR_LIST:+**PRs Created**: $PR_LIST}
${FILES_LIST:+**Files Created**: $FILES_LIST}

---

*Metrics injected by [\`inject-pr-metrics.sh\`](../scripts/monitoring/inject-pr-metrics.sh)*
EOF

# Append current PR body and metrics to temp file
TMP_BODY=$(mktemp)
echo "$PR_BODY" > "$TMP_BODY"
cat "$TMP_METRICS" >> "$TMP_BODY"

# Update PR using --body-file to avoid heredoc issues
log "Updating PR #$PR_NUMBER with runtime metrics..."

gh pr edit "$PR_NUMBER" --body-file "$TMP_BODY" || {
    log_error "Failed to update PR #$PR_NUMBER"
    rm -f "$TMP_METRICS" "$TMP_BODY"
    exit 1
}

# Cleanup temp files
rm -f "$TMP_METRICS" "$TMP_BODY"

log_success "Successfully injected metrics into PR #$PR_NUMBER"
log "Duration: $DURATION_HUMAN | Peak CPU: $PEAK_CPU% | Peak RAM: ${PEAK_RAM}MB"

if [ "$INSIGHT_COUNT" -gt 0 ]; then
    log_warning "$INSIGHT_COUNT warning(s) detected - review insights in PR"
fi

exit 0
