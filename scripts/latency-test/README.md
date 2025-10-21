# Latency Test Scripts

Quick reference for the $2 EU vs US latency testing scripts.

For the full detailed guide, see: [**knowledge-base/13-latency-test-guide.md**](../../knowledge-base/13-latency-test-guide.md)

---

## Quick Start

### On Each Test Instance (US & EU):

```bash
# 1. Upload script
scp api-latency-test.sh root@YOUR_INSTANCE_IP:~/

# 2. SSH into instance
ssh root@YOUR_INSTANCE_IP

# 3. Start test in background
chmod +x api-latency-test.sh
nohup ./api-latency-test.sh > /dev/null 2>&1 &

# 4. Verify it's running
tail -f ~/anthropic-latency.log
# Press Ctrl+C to exit tail

# 5. Disconnect (test keeps running)
exit
```

### After 48-72 Hours (On Your Local Machine):

```bash
# 1. Download results
scp root@US_IP:~/anthropic-latency.log us-oregon-latency.log
scp root@EU_IP:~/anthropic-latency.log eu-germany-latency.log

# 2. Analyze
./analyze-latency.sh us-oregon-latency.log eu-germany-latency.log

# 3. Follow the recommendation shown in output
```

---

## What Each Script Does

### `api-latency-test.sh`
- **Purpose**: Continuously test API latency to api.anthropic.com
- **Frequency**: Every 5 minutes
- **Output**: CSV log file at `~/anthropic-latency.log`
- **Format**: `timestamp,ttfb_ms,total_ms,http_code`
- **Duration**: Runs indefinitely until stopped
- **Resource Usage**: Minimal (one curl every 5 min)

**Example output:**
```csv
timestamp,ttfb_ms,total_ms,http_code
2025-10-18 10:00:00,245.67,312.45,401
2025-10-18 10:05:00,238.12,305.89,401
2025-10-18 10:10:00,251.34,318.76,401
```

**Note**: HTTP 401 is expected (using dummy API key to test endpoint only)

---

### `analyze-latency.sh`
- **Purpose**: Compare latency results from both instances
- **Input**: Two log files (US and EU)
- **Output**: Statistical comparison with recommendation
- **Metrics**: Average, Min, Max TTFB for each location
- **Decision**: Clear guidance on which provider to choose

**Example output:**
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

---

## Reading the Output

### TTFB (Time To First Byte)
- The time from request sent to first byte received
- **Most important metric** for interactive Claude Code work
- Lower is better
- Includes network latency + API processing start time

### Total Time
- Complete request/response cycle
- Less important than TTFB for streaming responses

### HTTP Code
- Should be **401** (unauthorized - expected with dummy key)
- Confirms endpoint is reachable
- Any other code indicates potential issue

---

## Troubleshooting

### Script not creating log file
```bash
# Check if script is running
ps aux | grep api-latency-test

# Check error log
cat ~/anthropic-latency-errors.log

# Restart manually
./api-latency-test.sh
```

### Analysis shows no data
```bash
# Verify log files exist and have content
wc -l us-oregon-latency.log eu-germany-latency.log

# Should show > 100 lines for meaningful data
```

### Different sample counts
- Normal if instances started at slightly different times
- Both should be close (within 1-2 samples)
- If very different, one instance may have crashed

---

## Cost Tracking

**Per instance cost:**
- CPX21: €0.011/hour = $0.0122/hour
- 72 hours: $0.88 per instance
- **Total: $1.76 for both instances**

**Check your bill:**
```bash
# In Hetzner console:
# Billing → Current Costs → Cloud Servers

# Should show ~$1.76 after 72 hours
```

---

## Important: Cleanup

**CRITICAL:** Delete both instances after downloading results!

```bash
# Via Hetzner Console:
# 1. Go to Cloud → Servers
# 2. Click on test-us-oregon → Delete
# 3. Click on test-eu-germany → Delete
# 4. Confirm deletion

# Verify deletion:
# Check that both servers no longer appear in server list
```

Forgetting this step = ongoing hourly charges! ⚠️

---

## Files in This Directory

- **api-latency-test.sh**: The daemon script that runs on each instance
- **analyze-latency.sh**: Local analysis script for comparing results
- **README.md**: This file (quick reference)

---

## Full Documentation

See the complete beginner-friendly guide with screenshots and detailed explanations:

📖 [**knowledge-base/13-latency-test-guide.md**](../../knowledge-base/13-latency-test-guide.md)

Covers:
- Detailed step-by-step setup
- Hetzner account creation
- Screenshot examples
- Troubleshooting
- Decision framework
- Cost breakdown

---

**Quick Stats:**
- **Test Duration**: 48-72 hours recommended
- **Sample Frequency**: Every 5 minutes (288 samples/day)
- **Total Cost**: ~$1.76 for both instances
- **Time Investment**: ~30 minutes setup, 5 minutes analysis
- **Decision Impact**: Could save 75+ minutes/year of cumulative latency
