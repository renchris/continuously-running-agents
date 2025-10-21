# LLM Provider Setup for Continuous Agents

## Overview

This guide covers how to set up your LLM provider (Anthropic API) for running continuously running Claude Code agents. It addresses key architecture decisions: API key management, subscription tiers, single vs multiple VMs, and integration with cloud providers like OVHCloud.

**Key Insight**: One API key can serve unlimited agents on one or multiple VMs. Agent work is I/O-bound (API calls), not CPU-intensive, so a single VM can run 50+ parallel agents.

## Quick Decision Guide

### Your Situation

If you have:
- **OVHCloud instance** (or similar VPS)
- **Anthropic Max $100/mo subscription** (or considering it)
- **Want to run multiple agents** (5-50+)

**Recommendation**: Use single OVHCloud VM + single API key from Max subscription. This setup can handle 20-50 parallel agents for $105-130/mo total (VM + API).

## API Key Architecture

### One Key for All Agents

**How it works**:
- Anthropic billing is **per-token usage**, not per VM or per agent
- Single API key can be used across multiple VMs and agents simultaneously
- Rate limits apply to the API key, not individual agents
- Cost is aggregated across all usage on that key

**Example Setup**:
```bash
# On your VPS
export ANTHROPIC_API_KEY="sk-ant-api03-xxx"

# All agents share this key
tmux new -s agent-1 "claude -p 'Work on frontend'"
tmux new -s agent-2 "claude -p 'Work on backend'"
tmux new -s agent-3 "claude -p 'Write tests'"
# ... 50 more agents, all using same key
```

### When to Use Multiple Keys

Use multiple API keys only if:
- **Multiple customers/projects** - Separate billing needed
- **Hit rate limits** - Rare with Max subscription (very high limits)
- **Need isolation** - Different teams/departments
- **Testing environments** - Separate dev/staging/prod usage tracking

**For most use cases**: Single API key is sufficient.

## Anthropic Subscription Tiers

### Tier Comparison (2025)

| Plan | Cost/Month | Usage | Best For |
|------|-----------|-------|----------|
| **Free** | $0 | Very limited | Quick testing |
| **Pro** | $20 | ~45 messages/5hrs | Light development, learning |
| **Max** | $100 | 5× Pro (~unlimited) | Heavy continuous agents |
| **Max+** | $200 | 20× Pro | Very heavy workloads |
| **API (Pay-per-use)** | Variable | Unlimited | Low/unpredictable usage |

### Subscription vs Pay-Per-Use Decision Matrix

| Monthly Expected API Cost | Recommendation | Why |
|--------------------------|----------------|-----|
| < $20 | Pay-per-use API | More flexible, cheaper |
| $20-$40 | Pro ($20) or API | Break-even point, preference |
| $40-$100 | Max ($100) | Better value, unlimited peace of mind |
| $100-$200 | Max ($100-200) | Essential for heavy use |
| > $200 | Enterprise or optimize | Need to review usage patterns |

### Break-Even Analysis

**Pro Plan ($20/mo)**:
- Unlimited messages within rate limits
- Equivalent to ~$20 of API usage
- Rate limits: ~45 messages per 5 hours

```
Break-even calculation:
$20 / month = ~600,000 Sonnet 4 input tokens + 120,000 output tokens
If you exceed this, Pro is cheaper than API
```

**Max Plan ($100/mo)**:
- 5× Pro usage (essentially unlimited for most use cases)
- Equivalent to ~$100 of API usage
- Rate limits: ~225 messages per 5 hours

```
Break-even calculation:
$100 / month = ~3M Sonnet 4 input tokens + 600K output tokens
For continuous agents, Max is almost always better value
```

### Subscription Advantages

✅ **Predictable costs** - No surprise bills
✅ **Unlimited usage** - Within generous rate limits
✅ **No mental overhead** - Don't count tokens
✅ **Higher rate limits** - More parallel agents
✅ **Better for continuous agents** - 24/7 operation

❌ **Pay upfront** - Even if low usage
❌ **Wasted if idle** - Paying for unused capacity

### API Pay-Per-Use Advantages

✅ **Pay only for what you use**
✅ **No upfront commitment**
✅ **Better for intermittent use**
✅ **Scale to zero** - No cost when idle

❌ **Unpredictable costs** - Can spike unexpectedly
❌ **Mental overhead** - Need to monitor usage
❌ **Lower rate limits** - Fewer parallel agents

## Single VM vs Multiple VMs

### Resource Requirements per Agent Count

| Agent Count | Recommended RAM | Recommended CPU | Recommended Storage | Monthly VM Cost |
|-------------|----------------|-----------------|-------------------|----------------|
| 1-5 agents | 2GB | 1-2 vCPU | 20GB SSD | $5-8 |
| 5-10 agents | 4GB | 2 vCPU | 40GB SSD | $8-15 |
| 10-20 agents | 8GB | 2-4 vCPU | 50GB SSD | $15-30 |
| 20-50 agents | 16GB | 4 vCPU | 100GB SSD | $30-50 |
| 50+ agents | 32GB+ | 8+ vCPU | 200GB+ SSD | $50-100+ |

**Why agents are light on resources**:
- Agents spend most time **waiting for API responses** (I/O-bound)
- Very low CPU usage (just text processing)
- Moderate RAM usage (mostly context buffering)
- Network bandwidth is the primary constraint

### Single VM Architecture

**Recommended for most users**: Start with single VM and scale vertically.

```bash
# Single OVHCloud instance (8GB RAM, 2 vCPU)
# Running 15 parallel agents in tmux

tmux new -s pm "claude -p 'PM: coordinate other agents'"

# Worker agents
for i in {1..14}; do
    tmux new -s agent-$i "claude -p 'work on assigned task'"
done

# All agents share:
# - Same API key
# - Same VM resources
# - Coordinated via tmux or coordination protocol
```

**Advantages**:
- ✅ Simple to manage - Single server to maintain
- ✅ Lower total cost - One VM, one IP, one set of tools
- ✅ Easy coordination - Agents can share files directly
- ✅ Resource efficiency - Shared OS, libraries, caching

**Disadvantages**:
- ❌ Single point of failure - VM down = all agents down
- ❌ Resource contention - Agents compete for RAM/CPU
- ❌ Scaling limits - Eventually hit VM size limits

### Multiple VM Architecture

**Use when**:
- Need more than 50 agents
- Want fault tolerance (one VM down ≠ all agents down)
- Different projects require isolation
- Hitting single VM resource limits

```bash
# VM 1: OVHCloud b2-7 (7GB RAM)
# - 20 agents for Project A

# VM 2: Hetzner CPX21 (4GB RAM)
# - 10 agents for Project B

# VM 3: DigitalOcean $15 droplet (2GB RAM)
# - 5 agents for Project C

# All use same API key, but isolated execution
```

**Advantages**:
- ✅ Fault tolerance - One failure doesn't affect others
- ✅ Better isolation - Projects/teams separated
- ✅ Flexible scaling - Add VMs as needed
- ✅ Geographic distribution - Agents in different regions

**Disadvantages**:
- ❌ More complex management - Multiple servers to maintain
- ❌ Higher cost - Multiple VMs, IPs, overhead
- ❌ Coordination challenges - Agents on different VMs need network coordination
- ❌ Resource inefficiency - Each VM has OS overhead

### Decision Tree

```
Start here:
│
├─ Running < 10 agents?
│  └─ YES → Single VM (2-4GB RAM)
│  └─ NO → Continue
│
├─ Running 10-20 agents?
│  └─ YES → Single VM (8GB RAM)
│  └─ NO → Continue
│
├─ Running 20-50 agents?
│  └─ YES → Single VM (16GB RAM) or 2 VMs (8GB each)
│  └─ NO → Continue
│
├─ Running 50+ agents?
│  └─ YES → Multiple VMs (Agent Farm architecture)
│           See: 07-examples.md#example-9-agent-farm-50-parallel-agents
```

## OVHCloud Integration

### Why OVHCloud

- **Competitive pricing**: $5-8/mo for entry-level instances
- **Global presence**: US, Europe, Asia-Pacific data centers
- **Flexible billing**: Hourly or monthly
- **OpenStack-based**: Standard cloud infrastructure

### OVHCloud Instance Types for Agents

| Instance Type | vCPU | RAM | Storage | Price/Mo | Agent Capacity |
|--------------|------|-----|---------|----------|----------------|
| **s1-2** | 1 | 2GB | 10GB SSD | ~$5 | 1-5 agents |
| **s1-4** | 1 | 4GB | 20GB SSD | ~$8 | 5-10 agents |
| **b2-7** | 2 | 7GB | 50GB SSD | ~$15 | 10-20 agents |
| **b2-15** | 4 | 15GB | 100GB SSD | ~$30 | 20-40 agents |
| **b2-30** | 8 | 30GB | 200GB SSD | ~$60 | 40-80 agents |

### Setting Up OVHCloud Instance

#### 1. Create Public Cloud Project

```bash
# Access OVHCloud Manager
# URL: https://us.ovhcloud.com/manager/

# Navigate to: Public Cloud → Create a project
# Note your project ID (e.g., e7c1dac8ed8d4db1b888070f285f404e)
```

#### 2. Launch Instance

**Via Web Console**:
1. Go to "Instances" → "Create an instance"
2. Select region (US-East, EU-West, etc.)
3. Choose instance type (recommended: **s1-4** or **b2-7**)
4. Select OS: **Ubuntu 24.04 LTS**
5. Add SSH key (create locally: `ssh-keygen -t ed25519`)
6. Set instance name (e.g., `claude-agent-primary`)
7. Click "Create"

**Via OpenStack CLI** (Advanced):
```bash
# Install OpenStack CLI
pip install python-openstackclient

# Download RC file from OVHCloud console
source openrc.sh

# Create instance
openstack server create \
  --image "Ubuntu 24.04" \
  --flavor s1-4 \
  --key-name my-ssh-key \
  --network Ext-Net \
  claude-agent-primary

# Get IP address
openstack server show claude-agent-primary -c addresses

#### OVHCloud Setup Walkthrough (Complete First-Time Guide - 15 minutes)

**For users who have never used OVHCloud before**. This walkthrough provides step-by-step instructions from account creation to first SSH connection.

##### Step 1: Create Account (2 minutes)

1. Go to [https://us.ovhcloud.com/public-cloud/](https://us.ovhcloud.com/public-cloud/)
2. Click **"Start Now"** or **"Sign Up"**
3. Fill in:
   - Email address
   - Password (strong password required)
   - Country/region
4. Verify email (check inbox for verification link)
5. Log in at [https://us.ovhcloud.com/manager/](https://us.ovhcloud.com/manager/)

**Validation**: You should see the OVHCloud Manager dashboard

##### Step 2: Add Payment Method (2 minutes)

1. In OVHCloud Manager, go to **Billing** → **Payment Methods**
2. Click **"Add a payment method"**
3. Choose:
   - **Credit Card** (Visa/Mastercard/Amex), OR
   - **PayPal**
4. Enter payment details and save
5. (Optional) Set as default payment method

**Note**: OVHCloud may place a small temporary hold ($1-2) to verify the card

**Validation**: Payment method shows "Active" status

##### Step 3: Create Public Cloud Project (1 minute)

1. In OVHCloud Manager, click **"Public Cloud"** in left sidebar
2. Click **"Create a project"**
3. Enter project name (e.g., "Claude Agents Production")
4. Confirm billing contact
5. Click **"Create project"**

**Validation**: You'll see a project ID (e.g., )

##### Step 4: Generate SSH Key (if you don't have one) (2 minutes)

Run this on your **local machine** (not in OVHCloud):

```bash
# Generate SSH key pair
ssh-keygen -t ed25519 -C "your-email@example.com" -f ~/.ssh/ovhcloud_claude

# Expected output:
# Generating public/private ed25519 key pair.
# Your identification has been saved in /Users/you/.ssh/ovhcloud_claude
# Your public key has been saved in /Users/you/.ssh/ovhcloud_claude.pub

# Display public key (you'll need this in next step)
cat ~/.ssh/ovhcloud_claude.pub

# Expected output:
# ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... your-email@example.com
```

**Copy the public key** (starts with ) - you'll paste it in Step 5

##### Step 5: Create Instance (5 minutes)

1. In your Public Cloud project, click **"Instances"** → **"Create an instance"**

2. **Select Region**:
   - US-East (Vint Hill, VA) - Best for US users
   - EU-West (Gravelines, France) - Best for EU users
   - CA-East (Beauharnois, Canada) - Best for Canada
   
   *Tip: Choose closest region to reduce latency*

3. **Choose Instance Type**:
   - Recommended: **General Purpose - d2-2** 
   - Specs: 2 vCPU, 4 GB RAM, 25 GB SSD
   - Cost: ~$0.015/hour ≈ **$10/month**
   
   *Alternatives*:
   - Budget: **b2-7** (2 vCPU, 7 GB RAM) - $0.013/hour
   - Performance: **s1-4** (1 vCPU, 4 GB RAM) - $0.023/hour

4. **Select Operating System**:
   - Choose **"Ubuntu 24.04 LTS"** (recommended)
   - Or **"Ubuntu 22.04 LTS"** (also works well)

5. **Add SSH Key**:
   - Click **"Add a key"**
   - Paste your public key from Step 4
   - Give it a name (e.g., "my-laptop-key")
   - Click **"Add this key"**

6. **Configure Instance**:
   - Instance name: 
   - Leave other settings as default
   - Click **"Create instance"**

7. **Wait for Provisioning** (~2 minutes)
   - Status will change:  → 
   - IP address will appear when ready

**Validation**: Instance shows "Active" with an IP address (e.g., )

##### Step 6: First SSH Connection (3 minutes)

Once instance is **Active**:

```bash
# Connect via SSH (replace IP with your instance's IP)
ssh -i ~/.ssh/ovhcloud_claude ubuntu@51.195.xxx.xxx

# First connection will ask to verify fingerprint:
# The authenticity of host '51.195.xxx.xxx' can't be established.
# ED25519 key fingerprint is SHA256:xxxxxxxxxxxxx.
# Are you sure you want to continue connecting (yes/no)?

# Type: yes

# Expected output:
# Warning: Permanently added '51.195.xxx.xxx' (ED25519) to known hosts.
# Welcome to Ubuntu 24.04 LTS
# ubuntu@claude-agent-01:~$
```

**Validation Commands**:

```bash
# Check system info
uname -a
# Expected: Linux claude-agent-01 5.15.0-xxx-generic ... x86_64 GNU/Linux

# Check resources
free -h
# Expected: Total memory around 3.9Gi

# Check disk space
df -h /
# Expected: Avail around 20G

# Check internet connectivity
curl -I https://api.anthropic.com
# Expected: HTTP/2 200
```

**If all validations pass, your OVHCloud instance is ready!**

##### Cost Estimate

- **d2-2 instance**: $0.015/hour × 730 hours/month = **$10.95/month**
- **Storage** (25GB included): $0
- **Bandwidth** (1TB included): $0
- **Total estimated cost**: ~$11/month

**Next Steps**: Continue with ["03. Configure Network"](#3-configure-network) above to set up firewall rules.


#### 3. Initial Server Setup

```bash
# SSH into instance
ssh ubuntu@YOUR_INSTANCE_IP

# Update system
sudo apt update && sudo apt upgrade -y

# Install essentials
sudo apt install -y build-essential curl wget git tmux mosh htop

# Install Node.js 20.x
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Install Claude Code CLI
sudo npm install -g @anthropic-ai/claude-code

# Set API key
echo 'export ANTHROPIC_API_KEY="sk-ant-api03-xxx"' >> ~/.bashrc
source ~/.bashrc

# Verify installation
claude --version
```

#### 4. Configure Firewall

```bash
# Enable UFW firewall
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH
sudo ufw allow ssh

# Allow Mosh (for mobile access)
sudo ufw allow 60000:61000/udp

# Enable firewall
sudo ufw enable
```

#### 5. Set Up Monitoring

```bash
# Install monitoring tools
sudo apt install -y nethogs iotop

# Create monitoring script
cat > ~/monitor.sh << 'EOF'
#!/bin/bash
echo "=== System Resources ==="
free -h
echo ""
echo "=== Disk Usage ==="
df -h /
echo ""
echo "=== Active Claude Agents ==="
tmux ls 2>/dev/null || echo "No tmux sessions"
EOF

chmod +x ~/monitor.sh
```

### OVHCloud-Specific Considerations

**Networking**:
- OVHCloud uses OpenStack Neutron for networking
- Each instance gets public IPv4 by default
- Private networking available (vRack)

**Storage**:
- SSD storage included with instance
- Additional volumes available (Block Storage)
- Automatic backups available (paid add-on)

**Billing**:
- Hourly billing: Pay per hour of usage
- Monthly billing: ~50% discount vs hourly
- No upfront commitment

**Support**:
- Community support: Free
- Business support: Paid add-on
- Enterprise support: Contact sales

## Your Specific Setup: OVHCloud + Max Plan

### Recommended Configuration

Based on your situation:
- ✅ OVHCloud public cloud instance (already created)
- ✅ Anthropic Max $100/mo subscription (already have)

**Optimal setup**:
```
Infrastructure:
- OVHCloud b2-7 (2 vCPU, 7GB RAM, 50GB SSD): $15/mo
- Single instance, no need for multiple VMs initially

API:
- Anthropic Max subscription: $100/mo (unlimited usage)
- Single API key for all agents
- No need for multiple subscriptions

Total cost: $115/mo for 10-20 parallel agents
```

### Implementation Steps

#### 1. Configure Your OVHCloud Instance

```bash
# SSH to your instance
ssh ubuntu@YOUR_OVHCLOUD_IP

# Set up environment
export ANTHROPIC_API_KEY="your-max-subscription-key"
echo 'export ANTHROPIC_API_KEY="your-max-subscription-key"' >> ~/.bashrc

# Install Claude Code
npm install -g @anthropic-ai/claude-code

# Install tmux for multi-agent coordination
sudo apt install -y tmux
```

#### 2. Set Up Multi-Agent Coordination

```bash
# Create coordination directory
mkdir -p ~/agents/{logs,coordination}

# Create agent spawner script
cat > ~/spawn-agent.sh << 'EOF'
#!/bin/bash
AGENT_NAME=$1
TASK=$2

tmux new -s "$AGENT_NAME" -d "claude -p '$TASK' 2>&1 | tee ~/agents/logs/${AGENT_NAME}.log"
echo "Started agent: $AGENT_NAME"
EOF

chmod +x ~/spawn-agent.sh

# Spawn multiple agents
~/spawn-agent.sh agent-1 "Work on frontend features"
~/spawn-agent.sh agent-2 "Write comprehensive tests"
~/spawn-agent.sh agent-3 "Refactor backend API"
```

#### 3. Monitor Resource Usage

```bash
# Check resource usage
htop

# Check tmux sessions
tmux ls

# Check agent logs
tail -f ~/agents/logs/agent-1.log
```

### Scaling Path

**Current setup** (10-20 agents):
- OVHCloud b2-7: $15/mo
- Max subscription: $100/mo
- **Total: $115/mo**

**If you need 20-40 agents**:
- Upgrade to OVHCloud b2-15 (15GB RAM): $30/mo
- Keep Max subscription: $100/mo
- **Total: $130/mo**

**If you need 40+ agents**:
- Option A: Upgrade to b2-30 (30GB RAM): $60/mo + $100/mo = $160/mo
- Option B: Add second VM (b2-7): $15/mo + $15/mo + $100/mo = $130/mo
- Option C: Switch to Agent Farm architecture (see 07-examples.md)

**If usage drops significantly**:
- Downgrade to API pay-per-use
- Cancel Max subscription
- Pay only for actual token usage
- Can save $50-80/mo if usage is very low

## Rate Limit Management

### Understanding Rate Limits

Anthropic rate limits vary by subscription tier:

| Tier | Requests/Minute | Tokens/Minute | Tokens/Day |
|------|----------------|---------------|------------|
| **Free** | 5 | 25,000 | 300,000 |
| **Pro** | 50 | 100,000 | 10,000,000 |
| **Max** | 1000+ | 2,000,000+ | 100,000,000+ |

### Handling Rate Limits in Multi-Agent Setups

**With Max subscription**: Rate limits are very high, unlikely to hit them with 10-50 agents.

**If you do hit limits**:

```bash
# Add rate limit handling to agents
cat > ~/agents/rate-limit-wrapper.sh << 'EOF'
#!/bin/bash

call_claude_with_retry() {
    local max_retries=5
    local delay=2

    for i in $(seq 1 $max_retries); do
        if claude "$@" 2>&1 | tee /tmp/claude-output.txt; then
            if grep -q "rate_limit" /tmp/claude-output.txt; then
                echo "Rate limited, waiting ${delay}s..."
                sleep $delay
                delay=$((delay * 2))
            else
                return 0
            fi
        else
            return 0
        fi
    done

    echo "Max retries exceeded"
    return 1
}

call_claude_with_retry "$@"
EOF

chmod +x ~/agents/rate-limit-wrapper.sh
```

### Distributing Load Across Time

```bash
# Stagger agent starts to avoid simultaneous API calls
for i in {1..10}; do
    ~/spawn-agent.sh agent-$i "task $i"
    sleep 5  # 5 second delay between spawns
done
```

### Rate Limit Monitoring

```python
# Simple rate limit monitor
import anthropic
import time

client = anthropic.Anthropic()

def monitor_rate_limits():
    """Check if approaching rate limits"""
    try:
        # Make test call
        response = client.messages.create(
            model="claude-sonnet-4",
            max_tokens=10,
            messages=[{"role": "user", "content": "test"}]
        )

        # Check response headers for rate limit info
        # (headers available in response object)
        remaining = response.headers.get('anthropic-ratelimit-requests-remaining')

        if remaining and int(remaining) < 10:
            print(f"⚠️  Rate limit warning: {remaining} requests remaining")
            return False
        return True
    except anthropic.RateLimitError:
        print("🚫 Rate limit exceeded!")
        return False

# Run periodically
while True:
    monitor_rate_limits()
    time.sleep(60)  # Check every minute
```

## Cost Calculator

### Monthly Cost Estimator

```bash
#!/bin/bash
# cost-estimator.sh

echo "=== Continuous Agent Cost Estimator ==="
echo ""

read -p "Number of agents: " NUM_AGENTS
read -p "Hours per day active (1-24): " HOURS_DAY
read -p "API calls per hour per agent: " CALLS_HOUR

# VM cost estimation
if [ $NUM_AGENTS -le 5 ]; then
    VM_COST=8
    VM_SIZE="s1-4 (4GB RAM)"
elif [ $NUM_AGENTS -le 10 ]; then
    VM_COST=15
    VM_SIZE="b2-7 (7GB RAM)"
elif [ $NUM_AGENTS -le 20 ]; then
    VM_COST=30
    VM_SIZE="b2-15 (15GB RAM)"
else
    VM_COST=60
    VM_SIZE="b2-30 (30GB RAM)"
fi

# API cost estimation (rough)
TOTAL_CALLS=$((NUM_AGENTS * HOURS_DAY * CALLS_HOUR * 30))
ESTIMATED_API_COST=$((TOTAL_CALLS * 2 / 1000))  # Very rough estimate

echo ""
echo "--- Recommended Setup ---"
echo "VM: OVHCloud $VM_SIZE - \$$VM_COST/mo"
echo ""
echo "--- API Costs ---"
echo "Estimated calls/month: $TOTAL_CALLS"
echo "Pay-per-use estimate: ~\$$ESTIMATED_API_COST/mo"
echo ""

if [ $ESTIMATED_API_COST -lt 20 ]; then
    echo "Recommendation: Stay on pay-per-use API"
    TOTAL=$((VM_COST + ESTIMATED_API_COST))
elif [ $ESTIMATED_API_COST -lt 100 ]; then
    echo "Recommendation: Pro subscription (\$20/mo) or Max (\$100/mo)"
    TOTAL=$((VM_COST + 20))
    TOTAL_MAX=$((VM_COST + 100))
    echo "Total with Pro: \$$TOTAL/mo"
    echo "Total with Max: \$$TOTAL_MAX/mo (better value if usage grows)"
else
    echo "Recommendation: Max subscription (\$100/mo) - unlimited usage"
    TOTAL=$((VM_COST + 100))
fi

echo ""
echo "=== Total Estimated Cost: \$$TOTAL/mo ==="
```

### Break-Even Calculator for Your Max Plan

```python
# check-max-value.py
# Check if your Max $100 subscription is worth it

import os
from anthropic import Anthropic

client = Anthropic()

# Get usage for current month
usage = client.usage.get(
    start_date="2025-10-01",
    end_date="2025-10-31"
)

# Calculate what it would cost on pay-per-use
# Sonnet 4 pricing: $3/M input, $15/M output
total_input_tokens = usage.input_tokens
total_output_tokens = usage.output_tokens

input_cost = (total_input_tokens / 1_000_000) * 3
output_cost = (total_output_tokens / 1_000_000) * 15
total_payg_cost = input_cost + output_cost

max_cost = 100  # Your subscription

print(f"Your Max subscription: ${max_cost}/mo")
print(f"Pay-per-use would cost: ${total_payg_cost:.2f}/mo")
print(f"Savings: ${total_payg_cost - max_cost:.2f}/mo")

if total_payg_cost < 100:
    print("\n⚠️  Consider downgrading to pay-per-use or Pro")
else:
    print("\n✅ Max subscription is saving you money!")
```

## Migration Paths

### From Pay-Per-Use to Max Subscription

**When to migrate**:
- Monthly API costs consistently > $100
- Want predictable billing
- Planning to scale to more agents

**How to migrate**:
1. Visit: <https://console.anthropic.com/settings/plans>
2. Select "Max" plan ($100/mo)
3. Confirm subscription
4. Continue using same API key (no code changes needed)

**Impact**:
- ✅ Same API key continues working
- ✅ Higher rate limits immediately
- ✅ Unlimited usage within rate limits
- ⚠️  Billed monthly now instead of per-use

### From Max to Pay-Per-Use

**When to migrate**:
- Usage dropped significantly (< $50/mo)
- Project paused/completed
- Want to scale to zero

**How to migrate**:
1. Visit: <https://console.anthropic.com/settings/plans>
2. Cancel Max subscription
3. Enable pay-per-use billing
4. Add payment method

**Impact**:
- ✅ Only pay for actual usage
- ✅ Can scale to $0 when idle
- ⚠️  Lower rate limits
- ⚠️  Need to monitor costs

### From Single VM to Multiple VMs

**When to migrate**:
- Single VM resource-constrained (>80% RAM usage)
- Need fault tolerance
- Want to isolate different projects

**How to migrate**:
```bash
# 1. Create second OVHCloud instance
# (follow same setup as first instance)

# 2. Distribute agents across VMs
# VM 1: Agents 1-10
# VM 2: Agents 11-20

# 3. Use same API key on both VMs
# No code changes needed!

# 4. Optional: Set up coordination between VMs
# See: 02-tmux-setup.md#multi-agent-coordination-protocol
```

#### Migration Example: Single Agent to 5-Agent Fleet

**Scenario**: You have one agent running documentation work. You want to scale to 5 specialized agents for a multi-repo project.

**Before (Single Agent)**:
```bash
# One tmux session, one task
tmux new -s docs-agent "claude -p 'Update all documentation'"

# Agent works sequentially:
# 1. Updates README (30 min)
# 2. Updates API docs (45 min)
# 3. Updates deployment guide (25 min)
# 4. Fixes broken links (20 min)
# 5. Updates changelog (15 min)
# Total: ~2 hours 15 minutes
```

**After (5-Agent Fleet)**:
```bash
# Start 5 specialized agents in parallel
bash scripts/start-agent-yolo.sh 1 "Update README.md with new features"
bash scripts/start-agent-yolo.sh 2 "Update API documentation in docs/api/"
bash scripts/start-agent-yolo.sh 3 "Update deployment guide with new cloud providers"
bash scripts/start-agent-yolo.sh 4 "Fix all broken documentation cross-references"
bash scripts/start-agent-yolo.sh 5 "Update CHANGELOG.md with recent releases"

# Monitor all agents
bash scripts/monitor-agents-yolo.sh

# Same work completes in ~45 minutes (parallelized)
```

**Migration Steps**:

1. **Identify parallelizable work**:
   ```bash
   # List all documentation tasks
   ls docs/
   # Output:
   # README.md, api/, deployment/, troubleshooting/, changelog/
   ```

2. **Create task distribution plan**:
   ```markdown
   Agent 1: README.md updates (core project docs)
   Agent 2: API documentation (technical reference)
   Agent 3: Deployment guides (infrastructure)
   Agent 4: Cross-reference fixes (maintenance)
   Agent 5: Changelog maintenance (version tracking)
   ```

3. **Launch agents with specific scopes**:
   ```bash
   #!/bin/bash
   # launch-doc-fleet.sh

   # Agent 1: Core documentation
   bash scripts/start-agent-yolo.sh 1 \
     "Update README.md: add new features from v2.0, improve getting started section"

   # Agent 2: API docs
   bash scripts/start-agent-yolo.sh 2 \
     "Update docs/api/: document new endpoints, add code examples, fix outdated examples"

   # Agent 3: Deployment
   bash scripts/start-agent-yolo.sh 3 \
     "Update docs/deployment/: add Hetzner provider, update OVHCloud pricing, add cost calculator"

   # Agent 4: Maintenance
   bash scripts/start-agent-yolo.sh 4 \
     "Fix broken cross-references: scan all .md files, update internal links, verify external URLs"

   # Agent 5: Changelog
   bash scripts/start-agent-yolo.sh 5 \
     "Update CHANGELOG.md: add entries for v2.0 release, follow Keep a Changelog format"
   ```

4. **Monitor completion**:
   ```bash
   # Watch all agent sessions
   watch -n 5 'tmux list-sessions | grep agent-yolo'

   # Check resource usage
   tail -f ~/agents/logs/resource-usage.log

   # View individual agent progress
   tmux attach -t agent-yolo-1  # Ctrl+b d to detach
   ```

5. **Collect results**:
   ```bash
   # After agents complete (or hit 8-hour timeout)
   # Review git changes from all agents
   git status
   git diff

   # Create single PR with all documentation updates
   git checkout -b docs/multi-agent-update-v2.0
   git add docs/ README.md CHANGELOG.md
   git commit -m "docs: comprehensive v2.0 documentation update

   - Update README.md with new features
   - Add Hetzner provider to deployment guide
   - Fix 47 broken cross-references
   - Document new API endpoints
   - Add CHANGELOG entries for v2.0"

   gh pr create --title "docs: comprehensive v2.0 documentation update" \
     --body "Coordinated update across 5 agents. See commit message for details."
   ```

**Key Learnings**:
- **Time savings**: 2h 15m → 45m (3x faster)
- **Cost**: 5 agents × 45 min = ~3.75 agent-hours total work
- **Coordination**: Agents work independently, human merges results
- **Resource usage**: 5 × 2GB RAM = 10GB total (ensure VM has 16GB+)

**When NOT to parallelize**:
- Tasks with dependencies (Agent 2 needs Agent 1's output)
- Small tasks (< 15 minutes - overhead not worth it)
- Tasks requiring deep context (better for single agent with full codebase understanding)

## Troubleshooting

### Issue: Rate Limit Errors

**Symptoms**:
```
Error: rate_limit_error
```

**Solutions**:
1. Check current tier limits
2. Upgrade to Max subscription for higher limits
3. Add exponential backoff retry logic
4. Stagger agent API calls

### Issue: High API Costs

**Symptoms**:
- Unexpected high bills
- Usage >> expected

**Solutions**:
1. Enable prompt caching (see 05-cost-optimization.md)
2. Check for infinite loops (agent repeating same failed action)
3. Use Haiku for simple tasks
4. Add usage monitoring and alerts
5. Consider Max subscription for fixed cost

### Issue: VM Resource Exhaustion

**Symptoms**:
```
Cannot allocate memory
OOMKilled
Swap usage high
```

**Solutions**:
1. Reduce number of parallel agents
2. Upgrade VM to larger instance
3. Add swap space (temporary):
   ```bash
   sudo fallocate -l 4G /swapfile
   sudo chmod 600 /swapfile
   sudo mkswap /swapfile
   sudo swapon /swapfile
   ```
4. Split agents across multiple VMs

### Issue: API Key Not Working

**Symptoms**:
```
Error: authentication_error
Invalid API key
```

**Solutions**:
1. Verify key is correct: `echo $ANTHROPIC_API_KEY`
2. Check key has no extra spaces/newlines
3. Verify subscription is active
4. Try regenerating API key in console

## Best Practices Summary

### ✅ Do This

- Start with single OVHCloud VM + Max subscription
- Use single API key for all agents
- Enable prompt caching immediately
- Monitor resource usage weekly
- Set up cost alerts
- Use tmux for multi-agent coordination
- Scale vertically before horizontally

### ❌ Avoid This

- Don't create multiple API keys unless absolutely needed
- Don't use multiple Pro subscriptions (wasteful)
- Don't skip cost monitoring
- Don't run agents without rate limit handling
- Don't over-provision VMs (start small, scale up)
- Don't expose API keys in git/logs

## Next Steps

After setting up your LLM provider:

1. **Set up tmux coordination** → See `02-tmux-setup.md`
2. **Configure remote access** → See `03-remote-access.md`
3. **Implement cost optimization** → See `05-cost-optimization.md`
4. **Review security hardening** → See `06-security.md`
5. **Study working examples** → See `07-examples.md`

## References

- OVHCloud Public Cloud: <https://www.ovhcloud.com/en/public-cloud/>
- OVHCloud Manager: <https://us.ovhcloud.com/manager/>
- Anthropic Pricing: <https://www.anthropic.com/pricing>
- Anthropic Console: <https://console.anthropic.com/>
- Claude Code Documentation: <https://docs.anthropic.com/claude-code>

---

**Last Updated**: October 15, 2025
**Tested On**: OVHCloud s1-4, b2-7 instances with Anthropic Max subscription
