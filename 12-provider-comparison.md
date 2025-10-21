# Cloud Provider Comparison: OVHCloud vs Hetzner

## Executive Summary

**Recommendation**: **Hetzner CPX21** in Hillsboro, OR

**Why**: Location doesn't matter for API-bound agent workloads. Hetzner offers dedicated resources, 50% more CPU, 60% more storage, and lower cost.

**Savings**: $37.92/year vs OVHCloud D2-4, $228/year vs OVHCloud B2-7

---

## Decision Journey

### Phase 1: Initial Assumption (Incorrect)

**Assumption**: "Closer datacenter = better performance for agents"

**Reasoning**:
- LA Local Zone seemed ideal
- Lower latency assumed to improve agent responsiveness
- Premium pricing justified by proximity

**Reality**: This was **wrong** for API-bound workloads.

### Phase 2: Location Analysis (Revelation)

**Discovery**: Agent performance dominated by API latency, not network latency

**Key Findings** (see `10-location-latency-analysis.md`):
- API inference time: 200-2000ms (90-95% of total time)
- Network latency difference (LA vs OR): ~30ms (2% of total time)
- Human perception threshold: <100ms (both locations feel instant)
- Oregon vs LA cost premium: $23-35/month for negligible benefit

**Conclusion**: **Location doesn't matter for Claude Code agents**

### Phase 3: Provider Comparison (Optimization)

**Question**: If location doesn't matter, what's the best value provider?

**Findings**:
- OVHCloud's advantage (LA Local Zone) is irrelevant
- Hetzner offers better specs at lower cost
- Community heavily favors Hetzner (Pieter Levels, vibecoding)
- Dedicated resources > shared resources for production

**Outcome**: **Hetzner is objectively better**

---

## Head-to-Head Comparison

### Budget Option: Hetzner CPX11 vs OVHCloud D2-4

| Feature | **Hetzner CPX11** | OVHCloud D2-4 |
|---------|-------------------|---------------|
| **vCPU** | 2 dedicated AMD | 2 shared |
| **RAM** | 2 GB | 4 GB ✅ |
| **Storage** | 40 GB | 50 GB ✅ |
| **Resources** | **Dedicated** ✅ | Shared |
| **Performance** | **Predictable** ✅ | Variable |
| **Price/mo** | **$4.90** ✅ | $13.15 |
| **Price/yr** | **$58.80** ✅ | $157.80 |

**Winner**: Hetzner CPX11 (⚠️ but RAM might be tight for 3+ agents)

### Recommended Option: Hetzner CPX21 vs OVHCloud ⭐

| Feature | **Hetzner CPX21** | OVHCloud D2-4 | OVHCloud B2-7 |
|---------|-------------------|---------------|---------------|
| **vCPU** | **3 dedicated** ✅ | 2 shared | 2 dedicated |
| **RAM** | 4 GB | 4 GB | 7 GB ✅ |
| **Storage** | **80 GB** ✅ | 50 GB | 50 GB |
| **Resources** | **Dedicated** ✅ | Shared | Dedicated |
| **Performance** | **Predictable** ✅ | Variable | Predictable |
| **Traffic** | **2 TB included** ✅ | Unlimited* | Unlimited* |
| **Price/mo** | **$9.99** ✅ | $13.15 | $29.04 |
| **Price/yr** | **$119.88** ✅ | $157.80 | $348.48 |
| **Savings vs D2-4** | **-$37.92/yr** ✅ | baseline | +$190.68/yr |
| **Savings vs B2-7** | **-$228.60/yr** ✅ | -$71/yr | baseline |

**Winner**: **Hetzner CPX21** - Best value, dedicated resources, more CPU, more storage

*OVHCloud has no explicit traffic limits but may throttle excessive usage

### Premium Option: Hetzner CPX31 vs OVHCloud

| Feature | **Hetzner CPX31** | OVHCloud B2-7 | OVHCloud B3-8 |
|---------|-------------------|---------------|---------------|
| **vCPU** | **4 dedicated** ✅ | 2 dedicated | 2 dedicated |
| **RAM** | 8 GB | 7 GB | 8 GB |
| **Storage** | **160 GB** ✅ | 50 GB | 50 GB |
| **Resources** | Dedicated | Dedicated | Dedicated |
| **Storage Type** | SSD | SSD | **NVMe** ✅ |
| **Location** | OR, VA | OR | **LA Local** ✅ |
| **Price/mo** | **$17.99** ✅ | $29.04 | $36.58 |
| **Price/yr** | **$215.88** ✅ | $348.48 | $438.96 |

**Winner**: **Hetzner CPX31** (2x CPU for half the price of B3-8)

---

## Why Hetzner CPX21 is Superior

### 1. Better Performance

**CPU**:
- ✅ **3 vCPUs** vs 2 (50% more)
- ✅ **Dedicated** AMD EPYC processors
- ✅ **Predictable** performance (no sharing)

**Storage**:
- ✅ **80 GB** vs 50 GB (60% more)
- ✅ More room for logs, backups, projects

**Network**:
- ✅ **2 TB included traffic** (generous)
- ✅ Same Oregon location option as OVHCloud
- ✅ Low latency to Anthropic API

### 2. Lower Cost

**Savings**:
- vs OVHCloud D2-4: **-$37.92/year** (24% cheaper)
- vs OVHCloud B2-7: **-$228.60/year** (39% cheaper)
- vs OVHCloud B3-8: **-$319.08/year** (42% cheaper)

### 3. Production Quality

**Reliability**:
- ✅ Dedicated vCPUs (consistent performance)
- ✅ No resource contention with other users
- ✅ Predictable behavior for 24/7 agents
- ✅ Excellent uptime track record

**vs Discovery Tier**:
- OVHCloud D2-4: Shared resources, variable performance
- Hetzner CPX21: Dedicated resources, consistent performance

### 4. Community Proven

**Testimonials**:
- ✅ Pieter Levels (@levelsio) - Uses Hetzner extensively
- ✅ Vibecoding community - Popular choice
- ✅ Indie hackers - Reliable, affordable
- ✅ $3M/year businesses run on Hetzner VPS

**Reputation**:
- Known for excellent price/performance
- Strong EU presence, expanding US
- Good support and documentation
- No surprise fees or throttling

---

## Instance Selection Guide

### Choose **Hetzner CPX11** ($4.90/mo) if:

- ✅ Tightest possible budget
- ✅ Running 1-2 agents max
- ✅ Minimal logging/monitoring needs
- ⚠️ **Risk**: May need to upgrade if RAM is insufficient

### Choose **Hetzner CPX21** ($9.99/mo) if: ⭐ **RECOMMENDED**

- ✅ Running 3-5 agents
- ✅ Want dedicated, predictable performance
- ✅ Need headroom for monitoring/logs
- ✅ Value price/performance ratio
- ✅ Following Pieter Levels approach
- ✅ **Best overall value**

### Choose **Hetzner CPX31** ($17.99/mo) if:

- ✅ Running 5-10 agents
- ✅ Need 8GB RAM for memory-intensive workloads
- ✅ Want maximum headroom
- ✅ Still cheaper than OVHCloud options

### Choose **OVHCloud B3-8** ($36.58/mo) if:

- ✅ Must have LA Local Zone (rare requirement)
- ✅ NVMe storage is critical
- ✅ Cost is not a concern
- ❌ **Generally not recommended** for agent workloads

---

## Technical Highlights

### CPU Architecture

**Hetzner**:
- CPX/CCX Series: Dedicated AMD EPYC vCPUs
- Transparent specs, sustained performance
- No "noisy neighbor" issues

**OVHCloud**:
- B3/C3 Series: 2.0-2.3 GHz (architecture unclear)
- Shared resources on Discovery tier
- Performance can vary

### Traffic Considerations

**Estimated Monthly Traffic per Agent**: 50-200 GB
- API calls to Anthropic (streaming responses)
- Git operations, package downloads
- Log streaming, web research

**For 5 agents @ 100GB each = 500GB/month**:
- Hetzner CPX21: Included in $9.99/mo ✅
- OVHCloud: Unknown if included or extra charges

### Network Latency (LA to Datacenters)

| Route | RTT | Impact |
|-------|-----|--------|
| LA → Hetzner Hillsboro, OR | 5-15ms | Negligible |
| LA → Hetzner Ashburn, VA | 60-75ms | Minimal |
| LA → OVHCloud B3-8 (LA Local) | <5ms | Not worth $27/mo premium |

**Why it doesn't matter**: API inference time (200-2000ms) >> network latency (5-75ms)

---

## Real-World Use Cases

### Scenario A: Solo Developer (3-5 agents, Max Plan)

**Hetzner CPX21**: $9.99/mo
- 3 dedicated vCPUs, 4GB RAM
- Sufficient for Max Plan limits (~225 msg/5hrs)
- 2TB traffic included

**OVHCloud D2-4**: $13.15/mo
- 2 shared vCPUs, 4GB RAM
- Variable performance (Discovery tier)
- Unknown traffic limits

**Winner**: Hetzner CPX21 (saves $37.92/year, better performance)

### Scenario B: Small Team (8-12 agents, API Key)

**Hetzner CPX31**: $17.99/mo
- 4 dedicated vCPUs, 8GB RAM
- 160GB storage, 3TB traffic

**OVHCloud B2-7**: $29.04/mo
- 2 dedicated vCPUs, 7GB RAM
- 50GB storage

**Winner**: Hetzner CPX31 (saves $132.60/year, 2x CPU)

### Scenario C: Indie Hacker - Pieter Levels Style

**Goal**: Maximum automation, minimize costs

**Hetzner CPX21**: $9.99/mo
- Dedicated resources
- Proven by $3M/year businesses
- "Good enough" philosophy

**Pieter Levels Philosophy Alignment**: ✅ Excellent match

---

## Migration Guide

### If Already on OVHCloud

**From D2-4 to Hetzner CPX21**:
- Save $37.92/year
- Gain 50% more CPU (dedicated vs shared)
- Gain 60% more storage
- **Recommended**: Switch immediately

**From B2-7 to Hetzner CPX21**:
- Save $132.60/year
- Gain 50% more CPU (3 vs 2 vCPU)
- Lose 3GB RAM (4GB vs 7GB - monitor usage)
- **Recommended**: Switch if 4GB sufficient

**Migration Process**:
1. Create Hetzner account
2. Provision CPX21 in Hillsboro, OR
3. Run setup scripts
4. Deploy agents on new instance
5. Test for 24-48 hours
6. Migrate production workload
7. Delete OVHCloud instance

**Downtime**: <30 minutes with preparation

---

## Final Recommendations

### For Max Plan Users (Majority Case):

**Best Choice**: **Hetzner CPX21** ($9.99/mo)
- Perfect for Max Plan rate limits (~225 msg/5hrs)
- Dedicated resources ensure consistent performance
- 4GB RAM sufficient for 3-5 agents
- 3 vCPUs handle concurrent agent tasks

**Total Cost**: $109.99/mo ($100 Max + $9.99 VM)

### For API Key Users (Heavy Usage):

**Best Choice**: **Hetzner CPX31** ($17.99/mo)
- 8GB RAM for 10-20+ agents
- 4 vCPUs for more parallel execution
- 160GB storage for extensive logging

**Total Cost**: $17.99/mo VM + variable API costs

### For Extreme Budget:

**Best Choice**: **Hetzner CPX11** ($4.90/mo)
- Cheapest dedicated option
- Sufficient for 1-2 agents
- Can upgrade to CPX21 if needed

**Total Cost**: $104.90/mo ($100 Max + $4.90 VM)
**Note**: Monitor RAM usage closely!

---

## Key Learnings

### Journey Summary:

1. **Started**: OVHCloud for LA Local Zone
2. **Discovered**: Location doesn't matter for API-bound agents
3. **Analyzed**: Hetzner offers better value
4. **Decided**: Hetzner CPX21 is optimal

### Lessons Learned:

✅ **Challenge assumptions**: "Local" isn't always better
✅ **Understand bottlenecks**: API latency >> network latency
✅ **Optimize for value**: Dedicated resources beat shared at similar price
✅ **Follow community**: Pieter Levels' choices are data-driven
✅ **Data over intuition**: Measure and analyze before deciding

---

## Next Steps

**Deploy on Hetzner CPX21**:
1. Create Hetzner account: https://www.hetzner.com/cloud
2. Provision CPX21 instance in Hillsboro, OR
3. Deploy using `IMPLEMENTATION.md` guide
4. Monitor for 7 days
5. Enjoy better performance at lower cost

**Specs**: 3 vCPU, 4GB RAM, 80GB SSD
**Cost**: $9.99/mo ($109.99 total with Max Plan)
**Savings**: $37.92/year vs OVHCloud D2-4
**Quality**: Dedicated resources, predictable performance

---

**Document Version**: 2.0 (Consolidated)
**Last Updated**: October 2025
**Author**: Chris Ren
**Decision**: Hetzner CPX21 over OVHCloud
**Methodology**: Data-driven cost/performance optimization
**Validated By**: Community best practices, production deployments
