#!/bin/bash
###############################################################################
# Anthropic API Latency Test Script
#
# Purpose: Continuously test latency to api.anthropic.com to compare
#          EU vs US hosting locations for optimal infrastructure decision
#
# Usage: nohup ./api-latency-test.sh > /dev/null 2>&1 &
#
# Output: Creates anthropic-latency.log with CSV format:
#         timestamp,ttfb_ms,total_ms,http_code
#
# Cost: Runs for 72 hours as part of ~$2 comparison test
###############################################################################

# Configuration
LOG_FILE=~/anthropic-latency.log
INTERVAL=300  # 5 minutes between tests
ERROR_LOG=~/anthropic-latency-errors.log

# Initialize log files
echo "timestamp,ttfb_ms,total_ms,http_code" > "$LOG_FILE"
echo "Starting latency test at $(date)" > "$ERROR_LOG"
echo "Testing api.anthropic.com every $INTERVAL seconds" >> "$ERROR_LOG"

# Function to test API latency
test_api_latency() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Test with minimal API request (uses dummy key, tests endpoint only)
    local curl_output=$(curl -o /dev/null -s -w "%{time_starttransfer},%{time_total},%{http_code}" \
        --max-time 30 \
        -X POST https://api.anthropic.com/v1/messages \
        -H "content-type: application/json" \
        -H "x-api-key: sk-ant-test-dummy-key-00000000000000000000000000000000" \
        -H "anthropic-version: 2023-06-01" \
        -d '{"model":"claude-3-5-sonnet-20241022","max_tokens":1,"messages":[{"role":"user","content":"test"}]}' \
        2>&1)

    # Check if curl succeeded
    if [ $? -ne 0 ]; then
        echo "$timestamp: ERROR - Curl failed: $curl_output" >> "$ERROR_LOG"
        return 1
    fi

    # Parse output (format: time_starttransfer,time_total,http_code)
    local ttfb_sec=$(echo "$curl_output" | cut -d',' -f1)
    local total_sec=$(echo "$curl_output" | cut -d',' -f2)
    local http_code=$(echo "$curl_output" | cut -d',' -f3)

    # Convert seconds to milliseconds
    local ttfb_ms=$(echo "$ttfb_sec * 1000" | bc 2>/dev/null)
    local total_ms=$(echo "$total_sec * 1000" | bc 2>/dev/null)

    # Validate we got numeric values
    if [ -z "$ttfb_ms" ] || [ -z "$total_ms" ]; then
        echo "$timestamp: ERROR - Failed to parse timing data" >> "$ERROR_LOG"
        return 1
    fi

    # Log the result
    echo "$timestamp,$ttfb_ms,$total_ms,$http_code" >> "$LOG_FILE"

    return 0
}

# Main loop
echo "Latency test started. Logging to $LOG_FILE"
echo "Press Ctrl+C to stop, or kill this process"
echo ""

sample_count=0

while true; do
    if test_api_latency; then
        ((sample_count++))
        if [ $((sample_count % 12)) -eq 0 ]; then
            # Every 12 samples (1 hour), print status
            echo "$(date): Collected $sample_count samples so far" >> "$ERROR_LOG"
        fi
    fi

    sleep "$INTERVAL"
done
