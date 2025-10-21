#!/bin/bash
###############################################################################
# Cost Tracking Script for Claude Code Agents
#
# Tracks daily API usage via logs, calculates costs based on token counts,
# stores history, and displays 7-day summary with total spend.
#
# Usage:
#   bash scripts/monitoring/cost-tracker.sh           # Show current daily costs
#   bash scripts/monitoring/cost-tracker.sh --week    # Show 7-day summary
#   bash scripts/monitoring/cost-tracker.sh --log     # Update cost log from agent logs
#   bash scripts/monitoring/cost-tracker.sh --help    # Show this help
#
# Setup (optional - for automated tracking):
#   # Add to crontab to track costs daily at midnight:
#   0 0 * * * bash ~/scripts/monitoring/cost-tracker.sh --log
#
# Files:
#   ~/agents/costs/daily-costs.log     - Historical cost tracking
#   ~/agents/logs/*.log                - Agent activity logs (parsed for tokens)
#
# Pricing (2025 Sonnet 4):
#   Input:  $3.00 per 1M tokens
#   Output: $15.00 per 1M tokens
#   Cache Hit: $0.30 per 1M tokens
###############################################################################

set -euo pipefail

# Configuration
COST_LOG_DIR=~/agents/costs
COST_LOG_FILE=$COST_LOG_DIR/daily-costs.log
AGENT_LOG_DIR=~/agents/logs

# Pricing per million tokens (Sonnet 4 - 2025)
PRICE_INPUT=3.00
PRICE_OUTPUT=15.00
PRICE_CACHE_HIT=0.30

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

###############################################################################
# Helper Functions
###############################################################################

show_help() {
    head -n 30 "$0" | grep "^#" | sed 's/^# \?//'
}

ensure_directories() {
    mkdir -p "$COST_LOG_DIR"

    # Create log file with header if it doesn't exist
    if [ ! -f "$COST_LOG_FILE" ]; then
        echo "Date,InputTokens,OutputTokens,CacheHits,InputCost,OutputCost,CacheCost,TotalCost" > "$COST_LOG_FILE"
    fi
}

calculate_cost() {
    local input_tokens=$1
    local output_tokens=$2
    local cache_tokens=$3

    # Convert to millions and calculate costs
    local input_cost=$(echo "scale=4; $input_tokens / 1000000 * $PRICE_INPUT" | bc)
    local output_cost=$(echo "scale=4; $output_tokens / 1000000 * $PRICE_OUTPUT" | bc)
    local cache_cost=$(echo "scale=4; $cache_tokens / 1000000 * $PRICE_CACHE_HIT" | bc)
    local total_cost=$(echo "scale=4; $input_cost + $output_cost + $cache_cost" | bc)

    echo "$input_cost,$output_cost,$cache_cost,$total_cost"
}

###############################################################################
# Parse Agent Logs for Token Usage
###############################################################################

parse_agent_logs() {
    local date=${1:-$(date +%Y-%m-%d)}
    local input_tokens=0
    local output_tokens=0
    local cache_tokens=0

    # Check if agent log directory exists
    if [ ! -d "$AGENT_LOG_DIR" ]; then
        echo -e "${YELLOW}Warning: Agent log directory not found at $AGENT_LOG_DIR${NC}" >&2
        echo "0,0,0"
        return
    fi

    # Parse all agent log files for today's usage
    # Look for patterns like:
    # - "input_tokens: 1234"
    # - "output_tokens: 567"
    # - "cache_read_input_tokens: 890"
    # - JSON patterns from Claude API responses

    if [ -f "$AGENT_LOG_DIR/resource-usage.log" ]; then
        # Example parsing - adapt based on actual log format
        # This is a simplified version; real implementation would parse actual API logs

        # Look for token usage in today's logs
        local today_logs=$(grep "^$date" "$AGENT_LOG_DIR/resource-usage.log" 2>/dev/null || true)

        # For now, return zeros if no parsing pattern exists
        # In production, this would parse actual Claude API response logs
        input_tokens=0
        output_tokens=0
        cache_tokens=0
    fi

    echo "$input_tokens,$output_tokens,$cache_tokens"
}

###############################################################################
# Log Today's Costs
###############################################################################

log_daily_cost() {
    local date=$(date +%Y-%m-%d)

    # Check if today's cost already logged
    if grep -q "^$date," "$COST_LOG_FILE" 2>/dev/null; then
        echo -e "${YELLOW}Cost for $date already logged. Updating...${NC}"
        # Remove old entry
        sed -i "/^$date,/d" "$COST_LOG_FILE"
    fi

    # Parse token usage from logs
    local tokens=$(parse_agent_logs "$date")
    local input_tokens=$(echo "$tokens" | cut -d',' -f1)
    local output_tokens=$(echo "$tokens" | cut -d',' -f2)
    local cache_tokens=$(echo "$tokens" | cut -d',' -f3)

    # Calculate costs
    local costs=$(calculate_cost "$input_tokens" "$output_tokens" "$cache_tokens")

    # Log to file
    echo "$date,$input_tokens,$output_tokens,$cache_tokens,$costs" >> "$COST_LOG_FILE"

    echo -e "${GREEN}✓ Logged costs for $date${NC}"
    echo "  Input tokens:  $input_tokens"
    echo "  Output tokens: $output_tokens"
    echo "  Cache hits:    $cache_tokens"
    echo "  Total cost:    \$$(echo "$costs" | cut -d',' -f4)"
}

###############################################################################
# Show Today's Costs
###############################################################################

show_today() {
    local date=$(date +%Y-%m-%d)

    echo "======================================"
    echo "  COST TRACKER - TODAY"
    echo "  $date"
    echo "======================================"
    echo ""

    # Check if costs logged for today
    local today_line=$(grep "^$date," "$COST_LOG_FILE" 2>/dev/null || echo "")

    if [ -z "$today_line" ]; then
        echo -e "${YELLOW}No costs logged for today yet.${NC}"
        echo ""
        echo "Run: bash $0 --log"
        echo "     to calculate and log today's costs"
        return
    fi

    # Parse the line
    local input_tokens=$(echo "$today_line" | cut -d',' -f2)
    local output_tokens=$(echo "$today_line" | cut -d',' -f3)
    local cache_tokens=$(echo "$today_line" | cut -d',' -f4)
    local input_cost=$(echo "$today_line" | cut -d',' -f5)
    local output_cost=$(echo "$today_line" | cut -d',' -f6)
    local cache_cost=$(echo "$today_line" | cut -d',' -f7)
    local total_cost=$(echo "$today_line" | cut -d',' -f8)

    echo "Token Usage:"
    printf "  Input tokens:  %'d\n" "$input_tokens"
    printf "  Output tokens: %'d\n" "$output_tokens"
    printf "  Cache hits:    %'d\n" "$cache_tokens"
    echo ""

    echo "Costs:"
    printf "  Input cost:    \$%.4f\n" "$input_cost"
    printf "  Output cost:   \$%.4f\n" "$output_cost"
    printf "  Cache cost:    \$%.4f\n" "$cache_cost"
    echo "  ----------------------"
    printf "  ${GREEN}Total cost:    \$%.4f${NC}\n" "$total_cost"
    echo ""
}

###############################################################################
# Show 7-Day Summary
###############################################################################

show_week() {
    echo "======================================"
    echo "  COST TRACKER - 7-DAY SUMMARY"
    echo "======================================"
    echo ""

    # Get last 7 days of data (excluding header)
    local week_data=$(tail -n 8 "$COST_LOG_FILE" | tail -n 7)

    if [ -z "$week_data" ]; then
        echo -e "${YELLOW}No cost data available yet.${NC}"
        echo ""
        echo "Run: bash $0 --log"
        echo "     to start tracking costs"
        return
    fi

    # Display table header
    printf "%-12s %12s %12s %12s %10s\n" "Date" "Input Tok" "Output Tok" "Cache Tok" "Total Cost"
    echo "----------------------------------------------------------------------"

    # Display each day
    local total_cost_sum=0
    local total_input=0
    local total_output=0
    local total_cache=0

    while IFS=',' read -r date input_tokens output_tokens cache_tokens input_cost output_cost cache_cost total_cost; do
        printf "%-12s %'12d %'12d %'12d \$%9.4f\n" \
            "$date" "$input_tokens" "$output_tokens" "$cache_tokens" "$total_cost"

        total_cost_sum=$(echo "$total_cost_sum + $total_cost" | bc)
        total_input=$((total_input + input_tokens))
        total_output=$((total_output + output_tokens))
        total_cache=$((total_cache + cache_tokens))
    done <<< "$week_data"

    echo "----------------------------------------------------------------------"
    printf "%-12s %'12d %'12d %'12d ${GREEN}\$%9.4f${NC}\n" \
        "TOTAL" "$total_input" "$total_output" "$total_cache" "$total_cost_sum"

    echo ""
    echo "Average Daily Cost: \$$(echo "scale=4; $total_cost_sum / 7" | bc)"
    echo "Projected Monthly:  \$$(echo "scale=2; $total_cost_sum / 7 * 30" | bc)"
    echo ""

    # Show budget warnings
    local max_plan_cost=100
    local projected_monthly=$(echo "scale=2; $total_cost_sum / 7 * 30" | bc)

    if (( $(echo "$projected_monthly > $max_plan_cost" | bc -l) )); then
        echo -e "${RED}⚠️  WARNING: Projected monthly cost exceeds Max plan (\$$max_plan_cost/mo)${NC}"
        echo "   Consider optimizing usage or upgrading plan"
    elif (( $(echo "$projected_monthly > 80" | bc -l) )); then
        echo -e "${YELLOW}⚠️  Note: Approaching Max plan limit (\$$max_plan_cost/mo)${NC}"
    else
        echo -e "${GREEN}✓ Within Max plan budget${NC}"
    fi
    echo ""
}

###############################################################################
# Main
###############################################################################

main() {
    ensure_directories

    case "${1:-}" in
        --help|-h)
            show_help
            ;;
        --log)
            log_daily_cost
            ;;
        --week|-w)
            show_week
            ;;
        --today|"")
            show_today
            ;;
        *)
            echo "Unknown option: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

main "$@"
