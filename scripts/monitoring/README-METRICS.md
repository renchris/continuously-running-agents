# PR Runtime Metrics Injection System

Automated system for injecting agent performance metrics into pull requests with actionable insights.

## Overview

The PR metrics injection system automatically appends runtime performance data to agent-created pull requests, helping track resource usage patterns and identify optimization opportunities.

## Components

### 1. `inject-pr-metrics.sh`

Core script that extracts metrics from agent status JSON and formats them into markdown tables.

**Features:**
- Extracts comprehensive metrics from `~/agents/status/agent-{N}-status.json`
- Formats data as clean markdown tables
- Generates actionable insights with warnings
- Idempotent (won't inject twice)
- Works with any PR number and agent number

**Usage:**
```bash
bash scripts/monitoring/inject-pr-metrics.sh <pr_number> <agent_number>

# Example
bash scripts/monitoring/inject-pr-metrics.sh 42 3
```

**Metrics Collected:**
- Agent number and session ID
- Status (running/completed/error)
- Start and completion timestamps
- Duration (human-readable format)
- Peak CPU usage (percentage)
- Peak RAM usage (MB)
- Exit code
- Restart attempt count
- PRs created by agent
- Files created by agent

### 2. Integration with `agent-completion-watcher.sh`

Automatic PR detection and metrics injection when agents create pull requests.

**How it Works:**
1. Watcher monitors agent status files every 60 seconds
2. Detects new PRs in `pr_created` array
3. Calls `inject-pr-metrics.sh` automatically
4. Marks injection as complete in status JSON
5. Prevents duplicate injections via idempotency check

**Logs:**
- Standard output: Real-time injection status
- `~/agents/logs/metrics-injection.log`: Detailed injection logs

## Actionable Insights

The system automatically generates warnings for common performance issues:

### Runtime Warnings

| Threshold | Warning | Recommendation |
|-----------|---------|----------------|
| >1 hour | ⚠️ Long runtime detected | Break task into smaller chunks |
| >1500MB RAM | ⚠️ High memory usage | Review context size, reduce file processing |
| >80% CPU | ⚠️ High CPU usage | Intensive computation detected |
| >0 restarts | ⚠️ Agent restarts detected | Check logs for crash/timeout patterns |
| Error status | ❌ Agent terminated with errors | Review logs for failure details |

### No Issues
If all metrics are within normal ranges:
```
✅ No performance issues detected - agent executed efficiently
```

## Example Output

The injected metrics appear at the bottom of the PR description:

```markdown
---

## 🤖 Agent Runtime Metrics

Auto-generated performance data from agent-3 execution.

| Metric | Value |
|--------|-------|
| **Agent** | agent-3 (`prod-agent-3`) |
| **Status** | completed |
| **Started** | 2025-10-22T01:30:00Z |
| **Completed** | 2025-10-22T03:15:42Z |
| **Duration** | 1h 45m (6342s) |
| **Peak CPU** | 78.5% |
| **Peak RAM** | 1623 MB |
| **Exit Code** | 0 |
| **Restart Attempts** | 0 |

### 📊 Actionable Insights

- ⚠️ **High memory usage** (1623MB peak): Agent may be processing large files or holding too much context

### 📝 Deliverables

**Files Created**: documentation.md, config.yaml

---

*Metrics injected by [`inject-pr-metrics.sh`](../scripts/monitoring/inject-pr-metrics.sh)*
```

## Status JSON Schema

The system expects agent status files at `~/agents/status/agent-{N}-status.json`:

```json
{
  "agent_number": 3,
  "session": "prod-agent-3",
  "status": "completed",
  "started": "2025-10-22T01:30:00Z",
  "completed": "2025-10-22T03:15:42Z",
  "duration_seconds": 6342,
  "pr_created": ["#42"],
  "files_created": ["documentation.md"],
  "exit_code": 0,
  "errors": [],
  "resources": {
    "cpu_percent": 45.2,
    "ram_mb": 892,
    "peak_cpu": 78.5,
    "peak_ram_mb": 1623
  },
  "metrics_injected": false
}
```

## Idempotency

The system prevents duplicate metrics injection via two mechanisms:

1. **PR Body Check**: Searches for "## 🤖 Agent Runtime Metrics" header
2. **Status File Flag**: Sets `metrics_injected: true` after successful injection

If metrics already exist, the script exits with a warning:
```
⚠ Metrics already injected in PR #42 - skipping
```

## Manual Injection

While the system auto-injects via the watcher, you can manually inject metrics:

```bash
# Get PR number and agent number
gh pr list

# Inject metrics
bash scripts/monitoring/inject-pr-metrics.sh 42 3

# Verify injection
gh pr view 42 | grep "Agent Runtime Metrics"
```

## Troubleshooting

### Metrics Not Appearing

1. **Check status file exists:**
   ```bash
   ls -la ~/agents/status/agent-3-status.json
   ```

2. **Verify PR number:**
   ```bash
   gh pr list
   ```

3. **Check injection logs:**
   ```bash
   tail -50 ~/agents/logs/metrics-injection.log
   ```

4. **Test manually:**
   ```bash
   bash -x scripts/monitoring/inject-pr-metrics.sh 42 3
   ```

### Injection Fails

**Common causes:**
- Status file doesn't exist
- PR doesn't exist
- `gh` CLI not authenticated
- Missing `jq` dependency
- Metrics already injected

**Debug steps:**
```bash
# Verify gh auth
gh auth status

# Check jq installed
which jq

# Validate status JSON
cat ~/agents/status/agent-3-status.json | jq .

# Check PR exists
gh pr view 42
```

## Performance Impact

- **CPU Usage**: <0.1% (metrics extraction and formatting)
- **Memory**: <10MB (temp file operations)
- **Network**: Single API call to GitHub (PR edit)
- **Execution Time**: 1-3 seconds per injection

## Integration with Existing Monitoring

The metrics system complements existing monitoring tools:

| Tool | Purpose | Metrics System Role |
|------|---------|---------------------|
| `agent-completion-watcher.sh` | Real-time agent monitoring | PR detection trigger |
| `resource-stats.sh` | Resource usage tracking | Data source (status JSON) |
| `dashboard.sh` | Live dashboard display | Provides historical PR data |
| `cost-tracker.sh` | Cost analysis | Runtime data for cost correlation |

## Future Enhancements

Potential improvements:

- [ ] Graph generation (CPU/RAM over time)
- [ ] Historical metrics comparison
- [ ] Cost per PR calculation
- [ ] Slack/Discord notifications for warnings
- [ ] PR comment threading instead of body append
- [ ] Multi-agent collaboration metrics
- [ ] Token usage tracking (when available via API)

## Related Documentation

- `agent-completion-watcher.sh` - Status JSON format and agent monitoring
- `05-cost-optimization.md` - Resource usage optimization strategies
- `ACTUAL-DEPLOYMENT-COSTS.md` - Real-world cost analysis
- `07-examples.md` - Production deployment patterns

---

**Last Updated**: 2025-10-22
