# Cost Optimization for Continuous Agents

## Overview

Running Claude Code agents continuously can incur significant costs if not managed properly. This guide provides strategies to optimize costs while maintaining agent effectiveness (based on 2025 pricing and best practices).

## Claude Pricing Structure (2025)

### API Pricing (Per Million Tokens)

| Model | Input | Output | Cache Write (5min) | Cache Write (1hr) | Cache Hit |
|-------|-------|--------|-------------------|-------------------|-----------|
| **Sonnet 4** | $3 | $15 | $3.75 | $6 | $0.30 |
| **Opus 4/4.1** | $15 | $75 | $18.75 | $30 | $1.50 |
| **Haiku 3.5** | $0.80 | $4 | $1.00 | $1.60 | $0.08 |

### Subscription Plans

| Plan | Cost/Month | Usage Limit | Best For |
|------|-----------|-------------|----------|
| **Free** | $0 | Very limited | Testing |
| **Pro** | $20 | ~45 messages/5hrs | Light development |
| **Max** | $100 | 5x Pro (~unlimited) | Heavy use, continuous agents |
| **Max+** | $200 | 20x Pro | Very heavy use |

**Max Plan Advantages**:
- ✅ **Essentially unlimited usage** for most continuous agent workloads
- ✅ **Very high rate limits** - Support 20-50+ parallel agents on single API key
- ✅ **Predictable costs** - $100/mo regardless of token usage
- ✅ **One key for all agents** - No need for multiple subscriptions
- ✅ **Best value for 24/7 agents** - Pays for itself vs API at ~$100 usage/month

### Key Insights

- **Cache hits cost 90% less** than regular input
- **Batch API provides 50% discount** (both input/output)
- **Prompt caching** is critical for continuous agents
- **Fixed-cost subscriptions** better for heavy users
- **One API key serves unlimited agents** - No need for multiple subscriptions

### API Key Management

**Do you need multiple API keys?**

**No, in most cases** - A single API key can:
- Serve unlimited parallel agents
- Work across multiple VMs
- Handle 20-50+ simultaneous sessions
- Aggregate all usage for cost tracking

**Only use multiple API keys when**:
- ❌ **Multiple customers/projects** - Need separate billing
- ❌ **Different teams** - Want isolated cost tracking
- ❌ **Hit rate limits** - Rare with Max subscription
- ❌ **Testing vs production** - Want to separate environments

**Common misconception**: "I need a separate $20 Pro subscription per agent"
**Reality**: One Max $100 subscription serves all your agents at once.

**Example**:
```bash
# ❌ Wasteful: 5 Pro subscriptions = $100/mo for 5 agents
export API_KEY_1="sk-ant-agent1"  # $20
export API_KEY_2="sk-ant-agent2"  # $20
export API_KEY_3="sk-ant-agent3"  # $20
# ... etc

# ✅ Better: 1 Max subscription = $100/mo for 20+ agents
export ANTHROPIC_API_KEY="sk-ant-main"  # $100
# All agents use this same key
```

## Cost Calculation Examples

### Scenario 1: Moderate Continuous Agent

**Setup**:
- 10 hours/day active coding
- Average 500 input + 200 output tokens per turn
- 10 turns per hour
- Using Sonnet 4

**Daily Cost (No optimization)**:
```
Input:  10 hrs × 10 turns × 500 tokens = 50,000 tokens
Output: 10 hrs × 10 turns × 200 tokens = 20,000 tokens

Input cost:  0.05M × $3 = $0.15
Output cost: 0.02M × $15 = $0.30
Total: $0.45/day = $13.50/month
```

**With Prompt Caching (90% cache hits)**:
```
Cache misses: 10% × 0.05M × $3 = $0.015
Cache hits:   90% × 0.05M × $0.30 = $0.0135
Output: $0.30 (unchanged)

Total: $0.33/day = $9.90/month
26% savings!
```

### Scenario 2: Heavy Continuous Agent (24/7)

**Setup**:
- 24/7 operation
- 5 turns per hour
- 1000 input + 400 output tokens per turn
- Using Sonnet 4

**Monthly Cost (No optimization)**:
```
Input:  24 × 30 × 5 × 1000 = 3.6M tokens = $10.80
Output: 24 × 30 × 5 × 400 = 1.44M tokens = $21.60
Total: $32.40/month
```

**With All Optimizations**:
```
1. Prompt caching (90% hit rate):
   Input: $10.80 → $1.08 + $0.97 = $2.05

2. Use Haiku for 50% of tasks:
   Input: $2.05 × 0.5 + ($2.05 × 0.5 × 0.27) = $1.30
   Output: $21.60 × 0.5 + ($21.60 × 0.5 × 0.27) = $13.70

3. Batch API (50% discount on batchable work - 30%):
   Further ~15% reduction

Estimated total: $12-15/month
50% savings!
```

**Recommendation**: At this usage, consider **Max subscription ($100/mo)** for unlimited usage.

## Optimization Strategies

### 1. Prompt Caching (CRITICAL)

Prompt caching reduces costs by 90% for repeated context.

#### How It Works

- System prompts and common context cached for 5 minutes or 1 hour
- Cache writes cost 1.25-2× base input
- Cache hits cost 0.1× base input
- **ROI**: After 2-10 cache hits, you break even

#### Implementation

```python
# Example API call with caching
import anthropic

client = anthropic.Anthropic()

# Mark parts of prompt for caching
response = client.messages.create(
    model="claude-sonnet-4",
    max_tokens=1024,
    system=[
        {
            "type": "text",
            "text": "You are an autonomous coding agent...",
            "cache_control": {"type": "ephemeral"}  # Cache this!
        }
    ],
    messages=[
        {"role": "user", "content": "Continue working on the project"}
    ]
)
```

#### Best Practices

```bash
# Cache these elements:
✅ System prompts (rarely change)
✅ Project documentation
✅ Code style guidelines
✅ Large file contents
✅ Common context

# Don't cache:
❌ User queries (always different)
❌ Unique one-time instructions
❌ Rapidly changing data
```

#### For Continuous Agents

```python
# Structure prompts to maximize caching:

CACHED_SYSTEM_CONTEXT = """
[Project documentation - 10KB]
[Code style guide - 2KB]
[Architecture overview - 5KB]
"""  # This gets cached

VARIABLE_CONTEXT = """
Current task: {current_task}
Recent changes: {recent_changes}
"""  # This changes each turn
```

### 2. Model Selection

Use the right model for each task:

| Task Type | Recommended Model | Cost (vs Sonnet 4) |
|-----------|------------------|-------------------|
| Routine refactoring | Haiku 3.5 | 73% cheaper |
| Standard features | Sonnet 4 | Baseline |
| Complex architecture | Opus 4 | 5× more expensive |
| Simple fixes | Haiku 3.5 | 73% cheaper |
| Planning/reasoning | Sonnet 4.5 | Baseline |

#### Dynamic Model Switching

```bash
#!/bin/bash
# smart-agent.sh

TASK_TYPE=$1

case $TASK_TYPE in
    "simple"|"fix"|"refactor")
        MODEL="claude-haiku-3-5"
        ;;
    "feature"|"implementation")
        MODEL="claude-sonnet-4"
        ;;
    "architecture"|"planning")
        MODEL="claude-opus-4"
        ;;
    *)
        MODEL="claude-sonnet-4"
        ;;
esac

claude --model $MODEL -p "task details"
```

#### Subagent Model Assignment (Eric Zakariasson Pattern)

```bash
# Planning agent: Use GPT-5 or Opus 4
cursor-agent -p "analyze architecture and create plan" --model opus-4

# Implementation agents: Use Sonnet 4
for task in "${TASKS[@]}"; do
    cursor-agent -p "$task" --model sonnet-4 &
done

# Testing agent: Use Haiku 3.5
cursor-agent -p "run tests and report" --model haiku-3-5
```

### 3. Context Management

Reducing context size = lower costs.

#### Use /clear Command

```bash
# In Claude session, after completing a task:
/clear

# Wipes short-term memory, keeps project context
# Reduces token usage on subsequent turns
```

#### Structured Context Windowing

```bash
# Instead of: "here's all 100 files in the project"
# Use: "here are the 3 files relevant to this task"

# Agent prompt should include:
"Focus on relevant files only. Don't load entire codebase unless necessary."
```

#### Git-Based Context

```bash
# Provide only recent changes as context:
RECENT_CHANGES=$(git diff HEAD~5..HEAD)

claude -p "Review these recent changes and continue: $RECENT_CHANGES"

# Cheaper than loading full project every time
```

### 4. Batch API (50% Discount)

For non-urgent tasks, use Batch API.

#### When to Use

✅ Generating test cases
✅ Code documentation
✅ Batch refactoring
✅ Non-interactive analysis
✅ Overnight processing

❌ Interactive development
❌ Real-time debugging
❌ Immediate responses needed

#### Implementation

```python
import anthropic

client = anthropic.Anthropic()

# Create batch request
batch = client.batches.create(
    requests=[
        {
            "custom_id": "test-gen-1",
            "params": {
                "model": "claude-sonnet-4",
                "max_tokens": 1024,
                "messages": [
                    {"role": "user", "content": "Generate tests for auth.js"}
                ]
            }
        },
        # ... more requests
    ]
)

# Process results later (50% cheaper!)
```

### 5. Subscription vs Pay-As-You-Go

#### Decision Matrix

| Monthly API Cost | Recommendation |
|-----------------|----------------|
| < $20 | Stay on pay-as-you-go |
| $20-40 | Consider Pro ($20) |
| $40-100 | Consider Max ($100) |
| $100-200 | Definitely Max ($100-200) |
| > $200 | Enterprise or optimize usage |

#### Break-Even Analysis

**Pro Plan ($20/mo)**:
- Unlimited messages (with rate limits)
- Breaks even at ~$20 API usage
- Best for: predictable moderate use

**Max Plan ($100/mo)**:
- 5-20× Pro usage
- Breaks even at ~$100 API usage
- Best for: heavy continuous agents

**Example**:
```
If your continuous agent costs $50/mo on API:
→ Switch to Max plan ($100)
→ Get unlimited usage
→ Run 2× more agents at no extra cost
```

### 6. Rate Limit Management

Avoid wasted API calls hitting rate limits.

```bash
# Exponential backoff on rate limits
function call_with_backoff() {
    DELAY=1
    MAX_RETRIES=5

    for i in $(seq 1 $MAX_RETRIES); do
        claude "$@" && break

        echo "Rate limited, waiting ${DELAY}s..."
        sleep $DELAY
        DELAY=$((DELAY * 2))
    done
}
```

### 7. Monitoring and Alerting

Track costs in real-time to avoid surprises.

#### Using Anthropic Console

```
1. Visit https://console.anthropic.com/usage
2. Monitor daily/weekly usage
3. Set up budget alerts
4. Review usage by workspace
```

#### API-Based Monitoring

```python
# Check usage via API
import anthropic

client = anthropic.Anthropic()

# Get usage stats
usage = client.usage.get(
    start_date="2025-10-01",
    end_date="2025-10-15"
)

# Alert if > budget
MONTHLY_BUDGET = 100  # dollars
if usage.total_cost > MONTHLY_BUDGET:
    send_alert("Budget exceeded!")
```

#### Simple Shell Monitoring

```bash
#!/bin/bash
# cost-monitor.sh

LOG_FILE=~/agent-logs/api-calls.log

# Log each API call
echo "$(date) - API call" >> $LOG_FILE

# Count calls today
CALLS_TODAY=$(grep "$(date +%Y-%m-%d)" $LOG_FILE | wc -l)

# Estimate cost (rough)
ESTIMATED_COST=$(echo "$CALLS_TODAY * 0.02" | bc)

echo "Calls today: $CALLS_TODAY"
echo "Estimated cost: \$$ESTIMATED_COST"

# Alert if high
if (( $(echo "$ESTIMATED_COST > 10" | bc -l) )); then
    echo "⚠️  High usage today!"
fi
```

## Cost Optimization Checklist

### Before Starting Continuous Agent

- [ ] Enable prompt caching in system prompts
- [ ] Choose appropriate model (Haiku for simple tasks)
- [ ] Set max-turns limit to prevent runaway costs
- [ ] Configure /clear to run periodically
- [ ] Set up cost monitoring
- [ ] Decide: subscription vs pay-as-you-go

### During Operation

- [ ] Monitor daily costs via console
- [ ] Review cache hit rates
- [ ] Identify opportunities to use Haiku instead of Sonnet
- [ ] Batch non-urgent tasks for 50% discount
- [ ] Use /clear after completing independent tasks
- [ ] Check for infinite loops (waste money)

### Weekly Review

- [ ] Analyze cost breakdown by model
- [ ] Review cache efficiency
- [ ] Identify cost spikes and causes
- [ ] Adjust model selection strategy
- [ ] Consider switching to subscription if cost growing

## Advanced Optimization: Hybrid Approach

Combine multiple strategies for maximum savings:

```bash
#!/bin/bash
# hybrid-cost-optimized-agent.sh

TASK_PRIORITY=$1  # high, medium, low

case $TASK_PRIORITY in
    "high")
        # High priority: Sonnet 4, real-time, no batching
        MODEL="sonnet-4"
        BATCH=false
        ;;
    "medium")
        # Medium: Sonnet 4, but batch if possible
        MODEL="sonnet-4"
        BATCH=true
        ;;
    "low")
        # Low: Haiku, always batch, overnight processing
        MODEL="haiku-3-5"
        BATCH=true
        ;;
esac

if [ "$BATCH" = true ]; then
    # Queue for batch processing (50% discount)
    echo "$TASK" >> batch-queue.txt
else
    # Execute immediately
    claude --model $MODEL -p "$TASK"
fi
```

## Real-World Examples

### Example 1: Solo Developer on Budget

**Goal**: Run agent 8hrs/day, <$20/month

**Strategy**:
1. Use Sonnet 4 with aggressive prompt caching
2. Use Haiku for refactoring and tests (50% of work)
3. Stay on pay-as-you-go
4. /clear after each task
5. Batch documentation overnight

**Result**: ~$12-15/month

### Example 2: Startup with Multiple Agents

**Goal**: 3 agents running 24/7, predictable costs

**Strategy**:
1. Max subscription ($100/mo) - unlimited usage
2. All agents use Sonnet 4
3. Prompt caching enabled
4. No need to optimize aggressively

**Result**: $100/month fixed cost, no usage anxiety

### Example 3: Enterprise with Heavy Load

**Goal**: 10+ agents, cost-effective at scale

**Strategy**:
1. Multiple Max subscriptions ($200 × 5 = $1000/mo)
2. Route simple tasks to Haiku (30% of work)
3. Batch API for reports/analysis (20% of work)
4. Aggressive prompt caching
5. Dedicated cost monitoring dashboard

**Result**: ~$800-1000/month for massive throughput

## Cost Comparison: Continuous Agent Scenarios

| Scenario | Hours/Day | Optimization | Monthly Cost |
|----------|-----------|-------------|--------------|
| Hobby project | 2-4 | Basic caching | $5-10 |
| Solo dev (moderate) | 6-8 | Caching + Haiku mix | $10-20 |
| Solo dev (heavy) | 10-12 | All optimizations | $15-30 |
| Solo dev (24/7) | 24 | Max subscription | $100 (unlimited) |
| Team (3 agents) | 24 | Max subscription | $100 (unlimited) |
| Team (10+ agents) | 24 | Multiple Max subs | $200-500 |

## Tools and Resources

### Cost Calculators

- Anthropic Console Usage Dashboard
- API Usage & Cost API (official)
- Community cost estimation spreadsheets

### Monitoring Tools

```bash
# Simple usage tracking
alias claude-cost='curl -H "x-api-key: $ANTHROPIC_API_KEY" https://api.anthropic.com/v1/usage'

# With jq for parsing
alias claude-cost-today='claude-cost | jq ".usage[] | select(.date == \"$(date +%Y-%m-%d)\")"'
```

### Budget Alerts

```bash
# Add to crontab: check costs daily
0 0 * * * /home/user/check-daily-costs.sh

# check-daily-costs.sh:
#!/bin/bash
DAILY_BUDGET=5
COST_TODAY=$(claude-cost-today | jq .total_cost)

if (( $(echo "$COST_TODAY > $DAILY_BUDGET" | bc -l) )); then
    mail -s "Claude costs high today!" user@email.com <<< "Today's cost: $COST_TODAY"
fi
```

## Next Steps

1. Implement security best practices → See `06-security.md`
2. Review working examples and setups → See `07-examples.md`
3. Start with knowledge base overview → See `README.md`

## References

- Anthropic Pricing Page (2025): https://www.anthropic.com/pricing
- Manage costs effectively - Claude Docs
- Community cost analyses and comparison guides
- Finout Blog: Anthropic API Pricing Guide (2025)
- Various cost optimization blog posts from 2025
