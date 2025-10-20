# The $2 Latency Test: EU vs US Infrastructure Decision

> **A data-driven approach to choosing between Hetzner US Oregon and EU Germany for your Claude Code agents**

---

## Executive Summary

**The Question**: Should you deploy on Hetzner US Oregon ($9.99/mo) or EU Germany ($10.50/mo)?

**The Answer**: Depends on actual VM→API latency, not assumptions.

**The Test**: Spend $1.75 over 72 hours to measure real-world latency from both locations.

**The Value**: Could save 75+ minutes per year of cumulative latency, or discover EU performs identically and get 10x bandwidth.

**Time Investment**: 30 minutes setup + 5 minutes analysis = data-driven decision

---

## Table of Contents

1. [Why This Test Matters](#why-this-test-matters)
2. [Cost Breakdown](#cost-breakdown)
3. [Prerequisites](#prerequisites)
4. [Step 1: Create Hetzner Account](#step-1-create-hetzner-account)
5. [Step 2: Provision US Oregon Instance](#step-2-provision-us-oregon-instance)
6. [Step 3: Provision EU Germany Instance](#step-3-provision-eu-germany-instance)
7. [Step 4: Set Up Test on US Instance](#step-4-set-up-test-on-us-instance)
8. [Step 5: Set Up Test on EU Instance](#step-5-set-up-test-on-eu-instance)
9. [Step 6: Wait 48-72 Hours](#step-6-wait-48-72-hours)
10. [Step 7: Download and Analyze Results](#step-7-download-and-analyze-results)
11. [Step 8: Interpret Results](#step-8-interpret-results)
12. [Step 9: Make Your Decision](#step-9-make-your-decision)
13. [Step 10: Clean Up Test Instances](#step-10-clean-up-test-instances)
14. [Troubleshooting](#troubleshooting)
15. [Alternative: Quick 1-Hour Test](#alternative-quick-1-hour-test)
16. [Understanding the Metrics](#understanding-the-metrics)
17. [Reference: Why This Test Was Needed](#reference-why-this-test-was-needed)

---

## Why This Test Matters

### The Architecture Insight

When running Claude Code agents, there are **two different latency paths**:

1. **User (LA) → VM**: Only when SSH-ing for setup/monitoring (rare, maybe 5 min/day)
2. **VM → Anthropic API**: Where agents spend 95%+ of their time (constant, 24/7)

**Critical realization**: We need to optimize for #2, not #1!

### The EU vs US Uncertainty

**Known facts:**
- Anthropic expanded infrastructure to EU in August 2025
- api.anthropic.com uses Cloudflare anycast routing
- CPX21 EU costs $10.50/mo with 20TB bandwidth
- CPX21 US costs $9.99/mo with 2TB bandwidth

**Unknown:**
- Will EU VM → Anthropic API route to EU backend? (low latency)
- Or will it cross the Atlantic to US? (high latency)
- BGP peering agreements can override geographic proximity

**The test resolves this uncertainty** with real measurements.

### What You'll Learn Definitively

After 72 hours, you'll know:

✅ **Actual TTFB (Time To First Byte)** from each location
✅ **Whether Cloudflare routes EU → EU efficiently**
✅ **Latency variance** (consistency matters for interactive work)
✅ **Which option provides best marginal return**

**No more guessing.** Pure data.

---

## Cost Breakdown

### 72-Hour Test (Recommended)

| Item | Calculation | Cost |
|------|-------------|------|
| US Oregon CPX21 | €0.011/hr × 72 hours | $0.88 |
| EU Germany CPX21 | €0.011/hr × 72 hours | $0.88 |
| **Total** | | **$1.76** |

**Samples collected**: 864 per instance (every 5 minutes)

### 48-Hour Test (Adequate)

| Item | Calculation | Cost |
|------|-------------|------|
| US Oregon CPX21 | €0.011/hr × 48 hours | $0.59 |
| EU Germany CPX21 | €0.011/hr × 48 hours | $0.59 |
| **Total** | | **$1.18** |

**Samples collected**: 576 per instance

### 1-Hour Quick Test (Minimum)

| Item | Calculation | Cost |
|------|-------------|------|
| Both instances | €0.011/hr × 1 hour × 2 | $0.03 |

**Samples collected**: 12 per instance (minimal statistical validity)

### Return on Investment

**Scenario 1**: Test shows US is 20ms faster
- Save 20ms × 100 requests/day × 250 work days = 500,000ms = **8.3 minutes/year**
- Cost: $1.76 one-time
- ROI: Avoid 8+ minutes of annual latency waste

**Scenario 2**: Test shows EU is same speed as US
- Get 10x bandwidth (20TB vs 2TB) for $6.12/year
- Discover anycast routing works as intended
- ROI: Informed decision vs blind assumption

---

## Prerequisites

Before starting, ensure you have:

### Required:

- [ ] **Credit/debit card** for Hetzner billing
- [ ] **Email address** for Hetzner account
- [ ] **SSH key generated** on your local machine (see below if not)
- [ ] **Terminal/command line** access on your computer
- [ ] **72 hours of time** to let test run (no hands-on time, just waiting)
- [ ] **Basic SSH knowledge** (how to connect to a server)

### Generating SSH Key (if needed):

```bash
# On your local Mac (in Terminal)
ssh-keygen -t ed25519 -C "your_email@example.com"

# Press Enter to accept default location (~/.ssh/id_ed25519)
# Enter a passphrase (recommended) or press Enter for none
# Press Enter again to confirm

# Display your public key (you'll need this)
cat ~/.ssh/id_ed25519.pub
```

**Example output:**
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAbCdEfGhIjKlMnOpQrStUvWxYz your_email@example.com
```

**Save this output** - you'll paste it into Hetzner during instance creation.

---

## Step 1: Create Hetzner Account

### 1.1 Sign Up

1. Go to: **https://www.hetzner.com/cloud**
2. Click **Sign Up** (top right corner)
3. Fill in registration form:
   - Email address
   - Password (strong password recommended)
   - Accept terms of service
4. Click **Register**
5. **Check your email** for verification link
6. Click verification link to activate account

### 1.2 Add Payment Method

1. Log in to **Hetzner Cloud Console**: https://console.hetzner.cloud
2. You'll see a prompt to add payment method
3. Click **Add Payment Method**
4. Choose **Credit Card** or **SEPA Direct Debit**
5. Enter payment details
6. Click **Save**

**Important**: Hetzner bills **hourly**. You only pay for what you use. Deleting servers stops charges immediately.

### 1.3 Create a Project

1. In Hetzner Console, click **New Project**
2. Name: `latency-test` (or your preference)
3. Click **Create Project**
4. You're now in your project dashboard

---

## Step 2: Provision US Oregon Instance

### 2.1 Create Server

1. In your project, click **Add Server** (big button in center)

### 2.2 Choose Location

**Look for the "Location" section:**

- Select **Hillsboro, OR** (flag icon shows 🇺🇸)
- This is the US West location

**Visual guide:**
```
Location: [Nuremberg 🇩🇪] [Falkenstein 🇩🇪] [Helsinki 🇫🇮]
          [Hillsboro 🇺🇸]  [Ashburn 🇺🇸] ← Select Hillsboro
```

### 2.3 Choose Image

**Look for the "Image" section:**

1. Click **Operating Systems** tab (should be default)
2. Select **Ubuntu**
3. Select **Ubuntu 24.04 LTS** (latest LTS version)

**Visual guide:**
```
Image: [Ubuntu] [Debian] [Fedora] [Rocky Linux]

Ubuntu: 22.04 LTS  [24.04 LTS] ← Select this  26.04
```

### 2.4 Choose Server Type

**Look for the "Type" section:**

1. Click **Shared vCPU** tab (not Dedicated vCPU)
2. Find **CPX21**:
   - 3 vCPU
   - 4 GB RAM
   - 80 GB SSD
   - 2 TB traffic
   - **$0.016/hr** or **$9.99/mo**

**Visual guide:**
```
Type: [Shared vCPU] [Dedicated vCPU]

Shared vCPU:
  CPX11    CPX21    CPX31
  2 vCPU   3 vCPU   4 vCPU
  2 GB     4 GB     8 GB
  $4.99    $9.99 ← Select  $17.99
```

### 2.5 Add SSH Key

**Look for the "SSH keys" section:**

1. Click **Add SSH key**
2. Paste your public key (from `cat ~/.ssh/id_ed25519.pub`)
3. Name: `claude-agent-key` (or your preference)
4. Click **Add SSH key**

**Example:**
```
Name: claude-agent-key

Public Key:
┌─────────────────────────────────────────────────────┐
│ ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAbCd...       │
└─────────────────────────────────────────────────────┘

[Add SSH key]
```

### 2.6 Name Your Server

**Look for the "Name" field (at top or bottom):**

- Enter: `test-us-oregon`

### 2.7 Skip Optional Sections

**You can skip these:**
- Volumes (not needed)
- Networks (not needed)
- Firewalls (default is fine for testing)
- Backups (not needed for 72hr test)
- Placement Groups (not needed)
- Labels (optional)
- Cloud-init (not needed)

### 2.8 Create Server

1. Review your selections:
   - Location: Hillsboro, OR
   - Image: Ubuntu 24.04 LTS
   - Type: CPX21
   - SSH key: Added
   - Name: test-us-oregon

2. Click **Create & Buy Now** (bottom right)

3. **Server is creating** (takes 1-2 minutes)

### 2.9 Note the IP Address

**Once created, you'll see:**

```
test-us-oregon
───────────────────────────────
Status: Running ●
IP: 123.45.67.89 ← COPY THIS
Type: CPX21
Location: Hillsboro
```

**Write down or copy this IP address**: `123.45.67.89` (your actual IP will be different)

---

## Step 3: Provision EU Germany Instance

**Repeat Step 2 with these differences:**

### 3.1 Click "Add Server" Again

In the same project (`latency-test`)

### 3.2 Choose Different Location

- Select **Nuremberg** or **Falkenstein** (both are in Germany 🇩🇪)
- Either location is fine; choose whichever appears first

### 3.3 Same Settings

- Image: **Ubuntu 24.04 LTS** (same)
- Type: **CPX21** (same)
- SSH key: Select your **existing key** from dropdown (don't add again)

### 3.4 Different Name

- Name: `test-eu-germany`

### 3.5 Create Server

Click **Create & Buy Now**

### 3.6 Note the Second IP Address

**You now have two servers:**

```
test-us-oregon
  IP: 123.45.67.89

test-eu-germany
  IP: 98.76.54.32 ← COPY THIS TOO
```

**Write down both IP addresses** - you'll need them for SSH.

---

## Step 4: Set Up Test on US Instance

### 4.1 Test SSH Connection

From your local terminal:

```bash
# Replace 123.45.67.89 with your actual US IP
ssh root@123.45.67.89
```

**First time connecting:**
```
The authenticity of host '123.45.67.89 (123.45.67.89)' can't be established.
ED25519 key fingerprint is SHA256:AbCdEfGh...
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

Type `yes` and press Enter.

**Expected result:**
```
Welcome to Ubuntu 24.04 LTS (GNU/Linux ...)

root@test-us-oregon:~#
```

You're now connected to your US server! ✅

### 4.2 Create Test Script

**While connected to the US instance**, copy and paste this entire block:

```bash
cat > ~/api-latency-test.sh <<'EOFSCRIPT'
#!/bin/bash
# Anthropic API Latency Test Script
LOG_FILE=~/anthropic-latency.log
INTERVAL=300  # 5 minutes
ERROR_LOG=~/anthropic-latency-errors.log

echo "timestamp,ttfb_ms,total_ms,http_code" > "$LOG_FILE"
echo "Starting latency test at $(date)" > "$ERROR_LOG"

while true; do
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    curl_output=$(curl -o /dev/null -s -w "%{time_starttransfer},%{time_total},%{http_code}" \
        --max-time 30 \
        -X POST https://api.anthropic.com/v1/messages \
        -H "content-type: application/json" \
        -H "x-api-key: sk-ant-test-dummy" \
        -H "anthropic-version: 2023-06-01" \
        -d '{"model":"claude-3-5-sonnet-20241022","max_tokens":1,"messages":[{"role":"user","content":"test"}]}' \
        2>&1)

    if [ $? -eq 0 ]; then
        ttfb_sec=$(echo "$curl_output" | cut -d',' -f1)
        total_sec=$(echo "$curl_output" | cut -d',' -f2)
        http_code=$(echo "$curl_output" | cut -d',' -f3)

        ttfb_ms=$(echo "$ttfb_sec * 1000" | bc 2>/dev/null)
        total_ms=$(echo "$total_sec * 1000" | bc 2>/dev/null)

        if [ -n "$ttfb_ms" ]; then
            echo "$timestamp,$ttfb_ms,$total_ms,$http_code" >> "$LOG_FILE"
        fi
    fi

    sleep "$INTERVAL"
done
EOFSCRIPT
```

**Expected output:**
```
(Script created - no output)
```

### 4.3 Make Script Executable

```bash
chmod +x ~/api-latency-test.sh
```

### 4.4 Start Test in Background

```bash
nohup ./api-latency-test.sh > /dev/null 2>&1 &
```

**Expected output:**
```
[1] 12345
```

The number (e.g., 12345) is the process ID. This is normal.

### 4.5 Verify Test is Running

Wait 30 seconds, then:

```bash
tail -f ~/anthropic-latency.log
```

**Expected output after 1-2 minutes:**
```
timestamp,ttfb_ms,total_ms,http_code
2025-10-18 10:00:32,245.67,312.45,401
2025-10-18 10:05:32,238.12,305.89,401
```

**Key indicators:**
- ✅ New line appears every ~5 minutes
- ✅ HTTP code is **401** (expected - we're using dummy key)
- ✅ TTFB values are in 100-500ms range (normal)

**Press Ctrl+C to stop watching** (test keeps running in background)

### 4.6 Disconnect from US Instance

```bash
exit
```

You're back on your local machine. The test continues running on the server!

---

## Step 5: Set Up Test on EU Instance

### 5.1 Connect to EU Instance

```bash
# Replace 98.76.54.32 with your actual EU IP
ssh root@98.76.54.32
```

**Type `yes` if prompted about authenticity.**

**Expected:**
```
root@test-eu-germany:~#
```

### 5.2 Run IDENTICAL Setup

**Copy and paste the EXACT same commands from Step 4:**

```bash
# Create script (same as before)
cat > ~/api-latency-test.sh <<'EOFSCRIPT'
#!/bin/bash
# Anthropic API Latency Test Script
LOG_FILE=~/anthropic-latency.log
INTERVAL=300  # 5 minutes
ERROR_LOG=~/anthropic-latency-errors.log

echo "timestamp,ttfb_ms,total_ms,http_code" > "$LOG_FILE"
echo "Starting latency test at $(date)" > "$ERROR_LOG"

while true; do
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    curl_output=$(curl -o /dev/null -s -w "%{time_starttransfer},%{time_total},%{http_code}" \
        --max-time 30 \
        -X POST https://api.anthropic.com/v1/messages \
        -H "content-type: application/json" \
        -H "x-api-key: sk-ant-test-dummy" \
        -H "anthropic-version: 2023-06-01" \
        -d '{"model":"claude-3-5-sonnet-20241022","max_tokens":1,"messages":[{"role":"user","content":"test"}]}' \
        2>&1)

    if [ $? -eq 0 ]; then
        ttfb_sec=$(echo "$curl_output" | cut -d',' -f1)
        total_sec=$(echo "$curl_output" | cut -d',' -f2)
        http_code=$(echo "$curl_output" | cut -d',' -f3)

        ttfb_ms=$(echo "$ttfb_sec * 1000" | bc 2>/dev/null)
        total_ms=$(echo "$total_sec * 1000" | bc 2>/dev/null)

        if [ -n "$ttfb_ms" ]; then
            echo "$timestamp,$ttfb_ms,$total_ms,$http_code" >> "$LOG_FILE"
        fi
    fi

    sleep "$INTERVAL"
done
EOFSCRIPT

# Make executable
chmod +x ~/api-latency-test.sh

# Start in background
nohup ./api-latency-test.sh > /dev/null 2>&1 &

# Wait 30 seconds
sleep 30

# Verify running
tail -f ~/anthropic-latency.log
```

**Watch for entries to appear** (takes 1-2 minutes for first sample)

**Press Ctrl+C when you see entries**

**Expected:**
```
timestamp,ttfb_ms,total_ms,http_code
2025-10-18 10:01:15,267.89,334.56,401
```

### 5.3 Disconnect from EU Instance

```bash
exit
```

**Both tests are now running!** 🎉

---

## Step 6: Wait 48-72 Hours

### What's Happening

Both instances are:
- Testing API latency every 5 minutes
- Logging results to CSV files
- Running 24/7 in the background
- Costing €0.011/hour each ($0.0122/hour)

### No Action Required

You can:
- ✅ Close your terminal
- ✅ Turn off your computer
- ✅ Go about your life
- ✅ The tests keep running

### Optional: Check Progress

If you want to see how it's going:

```bash
# US instance
ssh root@123.45.67.89
tail -20 ~/anthropic-latency.log
exit

# EU instance
ssh root@98.76.54.32
tail -20 ~/anthropic-latency.log
exit
```

### How Much Data You'll Have

| Duration | Samples per Instance | Total Samples |
|----------|---------------------|---------------|
| 24 hours | 288 | 576 |
| 48 hours | 576 | 1,152 |
| 72 hours | 864 | 1,728 |

**Minimum recommended**: 48 hours (576 samples)
**Ideal**: 72 hours (864 samples)

### Set a Reminder

**Important**: Set a phone/calendar reminder for 48-72 hours from now to:
1. Download the results
2. **DELETE both instances** to stop charges

Forgetting = ongoing hourly charges! ⚠️

---

## Step 7: Download and Analyze Results

**After 48-72 hours have passed...**

### 7.1 Download Log Files

From your **local machine** terminal:

```bash
# Create a directory for results
mkdir ~/latency-test-results
cd ~/latency-test-results

# Download from US instance (replace IP)
scp root@123.45.67.89:~/anthropic-latency.log us-oregon-latency.log

# Download from EU instance (replace IP)
scp root@98.76.54.32:~/anthropic-latency.log eu-germany-latency.log
```

**Expected output:**
```
anthropic-latency.log        100%   42KB  500.2KB/s   00:00
```

### 7.2 Verify Downloads

```bash
# Check both files exist and have data
ls -lh

# Should show:
# -rw-r--r--  1 you  staff   42K Oct 21 10:30 us-oregon-latency.log
# -rw-r--r--  1 you  staff   41K Oct 21 10:30 eu-germany-latency.log

# Count lines (should be 500+)
wc -l us-oregon-latency.log eu-germany-latency.log
```

**Expected for 72-hour test:**
```
     865 us-oregon-latency.log
     864 eu-germany-latency.log
    1729 total
```

### 7.3 Get Analysis Script

If you haven't already, get the analysis script:

```bash
# If you have the repository:
cd /Users/chrisren/Development/cloud-agent
cp scripts/latency-test/analyze-latency.sh ~/latency-test-results/

# Make it executable
chmod +x ~/latency-test-results/analyze-latency.sh
```

**Or create it manually:**

```bash
# Download from repository or copy from scripts/latency-test/analyze-latency.sh
# See the full script in scripts/latency-test/ directory
```

### 7.4 Run Analysis

```bash
cd ~/latency-test-results
./analyze-latency.sh us-oregon-latency.log eu-germany-latency.log
```

**The analysis will output a comprehensive comparison** (see next section)

---

## Step 8: Interpret Results

The analysis script produces output like this:

### Example Output 1: US is Faster

```
========================================
  ANTHROPIC API LATENCY COMPARISON
========================================

US OREGON (Hillsboro, OR)
-------------------------------------------
  Average TTFB:   245.32 ms
  Min TTFB:       198.45 ms
  Max TTFB:       412.67 ms
  Samples:            864
  Duration:     ~72.0 hours

EU GERMANY (Nuremberg/Falkenstein)
-------------------------------------------
  Average TTFB:   267.89 ms
  Min TTFB:       215.34 ms
  Max TTFB:       438.92 ms
  Samples:            863
  Duration:     ~71.9 hours

========================================
  COMPARISON & RECOMMENDATION
========================================

✅ US OREGON IS FASTER

  US Oregon:  245.32 ms average
  EU Germany: 267.89 ms average
  Difference: 22.57 ms faster (8.4% improvement)

📊 RECOMMENDATION: Choose US Oregon
   Reason: Measurable latency advantage
```

### Example Output 2: EU is Faster

```
========================================
  COMPARISON & RECOMMENDATION
========================================

✅ EU GERMANY IS FASTER

  EU Germany: 238.45 ms average
  US Oregon:  245.32 ms average
  Difference: 6.87 ms faster (2.8% improvement)

⚖️  MARGINAL: EU Germany slightly faster
   Reason: Difference is minimal (<10ms)
   Consider: EU costs $6.12/year more but includes 20TB bandwidth
```

### Example Output 3: Essentially Identical

```
✅ US OREGON IS FASTER

  US Oregon:  242.15 ms average
  EU Germany: 245.78 ms average
  Difference: 3.63 ms faster (1.5% improvement)

⚖️  MARGINAL: US Oregon slightly faster
   Reason: Difference is minimal (<10ms)
```

### Understanding the Decision Tiers

| Difference | Meaning | Recommendation Strength |
|------------|---------|------------------------|
| **>50ms** | Significant advantage | 🎯 **STRONG** - Clear winner |
| **10-50ms** | Measurable advantage | 📊 **MODERATE** - Choose faster option |
| **<10ms** | Marginal difference | ⚖️  **WEAK** - Either option viable |

### Data Quality Indicators

The script also checks data quality:

✅ **Good**: 576+ samples (48+ hours)
⚠️  **Limited**: <576 samples (consider running longer)

---

## Step 9: Make Your Decision

### Decision Matrix

Based on your results, choose your production infrastructure:

#### Scenario A: US is 10+ ms faster

**Choose**: **Hetzner US Oregon CPX21** at $9.99/month

**Reasoning:**
- ✅ Measurably better latency
- ✅ Saves $6.12/year vs EU
- ✅ 2TB bandwidth is adequate (40x typical agent usage)
- ✅ Predictable US→US routing

**Action**: Proceed with US Oregon deployment (see IMPLEMENTATION.md)

---

#### Scenario B: EU is 10+ ms faster

**Choose**: **Hetzner EU Germany CPX21** at $10.50/month

**Reasoning:**
- ✅ Better latency despite longer geographic distance
- ✅ Cloudflare anycast routing works efficiently to EU backend
- ✅ 10x bandwidth (20TB vs 2TB) included
- ✅ Worth the $6.12/year premium for performance

**Action**: Proceed with EU deployment (modify IMPLEMENTATION.md location)

---

#### Scenario C: Within 10ms (Marginal)

**Personal Choice** - both are viable:

**Option A: US Oregon ($9.99/mo)** ✅ **Recommended if marginal**
- Saves $6.12/year
- Slightly better SSH latency from LA
- Predictable routing
- 2TB is adequate for agent workload

**Option B: EU Germany ($10.50/mo)**
- Future-proof with 20TB bandwidth
- Minimal cost increase ($0.51/mo)
- May perform better as Anthropic expands EU presence

**Action**: Choose based on personal preference

---

### Long-Term Implications

**Your decision affects:**

| Factor | US Oregon | EU Germany |
|--------|-----------|------------|
| **Monthly cost** | $9.99 | $10.50 |
| **Annual cost** | $119.88 | $126.00 |
| **SSH latency from LA** | 10-30ms | 150-200ms |
| **API latency** | (measured in test) | (measured in test) |
| **Bandwidth included** | 2TB | 20TB |
| **Bandwidth overage** | $1/TB | $1/TB |
| **Geographic proximity** | Same coast | Europe |

**For Claude Code agents:**
- API latency matters most (measured in this test)
- SSH latency is minor (only during setup/monitoring)
- Bandwidth usage is typically <50GB/month (both adequate)

---

## Step 10: Clean Up Test Instances

### 🚨 CRITICAL: Delete Both Instances 🚨

**Forgetting this step = ongoing hourly charges!**

### 10.1 Via Hetzner Console (Recommended)

1. Go to: https://console.hetzner.cloud
2. Select your `latency-test` project
3. Click on **test-us-oregon**
4. Scroll down, click **Delete** (red button)
5. Type the server name to confirm: `test-us-oregon`
6. Click **Delete server**
7. **Repeat for test-eu-germany**

### 10.2 Verify Deletion

**In your project dashboard:**
- You should see: **"No servers found"**
- Server list is empty

### 10.3 Check Final Bill

1. In Hetzner Console: **Billing** → **Current Costs**
2. Look for **Cloud Servers**
3. Should show **~$1.76** total for both instances

**Example:**
```
Cloud Servers
  test-us-oregon    72 hours × €0.011/hr = €0.792 ($0.88)
  test-eu-germany   72 hours × €0.011/hr = €0.792 ($0.88)
  ────────────────────────────────────────────────────
  Total:                                  €1.584 ($1.76)
```

### 10.4 Optional: Delete Project

If you won't use this project again:

1. **Billing** → **Project Settings**
2. Scroll to bottom
3. Click **Delete project**
4. Confirm

**Note**: You can keep the project for future tests - no charges if no servers running.

---

## Troubleshooting

### Problem: SSH connection refused

**Symptoms:**
```
ssh: connect to host 123.45.67.89 port 22: Connection refused
```

**Solutions:**
1. Wait 2-3 minutes - server may still be initializing
2. Check server status in Hetzner Console (should say "Running")
3. Verify IP address is correct
4. Check firewall isn't blocking port 22

---

### Problem: Script not creating log file

**Symptoms:**
```bash
tail ~/anthropic-latency.log
# File not found
```

**Solutions:**

```bash
# Check if script is running
ps aux | grep api-latency-test

# If not running, check errors
cat ~/anthropic-latency-errors.log

# Manually run script to see errors
./api-latency-test.sh
# Watch for error messages

# Restart script
pkill -f api-latency-test  # Kill old process
nohup ./api-latency-test.sh > /dev/null 2>&1 &
```

---

### Problem: No new log entries appearing

**Symptoms:**
Log file exists but hasn't updated in >10 minutes

**Solutions:**

```bash
# Check script is still running
ps aux | grep api-latency-test

# Check for network errors
cat ~/anthropic-latency-errors.log

# Test connectivity manually
curl -I https://api.anthropic.com
# Should return HTTP/2 200 or 404

# Check if bc (calculator) is installed
which bc
# If not found:
apt update && apt install -y bc

# Restart script
pkill -f api-latency-test
nohup ./api-latency-test.sh > /dev/null 2>&1 &
```

---

### Problem: Analysis script shows "No data"

**Symptoms:**
```
ERROR: No data in us-oregon-latency.log
```

**Solutions:**

```bash
# Check file exists and has content
ls -lh us-oregon-latency.log eu-germany-latency.log

# Check file format
head us-oregon-latency.log
# Should show:
# timestamp,ttfb_ms,total_ms,http_code
# 2025-10-18 10:00:00,245.67,312.45,401

# Count valid entries
tail -n +2 us-oregon-latency.log | wc -l
# Should be >100 for meaningful results
```

---

### Problem: Vastly different sample counts

**Symptoms:**
US has 864 samples, EU has 200 samples

**Causes:**
- EU instance script crashed or was never started
- EU instance had network issues
- Scripts started at very different times

**Solutions:**

```bash
# SSH into EU instance
ssh root@EU_IP

# Check if script is running
ps aux | grep api-latency-test

# Check errors
cat ~/anthropic-latency-errors.log

# Restart if needed
pkill -f api-latency-test
nohup ./api-latency-test.sh > /dev/null 2>&1 &
```

**Consider extending test** if one instance has significantly less data.

---

### Problem: Hetzner billing higher than expected

**Expected cost**: $1.76 for 72 hours
**If higher**: Check for these issues

```bash
# Via Hetzner Console:
# 1. Billing → Current Costs → Detailed View

# Look for:
# - Extra servers you forgot to delete
# - Volumes (should be 0 for this test)
# - Load balancers (should be 0 for this test)
# - Snapshots (should be 0 for this test)

# Delete any unexpected resources
```

---

## Alternative: Quick 1-Hour Test

If you want a quick sanity check before committing to 72 hours:

### Cost: $0.03 total

### Procedure:

**Follow Steps 1-5 above, but in Step 6:**

After both instances are running, wait **1 hour only**, then:

```bash
# Download results after 1 hour
scp root@US_IP:~/anthropic-latency.log us-oregon-1hr.log
scp root@EU_IP:~/anthropic-latency.log eu-germany-1hr.log

# Analyze
./analyze-latency.sh us-oregon-1hr.log eu-germany-1hr.log

# Delete instances immediately
# (Hetzner Console → Delete both servers)
```

### Limitations:

⚠️  **Only 12 samples** per instance (vs 864 for 72hr)
⚠️  **Low statistical confidence** (may be skewed by temporary conditions)
⚠️  **Doesn't capture daily variations** (time of day, load patterns)

### When to use 1-hour test:

- ✅ Quick directional check (is EU dramatically worse?)
- ✅ Budget is extremely tight
- ✅ Willing to accept lower confidence results

**Recommendation**: If possible, do the full 48-72 hour test for $1-2 more. The data quality is worth it.

---

## Understanding the Metrics

### TTFB (Time To First Byte)

**Definition**: Time from request sent to first byte received

**What it includes:**
- Network latency (VM → Cloudflare → Anthropic backend)
- API processing start time
- Initial response headers

**Why it matters:**
- Most important metric for interactive work
- Claude Code streams responses, so TTFB = perceived latency
- Lower TTFB = more responsive agent experience

**Typical values:**
- **Excellent**: 100-200ms
- **Good**: 200-300ms
- **Acceptable**: 300-500ms
- **Poor**: >500ms

---

### Total Time

**Definition**: Complete request/response cycle

**What it includes:**
- Everything in TTFB
- Full response body transfer
- Connection cleanup

**Why it's less important:**
- For minimal requests (max_tokens=1), total ≈ TTFB
- For actual agent work, streaming means TTFB matters more
- Total time includes full generation, which varies by response length

---

### HTTP Code

**What you'll see**: 401 (Unauthorized)

**Why this is expected:**
- We're using a dummy API key
- We're not trying to get actual responses
- We're just testing endpoint latency
- 401 = server is reachable and responding

**If you see other codes:**
- 404 = Endpoint not found (check URL)
- 500 = Server error (temporary, should be rare)
- 000 = Network timeout (check connectivity)

---

### Sample Size and Statistical Validity

**Why more samples = better:**
- Accounts for daily variations (morning vs evening)
- Averages out temporary network hiccups
- Captures weekly patterns (weekday vs weekend API load)
- Reduces impact of outliers

**Minimum sample sizes:**

| Samples | Hours | Confidence | Use Case |
|---------|-------|------------|----------|
| 12 | 1 | Very Low | Quick sanity check only |
| 144 | 12 | Low | Directional indication |
| 288 | 24 | Moderate | Acceptable if budget tight |
| **576** | **48** | **Good** | **Recommended minimum** |
| **864** | **72** | **Very Good** | **Ideal** |

---

## Reference: Why This Test Was Needed

### The Journey to This Test

**Phase 1: Initial assumption** (incorrect)
- Thought LA Local Zone was better due to proximity
- Assumed User→VM latency mattered most
- Willing to pay premium for "local" datacenter

**Phase 2: Realization** (architecture insight)
- Discovered VM→API latency is what matters
- 95%+ of agent time is calling Anthropic API
- Oregon vs LA makes minimal difference for API calls

**Phase 3: New dilemma** (EU vs US)
- OVHCloud no longer optimal (shared CPU, expensive)
- Hetzner offers better value
- But EU vs US routing is uncertain due to Cloudflare anycast

**Phase 4: This test** (data-driven decision)
- Measure actual latencies from both locations
- Remove guesswork about BGP routing
- Make informed choice based on real data

### Related Documentation

See full analysis in:
- **12-provider-comparison.md**: Why Hetzner was chosen over OVHCloud
- **10-location-latency-analysis.md**: Deep dive on latency components
- **IMPLEMENTATION.md**: Full deployment guide

### Key Lessons

✅ **Question assumptions**: "Local" isn't always better
✅ **Understand your architecture**: Know where latency actually occurs
✅ **Measure, don't assume**: BGP routing can surprise you
✅ **Invest in data**: $2 test >>> making wrong $1,320/year decision

---

## Summary

**You've completed the test!** Here's what you accomplished:

1. ✅ Created two test instances (US and EU)
2. ✅ Ran 48-72 hours of latency measurements
3. ✅ Collected 576-864 samples per location
4. ✅ Downloaded and analyzed results
5. ✅ Made a data-driven infrastructure decision
6. ✅ Deleted test instances to stop charges

**Cost**: ~$1.76 for definitive answer
**Time invested**: 30 minutes setup + 5 minutes analysis
**Value**: Informed decision on infrastructure that will run for months/years

**Next steps:**

1. Proceed with deployment on chosen location (see IMPLEMENTATION.md)
2. Use monitoring scripts to validate decision (see 09-scaling-metrics.md)
3. Optimize based on actual usage patterns

---

**Generated**: October 18, 2025
**Version**: 1.0.0
**Author**: Chris Ren
**Test Cost**: $1.76 (72hr) or $1.18 (48hr) or $0.03 (1hr quick test)
**Success Rate**: Data-driven decision >>> assumptions

---

**Questions or issues?**

- Review [Troubleshooting section](#troubleshooting)
- Check scripts at `scripts/latency-test/`
- See provider comparison at `12-provider-comparison.md`
