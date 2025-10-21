# Scaling Metrics and Resource Optimization

## Overview

This guide provides data-driven metrics for making informed decisions about when to scale your VM resources up or down. Based on Pieter Levels' cost optimization approach, these metrics help you maintain optimal performance while minimizing costs.

**Key Principle**: Make scaling decisions based on 7+ days of data, not instantaneous spikes.

---

## Table of Contents

1. [Metrics to Monitor](#metrics-to-monitor)
2. [Scaling Up Decision Matrix](#scaling-up-decision-matrix)
3. [Scaling Down Decision Matrix](#scaling-down-decision-matrix)
4. [Monitoring Setup](#monitoring-setup)
5. [Decision Workflow](#decision-workflow)
6. [OVHCloud Scaling Procedure](#ovhcloud-scaling-procedure)

---

## Metrics to Monitor

### 1. CPU Usage

**Commands:**
```bash
# Real-time monitoring
htop

# Current CPU percentage
top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1

# Historical average (requires sysstat)
sar -u 1 10  # 10 samples, 1 second apart
```

**What to look for:**
- **Average usage** over 7 days
- **Peak usage** during busy periods
- **Sustained high usage** (>70% for >1 hour)

### 2. RAM Usage

**Commands:**
```bash
# Current usage with human-readable format
free -h

# RAM percentage used
free | grep Mem | awk '{print ($3/$2) * 100.0}'

# Top memory-consuming processes
ps aux --sort=-%mem | head -10

# Per-agent memory
ps aux | grep claude | awk '{print $4, $11}'
```

**What to look for:**
- **Average RAM** usage over 7 days
- **Peak RAM** usage
- **Swap usage** (any swap = problem)

### 3. Swap Usage

**Commands:**
```bash
# Current swap usage
free -h | grep Swap

# Swap percentage
free | grep Swap | awk '{print ($3/$2) * 100.0}'
```

**Critical:**
- ⚠️ **Any swap usage** means you need more RAM
- Swap = severe performance degradation
- If swap >0%, scale up immediately

### 4. Load Average

**Commands:**
```bash
# System load average
uptime

# Load average explained:
# - 1 min, 5 min, 15 min averages
# - Should be < (number of vCPUs × 1.5)
```

**Interpretation:**
- **s1-4 (1 vCPU)**: Load should be <1.5
- **b2-7 (2 vCPU)**: Load should be <3.0
- **b2-15 (4 vCPU)**: Load should be <6.0

### 5. Disk I/O

**Commands:**
```bash
# Real-time I/O by process
iotop

# Disk usage
df -h

# I/O statistics
iostat -x 1 5

# I/O wait percentage
top -bn1 | grep "Cpu(s)" | awk '{print $10}'
```

**What to look for:**
- **I/O wait** >20% sustained = disk bottleneck
- **Disk usage** >80% = need more storage

### 6. Network Activity

**Commands:**
```bash
# Real-time network usage per process
nethogs

# Network interface statistics
ifstat 1 5

# Total bandwidth
vnstat
```

**What to look for:**
- Network is rarely the bottleneck for agents
- Mostly low bandwidth (API calls are small)

### 7. Agent Activity

**Commands:**
```bash
# Active tmux sessions
tmux ls

# Claude processes count
ps aux | grep claude | wc -l

# Recent log activity
tail -100 ~/agents/logs/*.log | grep -c "response"

# Agent response time (proxy for performance)
# Check logs for lag between request and response
```

---

## Scaling Up Decision Matrix

### When to Scale Up (e.g., s1-4 → b2-7)

| Metric | Threshold | Duration | Urgency | Action |
|--------|-----------|----------|---------|--------|
| **CPU Usage** | >70% | >1 hour sustained | Medium | Scale up within 1-2 days |
| **RAM Usage** | >85% | >30 min sustained | High | Scale up within 24 hours |
| **Swap Usage** | >0% (any) | Any usage | **CRITICAL** | Scale up immediately |
| **Load Average** | >1.5× vCPU | >30 min | Medium | Scale up within 1-2 days |
| **I/O Wait** | >20% | >30 min | Medium | Scale up or optimize disk |
| **Agent Lag** | Slow responses | User noticeable | High | Investigate then scale |
| **OOM Errors** | Out of memory | Any occurrence | **CRITICAL** | Scale up immediately |

### Urgency Levels:

- **CRITICAL** (Now): Scale immediately, agents may crash
- **High** (24hrs): Scale within a day, performance degrading
- **Medium** (1-2 days): Schedule scaling, proactive optimization

### Example Scenarios:

**Scenario 1: Need to Scale Up**
```
Observations over 3 days:
- CPU: 75% average, 90% peak
- RAM: 88% average, 95% peak
- Swap: 5% used
- Load: 1.8 (1 vCPU instance)

Decision: ✅ SCALE UP (high RAM usage, swap in use)
Action: Resize s1-4 → b2-7 within 24 hours
```

**Scenario 2: Stay Current Size**
```
Observations over 7 days:
- CPU: 45% average, 65% peak
- RAM: 60% average, 75% peak
- Swap: 0%
- Load: 0.8

Decision: ❌ Don't scale (comfortable margins)
Action: Continue monitoring
```

---

## Scaling Down Decision Matrix

### When to Scale Down (e.g., b2-7 → s1-4)

**IMPORTANT**: Collect **at least 7 days** of data before scaling down.

| Metric | Safe Threshold | Minimum Duration | Notes |
|--------|----------------|------------------|-------|
| **Avg CPU** | <30% | 7 days | Average over entire week |
| **Peak CPU** | <60% | 7 days | Even during busiest times |
| **Avg RAM** | <50% | 7 days | Must have headroom |
| **Peak RAM** | <75% of target | 7 days | Critical for s1-4 (4GB) |
| **Swap** | 0% always | 7 days | No exceptions |
| **Load Avg** | <0.7× vCPU | 7 days | Well below capacity |
| **User Reports** | No slowness | Ongoing | No performance complaints |

### Safe to Scale Down When **ALL** Are True:

- ✅ Average CPU <30% over 7+ days
- ✅ Peak CPU <60%
- ✅ Average RAM <50% over 7+ days
- ✅ Peak RAM <75% of target instance size
- ✅ No swap usage ever (0%)
- ✅ No user-reported slowness
- ✅ Load average <0.7

### Example Decision:

**Scenario: Analyzing b2-7 for potential downgrade to s1-4**

```
7-day metrics on b2-7 (2 vCPU, 7GB RAM):
- Avg CPU: 18%  ✅ <30%
- Peak CPU: 45% ✅ <60%
- Avg RAM: 35% (2.45GB used) ✅ <50%
- Peak RAM: 55% (3.85GB used) ⚠️ CHECK!
- Swap: 0%      ✅ None
- Load: 0.5     ✅ <0.7

Analysis:
- Peak RAM: 3.85GB used
- s1-4 has 4GB total
- 3.85GB/4GB = 96% utilization at peak ❌ TOO TIGHT!

Decision: ❌ DON'T scale down
Reason: Peak RAM would max out s1-4, risking swap/OOM
Recommendation: Stay on b2-7 or optimize RAM usage first
```

**Scenario: Safe to scale down**

```
14-day metrics on b2-7 (2 vCPU, 7GB RAM):
- Avg CPU: 22%  ✅ <30%
- Peak CPU: 52% ✅ <60%
- Avg RAM: 32% (2.24GB used) ✅ <50%
- Peak RAM: 42% (2.94GB used) ✅ 2.94/4 = 73.5% of s1-4
- Swap: 0%      ✅ None
- Load: 0.45    ✅ <0.7

Decision: ✅ SAFE to scale down to s1-4
Action: Schedule scaling during low-activity period
Savings: $7/month ($15 → $8)
```

---

## Monitoring Setup

### Automated Resource Monitoring Script

Create a continuous monitoring script that logs metrics every 5 minutes:

**Location**: `~/scripts/monitoring/resource-stats.sh`

```bash
#!/bin/bash
###############################################################################
# Resource Statistics Logger
#
# Logs CPU, RAM, Load, Swap, and Disk usage every 5 minutes
# Used for long-term scaling decision analysis
#
# Usage: Run in tmux background session
#   tmux new -d -s resource-monitor "bash ~/scripts/monitoring/resource-stats.sh"
###############################################################################

LOG_FILE=~/agents/logs/resource-usage.log
INTERVAL=300  # 5 minutes

# Ensure log directory exists
mkdir -p ~/agents/logs

echo "Starting resource monitoring - logging to $LOG_FILE"
echo "Timestamp,CPU%,RAM%,Load1m,Swap%,Disk%" > $LOG_FILE

while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    MEM=$(free | grep Mem | awk '{print ($3/$2) * 100.0}')
    LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}')
    SWAP=$(free | grep Swap | awk '{if($2>0) print ($3/$2) * 100.0; else print 0}')
    DISK=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')

    echo "$TIMESTAMP,$CPU,$MEM,$LOAD,$SWAP,$DISK" >> $LOG_FILE

    sleep $INTERVAL
done
```

### Analysis Script

**Location**: `~/scripts/monitoring/analyze-usage.sh`

```bash
#!/bin/bash
###############################################################################
# Resource Usage Analyzer
#
# Analyzes historical resource usage from logs
# Provides scaling recommendations
#
# Usage: bash ~/scripts/monitoring/analyze-usage.sh [days]
###############################################################################

DAYS=${1:-7}
LOG_FILE=~/agents/logs/resource-usage.log

if [ ! -f "$LOG_FILE" ]; then
    echo "Error: Log file not found at $LOG_FILE"
    echo "Have you started resource monitoring?"
    exit 1
fi

# Calculate number of lines for N days (288 samples per day at 5-min intervals)
SAMPLES=$((DAYS * 288))

echo "======================================"
echo "  RESOURCE USAGE ANALYSIS"
echo "  Last $DAYS days"
echo "======================================"
echo ""

# CPU Analysis
echo "CPU Usage:"
AVG_CPU=$(tail -n $SAMPLES "$LOG_FILE" | awk -F',' '{sum+=$2; count++} END {printf "%.1f", sum/count}')
PEAK_CPU=$(tail -n $SAMPLES "$LOG_FILE" | awk -F',' '{if($2>max) max=$2} END {printf "%.1f", max}')
echo "  Average: ${AVG_CPU}%"
echo "  Peak:    ${PEAK_CPU}%"

# RAM Analysis
echo ""
echo "RAM Usage:"
AVG_RAM=$(tail -n $SAMPLES "$LOG_FILE" | awk -F',' '{sum+=$3; count++} END {printf "%.1f", sum/count}')
PEAK_RAM=$(tail -n $SAMPLES "$LOG_FILE" | awk -F',' '{if($3>max) max=$3} END {printf "%.1f", max}')
echo "  Average: ${AVG_RAM}%"
echo "  Peak:    ${PEAK_RAM}%"

# Load Average
echo ""
echo "Load Average:"
AVG_LOAD=$(tail -n $SAMPLES "$LOG_FILE" | awk -F',' '{sum+=$4; count++} END {printf "%.2f", sum/count}')
PEAK_LOAD=$(tail -n $SAMPLES "$LOG_FILE" | awk -F',' '{if($4>max) max=$4} END {printf "%.2f", max}')
echo "  Average: ${AVG_LOAD}"
echo "  Peak:    ${PEAK_LOAD}"

# Swap Usage
echo ""
echo "Swap Usage:"
AVG_SWAP=$(tail -n $SAMPLES "$LOG_FILE" | awk -F',' '{sum+=$5; count++} END {printf "%.1f", sum/count}')
PEAK_SWAP=$(tail -n $SAMPLES "$LOG_FILE" | awk -F',' '{if($5>max) max=$5} END {printf "%.1f", max}')
echo "  Average: ${AVG_SWAP}%"
echo "  Peak:    ${PEAK_SWAP}%"

# Disk Usage
echo ""
echo "Disk Usage:"
CURR_DISK=$(tail -n 1 "$LOG_FILE" | awk -F',' '{print $6}')
echo "  Current: ${CURR_DISK}%"

echo ""
echo "======================================"
echo "  SCALING RECOMMENDATION"
echo "======================================"
echo ""

# Determine current instance type from RAM
TOTAL_RAM=$(free -g | grep Mem | awk '{print $2}')
if [ $TOTAL_RAM -le 4 ]; then
    INSTANCE="s1-4"
    VCPU=1
    NEXT_UP="b2-7"
elif [ $TOTAL_RAM -le 7 ]; then
    INSTANCE="b2-7"
    VCPU=2
    NEXT_UP="b2-15"
    NEXT_DOWN="s1-4"
else
    INSTANCE="b2-15+"
    VCPU=4
    NEXT_DOWN="b2-7"
fi

echo "Current Instance: $INSTANCE ($VCPU vCPU, ${TOTAL_RAM}GB RAM)"
echo ""

# Check if should scale UP
SCALE_UP=0
if (( $(echo "$AVG_CPU > 70" | bc -l) )); then
    echo "⚠️  CPU average >70% - consider scaling up"
    SCALE_UP=1
fi
if (( $(echo "$PEAK_CPU > 90" | bc -l) )); then
    echo "⚠️  CPU peak >90% - consider scaling up"
    SCALE_UP=1
fi
if (( $(echo "$AVG_RAM > 85" | bc -l) )); then
    echo "🚨 RAM average >85% - SCALE UP SOON"
    SCALE_UP=1
fi
if (( $(echo "$PEAK_SWAP > 0" | bc -l) )); then
    echo "🚨 Swap in use - SCALE UP IMMEDIATELY"
    SCALE_UP=1
fi
if (( $(echo "$AVG_LOAD > ($VCPU * 1.5)" | bc -l) )); then
    echo "⚠️  Load average high - consider scaling up"
    SCALE_UP=1
fi

# Check if can scale DOWN (only if not scaling up)
if [ $SCALE_UP -eq 0 ] && [ -n "$NEXT_DOWN" ]; then
    CAN_SCALE_DOWN=1

    if (( $(echo "$AVG_CPU > 30" | bc -l) )); then
        CAN_SCALE_DOWN=0
    fi
    if (( $(echo "$PEAK_CPU > 60" | bc -l) )); then
        CAN_SCALE_DOWN=0
    fi
    if (( $(echo "$AVG_RAM > 50" | bc -l) )); then
        CAN_SCALE_DOWN=0
    fi
    if (( $(echo "$PEAK_SWAP > 0" | bc -l) )); then
        CAN_SCALE_DOWN=0
    fi

    # Check if peak RAM would fit in smaller instance
    if [ "$NEXT_DOWN" = "s1-4" ]; then
        # s1-4 has 4GB RAM
        PEAK_RAM_GB=$(echo "scale=2; ($PEAK_RAM / 100) * $TOTAL_RAM" | bc)
        PEAK_RAM_PERCENT_S14=$(echo "scale=1; ($PEAK_RAM_GB / 4) * 100" | bc)

        if (( $(echo "$PEAK_RAM_PERCENT_S14 > 75" | bc -l) )); then
            echo "⚠️  Peak RAM (${PEAK_RAM_GB}GB) too high for s1-4 (would be ${PEAK_RAM_PERCENT_S14}%)"
            CAN_SCALE_DOWN=0
        fi
    fi

    if [ $CAN_SCALE_DOWN -eq 1 ] && [ $DAYS -ge 7 ]; then
        echo "✅ Can potentially scale down to $NEXT_DOWN"
        echo "   Potential savings: \$7/month (if b2-7→s1-4)"
        echo ""
        echo "   Before scaling down:"
        echo "   1. Verify $DAYS days is representative workload"
        echo "   2. Schedule during low-activity period"
        echo "   3. Monitor closely after downgrade"
    elif [ $DAYS -lt 7 ]; then
        echo "⏳ Collect more data (need 7+ days, have $DAYS days)"
    fi
fi

if [ $SCALE_UP -eq 0 ] && ([ -z "$NEXT_DOWN" ] || [ $CAN_SCALE_DOWN -eq 0 ]); then
    echo "✅ Current instance size is appropriate"
    echo "   Continue monitoring for optimal performance"
fi

if [ $SCALE_UP -eq 1 ] && [ -n "$NEXT_UP" ]; then
    echo ""
    echo "📈 Recommendation: Scale up to $NEXT_UP"
    echo "   Additional cost: ~\$7/month (s1-4→b2-7)"
fi

echo ""
echo "======================================"
```

### Live Dashboard

**Location**: `~/scripts/monitoring/dashboard.sh`

```bash
#!/bin/bash
###############################################################################
# Live Resource Dashboard
#
# Real-time monitoring with historical context
#
# Usage: bash ~/scripts/monitoring/dashboard.sh
###############################################################################

while true; do
    clear
    echo "======================================"
    echo "  RESOURCE MONITORING DASHBOARD"
    echo "  $(date '+%Y-%m-%d %H:%M:%S')"
    echo "======================================"
    echo ""

    # Current Resources
    CPU_CURRENT=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    RAM_USED=$(free -h | grep Mem | awk '{print $3}')
    RAM_TOTAL=$(free -h | grep Mem | awk '{print $2}')
    RAM_PERCENT=$(free | grep Mem | awk '{print int($3/$2*100)}')
    SWAP_USED=$(free -h | grep Swap | awk '{print $3}')
    SWAP_TOTAL=$(free -h | grep Swap | awk '{print $2}')
    DISK_USED=$(df -h / | awk 'NR==2 {print $3}')
    DISK_TOTAL=$(df -h / | awk 'NR==2 {print $2}')
    DISK_PERCENT=$(df -h / | awk 'NR==2 {print $5}')
    LOAD=$(uptime | awk -F'load average:' '{print $2}')

    echo "Current Resources:"
    echo "  CPU:  ${CPU_CURRENT}%"
    echo "  RAM:  ${RAM_USED}/${RAM_TOTAL} (${RAM_PERCENT}%)"
    echo "  Swap: ${SWAP_USED}/${SWAP_TOTAL}"
    echo "  Disk: ${DISK_USED}/${DISK_TOTAL} (${DISK_PERCENT})"
    echo "  Load:${LOAD}"
    echo ""

    # Historical averages
    if [ -f ~/agents/logs/resource-usage.log ]; then
        echo "7-Day Averages:"
        AVG_CPU=$(tail -n 2000 ~/agents/logs/resource-usage.log | awk -F',' '{sum+=$2; count++} END {printf "%.1f", sum/count}')
        PEAK_CPU=$(tail -n 2000 ~/agents/logs/resource-usage.log | awk -F',' '{if($2>max) max=$2} END {printf "%.1f", max}')
        AVG_RAM=$(tail -n 2000 ~/agents/logs/resource-usage.log | awk -F',' '{sum+=$3; count++} END {printf "%.1f", sum/count}')
        PEAK_RAM=$(tail -n 2000 ~/agents/logs/resource-usage.log | awk -F',' '{if($3>max) max=$3} END {printf "%.1f", max}')

        echo "  Avg CPU:  ${AVG_CPU}%"
        echo "  Peak CPU: ${PEAK_CPU}%"
        echo "  Avg RAM:  ${AVG_RAM}%"
        echo "  Peak RAM: ${PEAK_RAM}%"
        echo ""

        echo "Scale Assessment:"
        if (( $(echo "$AVG_CPU < 30" | bc -l) )) && \
           (( $(echo "$PEAK_CPU < 60" | bc -l) )) && \
           (( $(echo "$AVG_RAM < 50" | bc -l) )) && \
           (( $(echo "$PEAK_RAM < 75" | bc -l) )); then
            echo "  ✅ Could potentially scale down"
            echo "     (Run analyze-usage.sh for details)"
        elif (( $(echo "$AVG_CPU > 70" | bc -l) )) || \
             (( $(echo "$AVG_RAM > 85" | bc -l) )); then
            echo "  ⚠️  Consider scaling up"
        else
            echo "  ✅ Current size is appropriate"
        fi
    else
        echo "Historical Data:"
        echo "  (No data yet - monitoring not started)"
        echo ""
        echo "  Start monitoring with:"
        echo "  tmux new -d -s resource-monitor 'bash ~/scripts/monitoring/resource-stats.sh'"
    fi

    echo ""
    echo "Active Agents: $(tmux ls 2>/dev/null | grep -c agent || echo 0)"
    echo "Tmux Sessions: $(tmux ls 2>/dev/null | wc -l || echo 0)"
    echo ""
    echo "======================================"
    echo "Refreshing in 5s... (Ctrl+C to exit)"

    sleep 5
done
```

---

## Decision Workflow

### Initial Deployment (Day 0)

1. **Start with s1-4** ($8/mo)
2. **Immediately start monitoring**:
   ```bash
   tmux new -d -s resource-monitor "bash ~/scripts/monitoring/resource-stats.sh"
   ```
3. Deploy 3-5 agents
4. Run for 7-14 days

### Week 1 Review (Day 7)

Run analysis:
```bash
bash ~/scripts/monitoring/analyze-usage.sh 7
```

**Possible outcomes:**

**A) Scale Up Needed**
- High CPU/RAM usage detected
- Action: Scale to b2-7
- Timeline: Within 24-48 hours

**B) Current Size OK**
- Metrics within acceptable range
- Action: Continue monitoring
- Timeline: Review again in 30 days

**C) Could Scale Down** (unlikely on day 7 if started with s1-4)
- Very low resource usage
- Action: Continue monitoring for another 7 days to confirm
- Timeline: Potential scale down after 14 days

### Monthly Review (Day 30+)

1. Run analysis for full month:
   ```bash
   bash ~/scripts/monitoring/analyze-usage.sh 30
   ```

2. Review Max Plan rate limit usage
3. Check cost vs performance
4. Make scaling decision

### Continuous Monitoring

- **Daily**: Quick check via dashboard
  ```bash
  bash ~/scripts/monitoring/dashboard.sh
  ```

- **Weekly**: Run 7-day analysis
- **Monthly**: Comprehensive review and cost optimization

---

## OVHCloud Scaling Procedure

### Vertical Scaling (Resize Instance)

**Step 1: Prepare for Downtime**
```bash
# Save all agent work
tmux ls | awk '{print $1}' | sed 's/://g' | while read session; do
    tmux send-keys -t $session C-c  # Gracefully stop agents
done

# Wait for agents to finish current tasks (1-2 min)
sleep 120

# Kill tmux sessions
tmux kill-server

# Verify no Claude processes running
ps aux | grep claude
```

**Step 2: In OVHCloud Console**
1. Go to **Public Cloud** → **Instances**
2. Select your instance
3. Click **Edit** or **Resize**
4. Choose new flavor:
   - Scale up: s1-4 → b2-7
   - Scale down: b2-7 → s1-4
5. Confirm resize
6. Wait 3-5 minutes for resize

**Step 3: Verify After Resize**
```bash
# SSH back into instance
ssh claude-agent@YOUR_IP

# Verify new resources
free -h
nproc  # Number of vCPUs

# Restart monitoring
tmux new -d -s resource-monitor "bash ~/scripts/monitoring/resource-stats.sh"

# Restart agents
bash ~/scripts/setup/start-agent.sh
```

**Downtime**: 5-10 minutes total

---

## Cost Impact Examples

### Scenario 1: Stay on s1-4
- **Instance**: $8/mo
- **Max Plan**: $100/mo
- **Total**: $108/mo
- **Savings**: $7/mo vs b2-7

### Scenario 2: Scale to b2-7
- **Instance**: $15/mo
- **Max Plan**: $100/mo
- **Total**: $115/mo
- **Cost**: +$7/mo, but better performance

### Scenario 3: Scale to b2-7 + API Key
- **Instance**: $15/mo
- **API Usage**: $30-50/mo
- **Total**: $45-65/mo (no Max Plan needed!)
- **Savings**: $50-70/mo vs Max+VM if API usage is moderate

---

## Summary

### Key Principles:

1. **Monitor for 7+ days** before making decisions
2. **Scale up aggressively** when hitting limits (performance matters)
3. **Scale down conservatively** with ample headroom
4. **Automate monitoring** from day 1
5. **Review monthly** for cost optimization

### Quick Reference:

**Scale Up When:**
- CPU >70% sustained or RAM >85%
- Any swap usage
- User complaints about slowness

**Scale Down When (ALL true):**
- Avg CPU <30%, Peak <60%
- Avg RAM <50%, Peak <75% of target
- No swap, 7+ days data
- No performance issues

**Tools:**
- `resource-stats.sh` - Continuous logging
- `analyze-usage.sh` - Decision support
- `dashboard.sh` - Live monitoring

---

**Last Updated**: October 19, 2025
**Version**: 1.0.0
**Author**: Chris Ren (based on Pieter Levels' optimization principles)
