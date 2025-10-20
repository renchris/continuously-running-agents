# Cloud Provider Comparison: OVHCloud vs Hetzner

## Executive Summary

**Initial Choice**: OVHCloud (for LA Local Zone proximity)

**Final Recommendation**: **Hetzner CPX21** in Hillsboro, OR

**Reason**: Location doesn't matter for API-bound agent workloads. Hetzner offers better value: dedicated resources, 50% more CPU, 60% more storage, and lower cost.

**Savings**: $37.92/year vs OVHCloud D2-4, $228/year vs OVHCloud B2-7

---

## Decision Journey

### Phase 1: Initial Assumption (Incorrect)

**Assumption**: "Closer datacenter = better performance for agents"

**Reasoning**:
- LA Local Zone seemed ideal (user in LA area)
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

## Detailed Comparison

### OVHCloud Options (Oregon/Standard Zones)

| Instance | vCPU | RAM | Storage | Resources | Location | Price/mo | Annual |
|----------|------|-----|---------|-----------|----------|----------|--------|
| **D2-4** (Discovery) | 2 | 4 GB | 50 GB NVMe | **Shared** | Oregon | $13.15 | $157.80 |
| **B2-7** (General) | 2 | 7 GB | 50 GB SSD | Dedicated | Oregon | $29.04 | $348.48 |
| **B3-8** (New Gen) | 2 | 8 GB | 50 GB NVMe | Dedicated | **LA Local** | $36.58 | $438.96 |

**Notes**:
- D2-4: Shared resources, "Discovery" tier (test/dev quality)
- B2-7: Older generation (2.0 GHz)
- B3-8: Only available in LA Local Zone (premium pricing)

### Hetzner Options (US Locations)

| Instance | vCPU | RAM | Storage | Resources | Location | Price/mo | Annual |
|----------|------|-----|---------|-----------|----------|----------|--------|
| **CPX11** | 2 | 2 GB | 40 GB SSD | **Dedicated** | OR, VA | $4.90 | $58.80 |
| **CPX21** ⭐ | **3** | 4 GB | 80 GB SSD | **Dedicated** | OR, VA | $9.99 | $119.88 |
| **CPX31** | 4 | 8 GB | 160 GB SSD | **Dedicated** | OR, VA | $17.99 | $215.88 |

**Notes**:
- All CPX instances: Dedicated AMD EPYC vCPUs
- Predictable, consistent performance
- Available in Hillsboro, OR and Ashburn, VA
- Community-proven reliability

---

## Head-to-Head: Best Options

### Budget Option Comparison

| Feature | **Hetzner CPX11** | OVHCloud D2-4 |
|---------|-------------------|---------------|
| **vCPU** | 2 dedicated AMD | 2 shared |
| **RAM** | 2 GB | 4 GB ✅ |
| **Storage** | 40 GB | 50 GB ✅ |
| **Resources** | **Dedicated** ✅ | Shared |
| **Performance** | **Predictable** ✅ | Variable |
| **Price/mo** | **$4.90** ✅ | $13.15 |
| **Price/yr** | **$58.80** ✅ | $157.80 |
| **Savings** | **-$99/yr** ✅ | baseline |
| **Total w/ Max** | $1,258.80 | $1,357.80 |

**Winner**: Hetzner CPX11 (but RAM might be tight)

### Recommended Option Comparison ⭐

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
| **Total w/ Max** | **$1,319.88** ✅ | $1,357.80 | $1,548.48 |

**Winner**: **Hetzner CPX21** - Best value, dedicated resources, more CPU, more storage

*OVHCloud has no explicit traffic limits but may throttle excessive usage

### Premium Option Comparison

| Feature | **Hetzner CPX31** | OVHCloud B2-7 | OVHCloud B3-8 |
|---------|-------------------|---------------|---------------|
| **vCPU** | **4 dedicated** ✅ | 2 dedicated | 2 dedicated |
| **RAM** | 8 GB | 7 GB | 8 GB |
| **Storage** | **160 GB** ✅ | 50 GB | 50 GB |
| **CPU Speed** | AMD EPYC | 2.0 GHz | **2.3 GHz** ✅ |
| **Resources** | Dedicated | Dedicated | Dedicated |
| **Storage Type** | SSD | SSD | **NVMe** ✅ |
| **Location** | OR, VA | OR | **LA Local** ✅ |
| **Price/mo** | **$17.99** ✅ | $29.04 | $36.58 |
| **Price/yr** | **$215.88** ✅ | $348.48 | $438.96 |
| **Savings** | **-$132.60/yr** ✅ | baseline | +$90.48/yr |
| **Total w/ Max** | **$1,415.88** ✅ | $1,548.48 | $1,638.96 |

**Winner**: **Hetzner CPX31** if you need more power (but likely overkill for Max Plan limits)

---

## Cost Analysis: All Options with Max Plan

| Provider | Instance | Resources | vCPU | RAM | Storage | VM/mo | Max/mo | **Total/mo** | **Total/yr** | Savings |
|----------|----------|-----------|------|-----|---------|-------|--------|--------------|--------------|---------|
| **Hetzner** | **CPX21** | **Dedicated** | **3** | 4 GB | **80 GB** | **$9.99** | $100 | **$109.99** | **$1,319.88** | **baseline** ⭐ |
| Hetzner | CPX11 | Dedicated | 2 | 2 GB | 40 GB | $4.90 | $100 | $104.90 | $1,258.80 | -$61.08 ⚠️ low RAM |
| OVHCloud | D2-4 | **Shared** | 2 | 4 GB | 50 GB | $13.15 | $100 | $113.15 | $1,357.80 | +$37.92 |
| Hetzner | CPX31 | Dedicated | 4 | 8 GB | 160 GB | $17.99 | $100 | $117.99 | $1,415.88 | +$96.00 |
| OVHCloud | B2-7 | Dedicated | 2 | 7 GB | 50 GB | $29.04 | $100 | $129.04 | $1,548.48 | +$228.60 |
| OVHCloud | B3-8 | Dedicated | 2 | 8 GB | 50 GB NVMe | $36.58 | $100 | $136.58 | $1,638.96 | +$319.08 |

**Clear Winner**: **Hetzner CPX21** at $1,319.88/year

---

## Why OVHCloud Was Initially Chosen (Now Invalidated)

### Original Reasoning:

1. **LA Local Zone** - Thought proximity mattered
2. **Marketing Appeal** - "Local" sounded premium
3. **Assumption** - Lower latency = better agent performance
4. **Price Acceptance** - Willing to pay premium for "local"

### Why This Was Wrong:

1. **API Latency Dominates**: 200-2000ms API time >> 30ms network difference
2. **I/O-Bound Workload**: Agents wait for API, not network
3. **Oregon = West Coast**: Still close enough (not East Coast)
4. **Cost Premium Unjustified**: Paying $23-35/mo for 30ms is poor value
5. **Shared Resources**: D2-4 is Discovery tier (variable performance)

### Lessons Learned:

✅ **Understand your bottleneck**: Identify what actually limits performance
✅ **Measure, don't assume**: API latency matters, not datacenter proximity
✅ **Question premiums**: "Local" isn't worth 2-3x cost for async workloads
✅ **Community wisdom**: Pieter Levels uses Hetzner for a reason
✅ **Dedicated > Shared**: For production workloads, pay for predictable resources

---

## Why Hetzner CPX21 is Superior

### 1. Better Performance

**CPU**:
- ✅ **3 vCPUs** vs 2 (50% more)
- ✅ **Dedicated** AMD EPYC processors
- ✅ **Predictable** performance (no sharing)
- ✅ **Sustained** high CPU available

**Storage**:
- ✅ **80 GB** vs 50 GB (60% more)
- ✅ More room for logs, backups, projects
- ✅ Can run more agents before storage issues

**Network**:
- ✅ **2 TB included traffic** (generous)
- ✅ Same Oregon location option as OVHCloud
- ✅ Low latency to Anthropic API

### 2. Lower Cost

**Savings**:
- vs OVHCloud D2-4: **-$37.92/year** (3% cheaper)
- vs OVHCloud B2-7: **-$228.60/year** (17% cheaper)
- vs OVHCloud B3-8: **-$319.08/year** (24% cheaper)

**Value**:
- Better specs AND cheaper than D2-4
- Dedicated resources vs D2-4's shared
- More CPU than any OVHCloud option under $30/mo

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
- ✅ $3M/year businesses run on €4.99/mo Hetzner VPS

**Reputation**:
- Known for excellent price/performance
- Strong EU presence, expanding US
- Good support and documentation
- No surprise fees or throttling

### 5. Flexibility

**Locations**:
- ✅ Hillsboro, OR (same as OVHCloud option)
- ✅ Ashburn, VA (East Coast alternative)
- ✅ Multiple EU locations (if needed later)

**Scaling**:
- Easy upgrade path: CPX21 → CPX31 → CPX41
- Resize with minimal downtime
- Add volumes, networks, load balancers

---

## Instance Selection Guide

### Choose **Hetzner CPX11** ($4.90/mo) if:

- ✅ Tightest possible budget
- ✅ Running 1-2 agents max
- ✅ Minimal logging/monitoring needs
- ✅ Can tolerate 2GB RAM limit
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
- ✅ Switching to API key (not Max Plan)
- ✅ Need 8GB RAM for intensive workloads
- ✅ Want maximum headroom
- ⚠️ Likely overkill for Max Plan limits

### Choose **OVHCloud B3-8** ($36.58/mo) if:

- ✅ Must have LA Local Zone (rare requirement)
- ✅ Need latest generation hardware
- ✅ NVMe storage is critical
- ✅ Cost is not a concern
- ❌ **Generally not recommended** for agent workloads

---

## Migration Considerations

### If Already on OVHCloud:

**From D2-4 to Hetzner CPX21**:
- Save $37.92/year
- Gain dedicated resources
- Gain 50% more CPU
- Gain 60% more storage
- **Recommended**: Switch immediately

**From B2-7 to Hetzner CPX21**:
- Save $228.60/year!
- Gain 50% more CPU (3 vs 2 vCPU)
- Gain 60% more storage
- Same RAM (4GB vs 7GB - check if sufficient)
- **Recommended**: Switch if 4GB RAM is sufficient

**From B3-8 to Hetzner CPX21**:
- Save $319.08/year!!
- Lose 1 vCPU (2 → 3, net +1)
- Lose 4GB RAM (8GB → 4GB)
- Gain 30GB storage (50GB → 80GB)
- **Recommended**: Switch unless you specifically need 8GB RAM

### Migration Process:

1. Create Hetzner account
2. Provision CPX21 in Hillsboro, OR
3. Run setup scripts
4. Deploy agents on new instance
5. Test for 24-48 hours
6. Migrate production workload
7. Delete OVHCloud instance
8. **Downtime**: <30 minutes with preparation

---

## Final Recommendations by Use Case

### For Max Plan Users (Majority Case):

**Best Choice**: **Hetzner CPX21** ($9.99/mo)
- Perfect for Max Plan rate limits (~225 msg/5hrs)
- Dedicated resources ensure consistent performance
- 4GB RAM sufficient for 3-5 agents
- 3 vCPUs handle concurrent agent tasks
- 80GB storage for logs and backups

**Total Cost**: $109.99/mo ($100 Max + $9.99 VM)

### For API Key Users (Heavy Usage):

**Best Choice**: **Hetzner CPX31** ($17.99/mo)
- 8GB RAM for 10-20+ agents
- 4 vCPUs for more parallel execution
- 160GB storage for extensive logging
- Better value than OVHCloud B2-7 or B3-8

**Total Cost**: $17.99/mo VM + variable API costs

### For Extreme Budget (Solo Hackers):

**Best Choice**: **Hetzner CPX11** ($4.90/mo)
- Cheapest dedicated option
- Sufficient for 1-2 agents
- Can upgrade to CPX21 if needed
- Still better than OVHCloud D2-4 (dedicated vs shared)

**Total Cost**: $104.90/mo ($100 Max + $4.90 VM)

**Note**: Monitor RAM usage closely!

---

## Location Decision Matrix

### When Location Doesn't Matter:

✅ API-bound workloads (Claude Code agents)
✅ Background processing (cron jobs, workers)
✅ Batch operations
✅ Async task queues
✅ CI/CD pipelines
✅ Backup/archival systems

**For these**: Choose best value provider (Hetzner)

### When Location Might Matter:

⚠️ Real-time user-facing apps (<200ms requirement)
⚠️ WebSocket/streaming applications
⚠️ High-frequency database queries
⚠️ Microservices with chatty inter-service calls
⚠️ Content delivery (use CDN instead)

**For these**: Consider proximity, but test first

### When Location Definitely Matters:

❌ Online gaming (need <50ms)
❌ Video streaming/conferencing
❌ Financial trading systems
❌ Real-time collaboration tools
❌ IoT device gateways

**For these**: Pay premium for local datacenter

**Claude Code agents**: Location doesn't matter ✅

---

## Testing Validation

### Pre-Deployment Tests (Optional):

**Latency Test**:
```bash
# From your Mac to Hetzner
ping -c 10 your_hetzner_ip

# Expected: 10-20ms (Hillsboro, OR)
# Acceptable: <50ms
```

**API Latency Test** (from Hetzner instance):
```bash
# After deployment
time curl -I https://api.anthropic.com

# Expected: 20-60ms
# Compare with OVHCloud if testing both
```

### Post-Deployment Validation:

**Week 1**: Monitor everything
```bash
bash ~/scripts/monitoring/dashboard.sh
```

**Week 1 Analysis**:
```bash
bash ~/scripts/monitoring/analyze-usage.sh 7
```

**Compare**:
- CPU usage (should be <50% on CPX21)
- RAM usage (should be <75% with 3-5 agents)
- API response times (should be 200-2000ms, network negligible)
- Cost (track Max Plan message consumption)

---

## Conclusion

### Journey Summary:

1. **Started**: OVHCloud for LA Local Zone
2. **Discovered**: Location doesn't matter for API-bound agents
3. **Analyzed**: Hetzner offers better value
4. **Decided**: Hetzner CPX21 is optimal

### Key Learnings:

✅ **Challenge assumptions**: "Local" isn't always better
✅ **Understand bottlenecks**: API latency >> network latency
✅ **Optimize for value**: Dedicated resources beat shared at similar price
✅ **Follow community**: Pieter Levels' choices are data-driven
✅ **Data over intuition**: Measure and analyze before deciding

### Final Recommendation:

**Deploy on Hetzner CPX21**
- Location: Hillsboro, OR
- Specs: 3 vCPU, 4GB RAM, 80GB SSD
- Cost: $9.99/mo ($109.99 total with Max Plan)
- Savings: $37.92/year vs OVHCloud D2-4
- Quality: Dedicated resources, predictable performance

**Next Steps**:
1. Create Hetzner account: https://www.hetzner.com/cloud
2. Provision CPX21 instance in Hillsboro, OR
3. Deploy using existing setup scripts
4. Monitor for 7 days
5. Enjoy better performance at lower cost

---

**Document Version**: 1.0
**Last Updated**: October 18, 2025
**Author**: Chris Ren
**Decision**: Hetzner CPX21 over OVHCloud D2-4/B2-7/B3-8
**Methodology**: Data-driven cost/performance optimization
**Validated By**: Community best practices (Pieter Levels, vibecoding)
