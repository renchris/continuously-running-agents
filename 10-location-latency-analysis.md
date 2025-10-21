# VM Location vs Latency: Decision Analysis for API-Bound Workloads

## Overview

When deploying Claude Code agents to the cloud, instance location (datacenter region) might seem important. However, for **API-bound workloads** like Claude Code agents, the VM-to-datacenter latency is largely **irrelevant** compared to the dominant factor: API response time.

This document explains why we chose **D2-4 in Oregon** over **B3-8 in LA Local Zone**, despite LA being closer geographically.

---

## Executive Summary

**Decision**: D2-4 in Oregon ($13.15/mo) instead of B3-8 in LA ($36.58/mo)

**Reasoning**:
- API call latency (200-2000ms) dwarfs network latency (10-15ms)
- Saves $276/year ($23/mo)
- Performance difference negligible for agent workloads
- Can upgrade later if needed

**When location matters**: Real-time applications, low-latency services, user-facing web apps

**When location doesn't matter**: API-bound agents, batch processing, background workers

---

## Latency Breakdown

### Network Latency Components

```
Total Request Time = User Latency + VM Processing + API Latency + Response Processing
```

#### Scenario 1: B3-8 in LA Local Zone

```
Your Mac (LA) → VM (LA Local):        ~1-2ms
VM → Anthropic API (Global CDN):      ~20-50ms  (varies by API endpoint)
Anthropic API Processing:              200-2000ms (model inference)
API → VM:                              ~20-50ms
VM Processing:                         ~10-50ms
VM → Your Mac (when SSH'd in):        ~1-2ms
────────────────────────────────────────────────
Total typical request:                 251-2154ms
Network portion:                       ~42-104ms (2-5% of total)
```

#### Scenario 2: D2-4 in Oregon

```
Your Mac (LA) → VM (Oregon):          ~10-15ms   (+9-13ms vs LA)
VM → Anthropic API:                   ~25-60ms   (+5-10ms vs LA)
Anthropic API Processing:             200-2000ms (same)
API → VM:                             ~25-60ms
VM Processing:                        ~10-50ms
VM → Your Mac (when SSH'd in):       ~10-15ms
────────────────────────────────────────────────
Total typical request:                280-2200ms
Network portion:                      ~70-150ms (3-7% of total)
Difference from LA:                   +29-46ms (~2% slower)
```

### Key Insight

**LA advantage**: 29-46ms faster (2% improvement)
**LA cost**: $23/mo more ($276/year)
**Cost per millisecond saved**: $6/ms/year or $0.50/ms/month

**Is 30ms worth $276/year?** For API-bound agents, **no**.

---

## Why Location Doesn't Matter for Claude Code Agents

### 1. Agents Are I/O-Bound, Not Network-Bound

Claude Code agents spend their time:

| Activity | Time | % of Total |
|----------|------|------------|
| **Waiting for API response** | 200-2000ms | **90-95%** |
| Local code execution | 10-50ms | 2-5% |
| File I/O | 5-20ms | 1-2% |
| Network latency (LA) | 42-104ms | 2-5% |
| Network latency (Oregon) | 70-150ms | 3-7% |

**Bottleneck**: API inference time (200-2000ms), not network (30ms difference)

### 2. Human Perception Threshold

- **<100ms**: Feels instant
- **100-300ms**: Slight delay, barely noticeable
- **300-1000ms**: Noticeable but acceptable
- **>1000ms**: Slow, needs optimization

**Reality**: Both LA and Oregon are well under perception threshold for the network portion. The API processing time (200-2000ms) dominates user experience.

### 3. Agent Workflow Pattern

```bash
# Typical agent workflow
Agent receives task → (instant)
Agent thinks about approach → (instant)
Agent calls Claude API → (200-2000ms) ← BOTTLENECK
Agent receives response → (+30ms OR vs LA - negligible)
Agent writes code → (10-50ms)
Agent calls API again → (200-2000ms) ← BOTTLENECK
```

**The 30ms Oregon "penalty" is noise compared to 200-2000ms API calls.**

### 4. SSH Interactive Use

When YOU connect to the VM:

- **LA Local**: 1-2ms SSH latency
- **Oregon**: 10-15ms SSH latency
- **Difference**: 9-13ms

**Human perception**: Both feel instant (<100ms threshold)

**Typing in SSH session**:
- Keystroke → VM: +9ms (Oregon)
- Character echo: +9ms return
- **Total penalty**: 18ms per keystroke

**Reality**: You won't notice 18ms. Modern internet has more jitter than this.

---

## When Location DOES Matter

### Use Cases Where Location is Critical:

1. **Real-time applications**
   - Video streaming
   - Online gaming
   - VoIP/video calls
   - High-frequency trading
   - **Requirement**: <50ms latency

2. **User-facing web applications**
   - E-commerce sites
   - SaaS dashboards
   - Content delivery
   - **Requirement**: <200ms response time

3. **Database-heavy workloads**
   - High transaction rate applications
   - Real-time analytics
   - Microservices with chatty inter-service calls
   - **Requirement**: Minimize cumulative latency

4. **Low-latency services**
   - CDN edge nodes
   - DNS servers
   - Load balancers
   - **Requirement**: Geographic distribution

### Why Claude Code Agents Don't Fit These:

- ❌ Not real-time (async background processing)
- ❌ Not user-facing (you SSH in occasionally)
- ❌ Not database-heavy (mostly API calls)
- ❌ API latency dominates (200-2000ms vs 30ms network)

---

## Cost-Benefit Analysis

### Quantitative Analysis

**Scenario**: Running 5 agents, each making 10 API calls per hour

```
Calls per month: 5 agents × 10 calls/hr × 24 hrs × 30 days = 36,000 calls

LA Local (B3-8):
  Cost: $36.58/mo
  Avg latency per call: 280ms
  Total wait time: 36,000 × 280ms = 10,080 seconds = 168 minutes

Oregon (D2-4):
  Cost: $13.15/mo
  Avg latency per call: 310ms (+30ms)
  Total wait time: 36,000 × 310ms = 11,160 seconds = 186 minutes

Difference:
  Extra wait time: 18 minutes/month
  Cost savings: $23.43/month = $281/year

Cost per minute saved: $23.43 / 18 = $1.30/minute
Cost per hour saved: $78/hour

Conclusion: Paying $78/hour to save clock time that agents
are waiting anyway (not doing useful work) is poor value.
```

### Qualitative Factors

**D2-4 in Oregon Advantages**:
- ✅ $276/year savings
- ✅ Same API performance (bottleneck unchanged)
- ✅ Adequate specs for Max Plan rate limits
- ✅ Easy to upgrade if proven inadequate
- ✅ Oregon still West Coast (not across country)

**B3-8 in LA Advantages**:
- ✅ 30ms faster network (2% improvement)
- ✅ Newest hardware generation
- ✅ More RAM (8GB vs 4GB)
- ✅ NVMe storage (faster)
- ❌ $276/year more expensive
- ❌ Overkill for Max Plan rate limits

---

## Decision Matrix

| Factor | Weight | D2-4 Oregon | B3-8 LA | Winner |
|--------|--------|-------------|---------|---------|
| **Cost** | 40% | $13.15/mo (10/10) | $36.58/mo (5/10) | D2-4 ⭐ |
| **Latency** | 20% | 310ms avg (8/10) | 280ms avg (10/10) | B3-8 |
| **Reliability** | 15% | Shared (6/10) | Dedicated (10/10) | B3-8 |
| **Resources** | 15% | 4GB (7/10) | 8GB (10/10) | B3-8 |
| **Scalability** | 10% | Can resize (8/10) | Can resize (9/10) | Tie |
| **Total Score** | 100% | **8.15/10** | **7.85/10** | **D2-4** ✅ |

**Winner**: D2-4 in Oregon (cost optimization outweighs marginal latency benefit)

---

## Real-World Impact Examples

### Example 1: Typical Agent Session

```
Agent task: "Implement user authentication"

D2-4 Oregon:
  Planning API call: 800ms
  Code generation call: 1200ms
  Review call: 600ms
  Total API time: 2600ms
  Network penalty: ~90ms (Oregon vs LA)
  Total time: 2690ms

B3-8 LA:
  Planning API call: 800ms
  Code generation call: 1200ms
  Review call: 600ms
  Total API time: 2600ms
  Network penalty: 0ms
  Total time: 2600ms

Difference: 90ms (3.4% slower)
Cost: $23/mo premium

Value: Paying $23/mo to save 90ms per task = poor ROI
```

### Example 2: Heavy Agent Day (50 API calls)

```
D2-4 Oregon:
  50 calls × 310ms avg = 15.5 seconds

B3-8 LA:
  50 calls × 280ms avg = 14.0 seconds

Time saved with LA: 1.5 seconds per heavy day
Cost: $23/month = $0.77/day

Paying $0.77/day to save 1.5 seconds = $18.48/minute saved
```

### Example 3: Interactive SSH Session

```
You SSH in to check agent logs:

D2-4 Oregon:
  SSH connect: 12ms
  Each command: 12ms latency
  10 commands: 120ms total overhead

B3-8 LA:
  SSH connect: 2ms
  Each command: 2ms latency
  10 commands: 20ms total overhead

Difference: 100ms overhead for entire session
Feels: Both instant (under human perception threshold)
```

---

## Geographic Context

### West Coast Options

| Location | Distance from LA | Approx Latency | Available Instances |
|----------|------------------|----------------|---------------------|
| **LA Local** | 0 miles | 1-2ms | B3-8 only |
| **Oregon (Hillsboro)** | ~900 miles | 10-15ms | D2-4, B2-7, most instances |
| **Seattle** | ~1,100 miles | 15-20ms | Various (if available) |
| **San Jose** | ~350 miles | 5-8ms | Various (if available) |

### East Coast (For Comparison)

| Location | Distance from LA | Approx Latency |
|----------|------------------|----------------|
| **Virginia** | ~2,600 miles | 60-80ms |
| **New York** | ~2,800 miles | 70-90ms |

**Key Point**: Oregon is still West Coast. It's not like choosing East Coast (which would add 50-70ms).

---

## API Routing Reality

### Anthropic API Infrastructure

Anthropic's API uses **global load balancing** and **edge locations**:

```
Your VM (Oregon) → Nearest Anthropic Edge → API Processing
Your VM (LA) → Nearest Anthropic Edge → API Processing
```

**Reality**: Both VMs likely hit the same Anthropic edge location (West Coast CDN)

**Difference**: Minimal (5-10ms at most)

### CDN Edge Locations (Typical)

- San Jose
- Los Angeles
- Seattle
- San Francisco

**Both Oregon and LA VMs**: Route to same West Coast edge

**API Processing**: Happens in central data centers (location unknown, doesn't matter)

---

## Monitoring Strategy

Since we chose D2-4 in Oregon, we'll **validate this decision with data**:

### Week 1 Monitoring

Track these metrics:

1. **API Response Times**
   ```bash
   grep "API response" ~/agents/logs/*.log | awk '{print $5}' | stats
   ```

2. **Network Latency**
   ```bash
   # From VM to Anthropic API
   time curl -I https://api.anthropic.com
   ```

3. **SSH Latency** (your perception)
   ```bash
   # From your Mac
   ssh claude-agent@VM_IP "echo test"
   ```

4. **Agent Performance**
   - Tasks completed per hour
   - User-reported responsiveness
   - Any timeouts or slowness

### Decision Criteria After 7 Days

**If D2-4 Oregon is sufficient**:
- ✅ Keep it, save $276/year
- ✅ Validate cost optimization decision

**If performance issues detected**:
- Determine if cause is Discovery tier (shared resources) or location
- Option A: Upgrade to B2-7 in Oregon (dedicated, same location)
- Option B: Resize to B3-8 in LA (best performance, higher cost)

**Key Question**: Is the issue resources or latency?
- Slow due to CPU/RAM contention → Upgrade instance size
- Slow due to network → Change location (unlikely)

---

## Alternative Scenario: When to Choose LA

### Use B3-8 in LA if:

1. **Budget is not a concern**
   - $23/mo is negligible
   - Prefer best-in-class from start

2. **Future-proofing for API key**
   - Plan to switch from Max Plan to API key
   - Will run 10-20+ agents
   - Need 8GB RAM and better CPU

3. **Psychological preference**
   - Want lowest possible latency on principle
   - "Best available" mindset
   - Don't want to worry about region

4. **Specific latency requirements**
   - Have measured requirements <300ms total
   - Every millisecond matters for your use case
   - (Not typical for agents)

### Use D2-4 in Oregon if:

1. **Cost optimization priority**
   - $276/year savings meaningful
   - Data-driven decision making
   - Willing to monitor and adapt

2. **Max Plan rate limits are constraint**
   - ~225 msg/5hrs shared limit
   - Resources less important than rate limits
   - Can't fully utilize 8GB RAM anyway

3. **Pieter Levels approach**
   - Start cheap, scale based on data
   - Optimize for cost/performance ratio
   - Monitor and iterate

---

## Conclusion

### The Decision

**Chosen**: D2-4 in Oregon ($13.15/mo)

**Over**: B3-8 in LA Local ($36.58/mo)

**Reasoning**:
1. API latency (200-2000ms) >> network latency (30ms difference)
2. Cost savings: $276/year (178% more expensive for 2% performance gain)
3. Oregon still West Coast (not cross-country)
4. Max Plan rate limits are real constraint, not VM resources
5. Can upgrade in 7 days if data shows need
6. Data-driven, iterative optimization approach

### Key Learnings

1. **Understand your bottleneck**: API-bound workloads don't benefit from minimal network latency
2. **Cost per improvement**: B3-8 costs $9.20/ms saved per year
3. **Perception vs reality**: 30ms is imperceptible to humans
4. **Monitor and adapt**: Start cheap, upgrade based on data
5. **Geography matters less than you think**: For async workloads

### Next Steps

1. ✅ Create D2-4 instance in Oregon
2. ✅ Deploy with resource monitoring from day 1
3. ✅ Run 3 agents initially (conservative)
4. ✅ Collect 7 days of performance data
5. ✅ Analyze with `analyze-usage.sh`
6. ✅ Make data-driven decision: keep, upgrade instance size, or change location

---

## Appendix: Latency Testing

### How to Test After Deployment

**From your Mac**:
```bash
# Test SSH latency
time ssh claude-agent@VM_IP "echo test"

# Test continuous latency
ping VM_IP
```

**From the VM**:
```bash
# Test latency to Anthropic API
time curl -I https://api.anthropic.com

# Continuous monitoring
watch -n 1 'curl -o /dev/null -s -w "Time: %{time_total}s\n" https://api.anthropic.com'
```

**Expected Results**:
- SSH: 10-15ms
- API endpoint: 20-60ms (varies by CDN routing)
- API call with inference: 200-2000ms

**If seeing >50ms to Anthropic API from Oregon**: May indicate routing issue, compare with LA

**If API calls >3000ms consistently**: Issue is API/model, not network

---

**Last Updated**: October 19, 2025
**Decision Made By**: Chris Ren
**Approach**: Data-driven cost optimization (Pieter Levels methodology)
**Review Date**: 7 days after deployment (October 25, 2025)
