#!/bin/bash
###############################################################################
# Resource Usage Analyzer
#
# Analyzes historical resource usage from logs
# Provides scaling recommendations
#
# Usage: bash ~/scripts/monitoring/analyze-usage.sh [days]
###############################################################################

DAYS=${1:-7}
LOG_FILE=~/agents/logs/resource-usage.log

if [ ! -f "$LOG_FILE" ]; then
    echo "Error: Log file not found at $LOG_FILE"
    echo "Have you started resource monitoring?"
    exit 1
fi

# Calculate number of lines for N days (288 samples per day at 5-min intervals)
SAMPLES=$((DAYS * 288))

echo "======================================"
echo "  RESOURCE USAGE ANALYSIS"
echo "  Last $DAYS days"
echo "======================================"
echo ""

# CPU Analysis
echo "CPU Usage:"
AVG_CPU=$(tail -n $SAMPLES "$LOG_FILE" | awk -F',' '{sum+=$2; count++} END {printf "%.1f", sum/count}')
PEAK_CPU=$(tail -n $SAMPLES "$LOG_FILE" | awk -F',' '{if($2>max) max=$2} END {printf "%.1f", max}')
echo "  Average: ${AVG_CPU}%"
echo "  Peak:    ${PEAK_CPU}%"

# RAM Analysis
echo ""
echo "RAM Usage:"
AVG_RAM=$(tail -n $SAMPLES "$LOG_FILE" | awk -F',' '{sum+=$3; count++} END {printf "%.1f", sum/count}')
PEAK_RAM=$(tail -n $SAMPLES "$LOG_FILE" | awk -F',' '{if($3>max) max=$3} END {printf "%.1f", max}')
echo "  Average: ${AVG_RAM}%"
echo "  Peak:    ${PEAK_RAM}%"

# Load Average
echo ""
echo "Load Average:"
AVG_LOAD=$(tail -n $SAMPLES "$LOG_FILE" | awk -F',' '{sum+=$4; count++} END {printf "%.2f", sum/count}')
PEAK_LOAD=$(tail -n $SAMPLES "$LOG_FILE" | awk -F',' '{if($4>max) max=$4} END {printf "%.2f", max}')
echo "  Average: ${AVG_LOAD}"
echo "  Peak:    ${PEAK_LOAD}"

# Swap Usage
echo ""
echo "Swap Usage:"
AVG_SWAP=$(tail -n $SAMPLES "$LOG_FILE" | awk -F',' '{sum+=$5; count++} END {printf "%.1f", sum/count}')
PEAK_SWAP=$(tail -n $SAMPLES "$LOG_FILE" | awk -F',' '{if($5>max) max=$5} END {printf "%.1f", max}')
echo "  Average: ${AVG_SWAP}%"
echo "  Peak:    ${PEAK_SWAP}%"

# Disk Usage
echo ""
echo "Disk Usage:"
CURR_DISK=$(tail -n 1 "$LOG_FILE" | awk -F',' '{print $6}')
echo "  Current: ${CURR_DISK}%"

echo ""
echo "======================================"
echo "  SCALING RECOMMENDATION"
echo "======================================"
echo ""

# Determine current instance type from RAM
TOTAL_RAM=$(free -g | grep Mem | awk '{print $2}')
if [ $TOTAL_RAM -le 4 ]; then
    INSTANCE="s1-4"
    VCPU=1
    NEXT_UP="b2-7"
elif [ $TOTAL_RAM -le 7 ]; then
    INSTANCE="b2-7"
    VCPU=2
    NEXT_UP="b2-15"
    NEXT_DOWN="s1-4"
else
    INSTANCE="b2-15+"
    VCPU=4
    NEXT_DOWN="b2-7"
fi

echo "Current Instance: $INSTANCE ($VCPU vCPU, ${TOTAL_RAM}GB RAM)"
echo ""

# Check if should scale UP
SCALE_UP=0
if (( $(echo "$AVG_CPU > 70" | bc -l) )); then
    echo "⚠️  CPU average >70% - consider scaling up"
    SCALE_UP=1
fi
if (( $(echo "$PEAK_CPU > 90" | bc -l) )); then
    echo "⚠️  CPU peak >90% - consider scaling up"
    SCALE_UP=1
fi
if (( $(echo "$AVG_RAM > 85" | bc -l) )); then
    echo "🚨 RAM average >85% - SCALE UP SOON"
    SCALE_UP=1
fi
if (( $(echo "$PEAK_SWAP > 0" | bc -l) )); then
    echo "🚨 Swap in use - SCALE UP IMMEDIATELY"
    SCALE_UP=1
fi
if (( $(echo "$AVG_LOAD > ($VCPU * 1.5)" | bc -l) )); then
    echo "⚠️  Load average high - consider scaling up"
    SCALE_UP=1
fi

# Check if can scale DOWN (only if not scaling up)
if [ $SCALE_UP -eq 0 ] && [ -n "$NEXT_DOWN" ]; then
    CAN_SCALE_DOWN=1

    if (( $(echo "$AVG_CPU > 30" | bc -l) )); then
        CAN_SCALE_DOWN=0
    fi
    if (( $(echo "$PEAK_CPU > 60" | bc -l) )); then
        CAN_SCALE_DOWN=0
    fi
    if (( $(echo "$AVG_RAM > 50" | bc -l) )); then
        CAN_SCALE_DOWN=0
    fi
    if (( $(echo "$PEAK_SWAP > 0" | bc -l) )); then
        CAN_SCALE_DOWN=0
    fi

    # Check if peak RAM would fit in smaller instance
    if [ "$NEXT_DOWN" = "s1-4" ]; then
        # s1-4 has 4GB RAM
        PEAK_RAM_GB=$(echo "scale=2; ($PEAK_RAM / 100) * $TOTAL_RAM" | bc)
        PEAK_RAM_PERCENT_S14=$(echo "scale=1; ($PEAK_RAM_GB / 4) * 100" | bc)

        if (( $(echo "$PEAK_RAM_PERCENT_S14 > 75" | bc -l) )); then
            echo "⚠️  Peak RAM (${PEAK_RAM_GB}GB) too high for s1-4 (would be ${PEAK_RAM_PERCENT_S14}%)"
            CAN_SCALE_DOWN=0
        fi
    fi

    if [ $CAN_SCALE_DOWN -eq 1 ] && [ $DAYS -ge 7 ]; then
        echo "✅ Can potentially scale down to $NEXT_DOWN"
        echo "   Potential savings: \$7/month (if b2-7→s1-4)"
        echo ""
        echo "   Before scaling down:"
        echo "   1. Verify $DAYS days is representative workload"
        echo "   2. Schedule during low-activity period"
        echo "   3. Monitor closely after downgrade"
    elif [ $DAYS -lt 7 ]; then
        echo "⏳ Collect more data (need 7+ days, have $DAYS days)"
    fi
fi

if [ $SCALE_UP -eq 0 ] && ([ -z "$NEXT_DOWN" ] || [ $CAN_SCALE_DOWN -eq 0 ]); then
    echo "✅ Current instance size is appropriate"
    echo "   Continue monitoring for optimal performance"
fi

if [ $SCALE_UP -eq 1 ] && [ -n "$NEXT_UP" ]; then
    echo ""
    echo "📈 Recommendation: Scale up to $NEXT_UP"
    echo "   Additional cost: ~\$7/month (s1-4→b2-7)"
fi

echo ""
echo "======================================"
