#!/bin/bash
###############################################################################
# Anthropic API Latency Analysis Script
#
# Purpose: Compare latency results from US Oregon vs EU Germany instances
#          to make data-driven infrastructure decision
#
# Usage: ./analyze-latency.sh us-oregon-latency.log eu-germany-latency.log
#
# Prerequisites:
#   - Downloaded log files from both test instances
#   - At least 48 hours of data collected (576+ samples)
#
# Output: Statistical comparison with clear winner declaration
###############################################################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check arguments
if [ $# -ne 2 ]; then
    echo "Usage: $0 <us-oregon-log> <eu-germany-log>"
    echo ""
    echo "Example:"
    echo "  $0 us-oregon-latency.log eu-germany-latency.log"
    exit 1
fi

US_LOG="$1"
EU_LOG="$2"

# Validate files exist
if [ ! -f "$US_LOG" ]; then
    echo -e "${RED}ERROR: US log file not found: $US_LOG${NC}"
    exit 1
fi

if [ ! -f "$EU_LOG" ]; then
    echo -e "${RED}ERROR: EU log file not found: $EU_LOG${NC}"
    exit 1
fi

# Function to calculate statistics
calculate_stats() {
    local file=$1
    local location=$2

    # Count samples (excluding header)
    local count=$(tail -n +2 "$file" | wc -l | tr -d ' ')

    if [ "$count" -eq 0 ]; then
        echo -e "${RED}ERROR: No data in $file${NC}"
        return 1
    fi

    # Calculate average, min, max TTFB (column 2)
    local stats=$(tail -n +2 "$file" | awk -F',' '{
        sum += $2
        if (NR == 1 || $2 < min) min = $2
        if (NR == 1 || $2 > max) max = $2
        count++
    } END {
        printf "%.2f,%.2f,%.2f,%d", sum/count, min, max, count
    }')

    echo "$stats"
}

# Print header
echo ""
echo "========================================="
echo "  ANTHROPIC API LATENCY COMPARISON"
echo "========================================="
echo ""

# Analyze US Oregon
echo -e "${BLUE}US OREGON (Hillsboro, OR)${NC}"
echo "-------------------------------------------"
US_STATS=$(calculate_stats "$US_LOG" "US Oregon")
if [ $? -ne 0 ]; then
    exit 1
fi

US_AVG=$(echo "$US_STATS" | cut -d',' -f1)
US_MIN=$(echo "$US_STATS" | cut -d',' -f2)
US_MAX=$(echo "$US_STATS" | cut -d',' -f3)
US_COUNT=$(echo "$US_STATS" | cut -d',' -f4)

printf "  Average TTFB: %8.2f ms\n" "$US_AVG"
printf "  Min TTFB:     %8.2f ms\n" "$US_MIN"
printf "  Max TTFB:     %8.2f ms\n" "$US_MAX"
printf "  Samples:      %8d\n" "$US_COUNT"

# Check data quality
hours_us=$(echo "scale=1; $US_COUNT * 5 / 60" | bc)
echo -e "  Duration:     ~${hours_us} hours"
echo ""

# Analyze EU Germany
echo -e "${BLUE}EU GERMANY (Nuremberg/Falkenstein)${NC}"
echo "-------------------------------------------"
EU_STATS=$(calculate_stats "$EU_LOG" "EU Germany")
if [ $? -ne 0 ]; then
    exit 1
fi

EU_AVG=$(echo "$EU_STATS" | cut -d',' -f1)
EU_MIN=$(echo "$EU_STATS" | cut -d',' -f2)
EU_MAX=$(echo "$EU_STATS" | cut -d',' -f3)
EU_COUNT=$(echo "$EU_STATS" | cut -d',' -f4)

printf "  Average TTFB: %8.2f ms\n" "$EU_AVG"
printf "  Min TTFB:     %8.2f ms\n" "$EU_MIN"
printf "  Max TTFB:     %8.2f ms\n" "$EU_MAX"
printf "  Samples:      %8d\n" "$EU_COUNT"

hours_eu=$(echo "scale=1; $EU_COUNT * 5 / 60" | bc)
echo -e "  Duration:     ~${hours_eu} hours"
echo ""

# Compare results
echo "========================================="
echo "  COMPARISON & RECOMMENDATION"
echo "========================================="
echo ""

# Calculate difference
DIFF=$(echo "scale=2; $US_AVG - $EU_AVG" | bc)
ABS_DIFF=$(echo "$DIFF" | tr -d '-')

if (( $(echo "$DIFF < 0" | bc -l) )); then
    # US is faster
    PCT=$(echo "scale=1; ($ABS_DIFF / $EU_AVG) * 100" | bc)
    echo -e "${GREEN}✅ US OREGON IS FASTER${NC}"
    echo ""
    printf "  US Oregon:  %.2f ms average\n" "$US_AVG"
    printf "  EU Germany: %.2f ms average\n" "$EU_AVG"
    printf "  ${GREEN}Difference: %.2f ms faster (%.1f%% improvement)${NC}\n" "$ABS_DIFF" "$PCT"
    echo ""

    # Decision guidance
    if (( $(echo "$ABS_DIFF > 50" | bc -l) )); then
        echo -e "${GREEN}🎯 STRONG RECOMMENDATION: Choose US Oregon${NC}"
        echo "   Reason: Significant latency advantage (>50ms)"
        DECISION="US_STRONG"
    elif (( $(echo "$ABS_DIFF > 10" | bc -l) )); then
        echo -e "${GREEN}📊 RECOMMENDATION: Choose US Oregon${NC}"
        echo "   Reason: Measurable latency advantage"
        DECISION="US_MODERATE"
    else
        echo -e "${YELLOW}⚖️  MARGINAL: US Oregon slightly faster${NC}"
        echo "   Reason: Difference is minimal (<10ms)"
        DECISION="US_MARGINAL"
    fi

else
    # EU is faster
    PCT=$(echo "scale=1; ($ABS_DIFF / $US_AVG) * 100" | bc)
    echo -e "${GREEN}✅ EU GERMANY IS FASTER${NC}"
    echo ""
    printf "  EU Germany: %.2f ms average\n" "$EU_AVG"
    printf "  US Oregon:  %.2f ms average\n" "$US_AVG"
    printf "  ${GREEN}Difference: %.2f ms faster (%.1f%% improvement)${NC}\n" "$ABS_DIFF" "$PCT"
    echo ""

    # Decision guidance
    if (( $(echo "$ABS_DIFF > 50" | bc -l) )); then
        echo -e "${GREEN}🎯 STRONG RECOMMENDATION: Choose EU Germany${NC}"
        echo "   Reason: Significant latency advantage (>50ms)"
        DECISION="EU_STRONG"
    elif (( $(echo "$ABS_DIFF > 10" | bc -l) )); then
        echo -e "${GREEN}📊 RECOMMENDATION: Choose EU Germany${NC}"
        echo "   Reason: Measurable latency advantage"
        echo "   Bonus: 10x more bandwidth (20TB vs 2TB)"
        DECISION="EU_MODERATE"
    else
        echo -e "${YELLOW}⚖️  MARGINAL: EU Germany slightly faster${NC}"
        echo "   Reason: Difference is minimal (<10ms)"
        echo "   Consider: EU costs $6.12/year more but includes 20TB bandwidth"
        DECISION="EU_MARGINAL"
    fi
fi

echo ""
echo "========================================="
echo "  DETAILED DECISION GUIDE"
echo "========================================="
echo ""

case "$DECISION" in
    US_STRONG)
        echo "CHOOSE: Hetzner US Oregon CPX21 at \$9.99/month"
        echo ""
        echo "Reasoning:"
        echo "  • Significantly faster API latency (>50ms advantage)"
        echo "  • Saves \$6.12/year vs EU option"
        echo "  • 2TB bandwidth is adequate for agent workload"
        echo "  • Predictable US→US routing"
        ;;
    US_MODERATE)
        echo "CHOOSE: Hetzner US Oregon CPX21 at \$9.99/month"
        echo ""
        echo "Reasoning:"
        echo "  • Measurably faster API latency"
        echo "  • Saves \$6.12/year vs EU option"
        echo "  • Better value proposition"
        ;;
    US_MARGINAL)
        echo "RECOMMENDED: Hetzner US Oregon CPX21 at \$9.99/month"
        echo ""
        echo "Reasoning:"
        echo "  • Slightly faster (within margin of error)"
        echo "  • Saves \$6.12/year"
        echo "  • Geographic proximity to LA (better SSH latency)"
        echo ""
        echo "Alternative: EU Germany could work if you value 20TB bandwidth"
        ;;
    EU_STRONG)
        echo "CHOOSE: Hetzner EU Germany CPX21 at \$10.50/month"
        echo ""
        echo "Reasoning:"
        echo "  • Significantly faster API latency (>50ms advantage)"
        echo "  • Cloudflare anycast routes efficiently to EU backend"
        echo "  • 10x bandwidth (20TB vs 2TB)"
        echo "  • Extra \$6.12/year easily justified by performance"
        ;;
    EU_MODERATE)
        echo "CHOOSE: Hetzner EU Germany CPX21 at \$10.50/month"
        echo ""
        echo "Reasoning:"
        echo "  • Measurably faster API latency"
        echo "  • 10x bandwidth (20TB vs 2TB)"
        echo "  • \$6.12/year premium is worthwhile"
        ;;
    EU_MARGINAL)
        echo "YOUR CHOICE: Both options are viable"
        echo ""
        echo "Option A: Hetzner EU Germany CPX21 at \$10.50/month"
        echo "  Pros: Slightly faster, 20TB bandwidth"
        echo "  Cons: +\$6.12/year, longer SSH latency from LA"
        echo ""
        echo "Option B: Hetzner US Oregon CPX21 at \$9.99/month"
        echo "  Pros: \$6.12/year cheaper, closer to LA"
        echo "  Cons: Only 2TB bandwidth (still 40x your usage)"
        ;;
esac

echo ""
echo "========================================="
echo "  DATA QUALITY CHECK"
echo "========================================="
echo ""

# Check if we have enough samples
MIN_SAMPLES=576  # 48 hours worth

if [ "$US_COUNT" -lt "$MIN_SAMPLES" ] || [ "$EU_COUNT" -lt "$MIN_SAMPLES" ]; then
    echo -e "${YELLOW}⚠️  WARNING: Limited sample size${NC}"
    echo ""
    echo "  Recommended: At least 576 samples (48 hours)"
    echo "  US samples:  $US_COUNT"
    echo "  EU samples:  $EU_COUNT"
    echo ""
    echo "  Consider running test longer for more confidence"
else
    echo -e "${GREEN}✅ Good sample size (48+ hours of data)${NC}"
    echo "  Results are statistically meaningful"
fi

echo ""
echo "========================================="
echo "  NEXT STEPS"
echo "========================================="
echo ""
echo "1. Review the recommendation above"
echo "2. Make your provider decision"
echo "3. DELETE both test instances to stop charges!"
echo "   (See cleanup section in guide)"
echo ""
echo "Total test cost: ~\$1.75 for this data-driven decision"
echo ""
