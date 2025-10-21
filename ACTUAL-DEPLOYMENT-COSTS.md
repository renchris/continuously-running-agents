# Actual Deployment Costs Analysis

**Data Source:** Production monitoring, October 20, 2025, 19:36-21:06 UTC
**Test Setup:** 5 agents on Hetzner CPX21 (3 vCPU, 4GB RAM, €7.91/month)

## Real Production Metrics

| Metric | Average | Peak | Notes |
|--------|---------|------|-------|
| CPU % | 0.5% | 3.1% | Mostly idle |
| RAM per agent | 280 MB | - | Stable |
| RAM total (5 agents) | 1.42 GB | 1.42 GB | 35% of 4GB |
| Load average | 0.01 | 0.03 | Very light |
| Swap usage | 0% | 0% | No pressure |

**Key Finding:** Server is severely under-utilized - 65% RAM free, 99.5% CPU idle.

## Current Cost Structure

| Setup | Agents | RAM Used | Cost/Month | Cost/Agent |
|-------|--------|----------|------------|------------|
| Current (5 agents) | 5 | 35% | €7.91 | **€1.58** |
| Available capacity | ~4 more | - | - | - |

## Immediate Optimization: Increase Density

**Goal:** Run 8 agents per CPX21 instead of 5

| Configuration | Agents/Server | RAM Used | Cost/Agent | Savings |
|---------------|---------------|----------|------------|---------|
| Current | 5 | 35% | €1.58 | Baseline |
| **Recommended** | **8** | **56%** | **€0.99** | **37%** |
| Aggressive | 10 | 70% | €0.79 | 50% |

### Implementation

```bash
# Deploy 3 more agents to existing server
./deploy-agent.sh --server cpx21-01 --count 3

# Monitor during ramp-up
watch -n 60 free -h
```

**Expected Result:** €0.99 per agent/month (from €1.58) = €0.50 per agent savings

## Cost at Scale (8 agents per server)

| Total Agents | Servers | Monthly Cost | Cost/Agent | Annual Cost |
|--------------|---------|--------------|------------|-------------|
| 8 | 1 | €7.91 | €0.99 | €95 |
| 16 | 2 | €15.82 | €0.99 | €190 |
| 40 | 5 | €39.55 | €0.99 | €475 |
| 80 | 10 | €79.10 | €0.99 | €949 |

## Resource Utilization Analysis

**Current (5 agents):**
- CPU: 98.5% idle
- RAM: 64.6% free
- Status: UNDER-UTILIZED

**Optimized (8 agents):**
- CPU: 98% idle (still plenty)
- RAM: 44% free (healthy buffer)
- Status: EFFICIENT

## Monitoring Requirements

### Alert Thresholds

| Metric | Warning | Critical |
|--------|---------|----------|
| RAM | 70% | 85% |
| CPU | 60% | 80% |
| Load (1m) | 2.0 | 2.5 |
| Agent restarts | 3/hour | 5/hour |

### Essential Metrics

```javascript
// Track per-agent memory
const metrics = {
  rss: process.memoryUsage().rss,
  heapUsed: process.memoryUsage().heapUsed,
  heapTotal: process.memoryUsage().heapTotal
};
```

## Next Steps

1. **Week 1:** Add 3 more agents to current server (5→8)
2. **Week 1:** Implement memory monitoring dashboard
3. **Week 2:** Validate stability with 8 agents
4. **Week 3:** Document optimal configuration

## Conclusion

**Current inefficiency:** €1.58/agent with 65% free capacity
**Immediate fix:** 8 agents/server = €0.99/agent (37% savings)
**Simple action:** Deploy 3 more agents to existing hardware

No architectural changes needed - just use existing capacity more efficiently.

---

**Data Source:** `~/agents/logs/resource-usage.log`
**Next Review:** After reaching 8 agents/server
