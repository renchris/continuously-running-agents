#!/bin/bash
###############################################################################
# Live Resource Dashboard
#
# Real-time monitoring with historical context
#
# Usage: bash ~/scripts/monitoring/dashboard.sh
###############################################################################

while true; do
    clear
    echo "======================================"
    echo "  RESOURCE MONITORING DASHBOARD"
    echo "  $(date '+%Y-%m-%d %H:%M:%S')"
    echo "======================================"
    echo ""

    # Current Resources
    CPU_CURRENT=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    RAM_USED=$(free -h | grep Mem | awk '{print $3}')
    RAM_TOTAL=$(free -h | grep Mem | awk '{print $2}')
    RAM_PERCENT=$(free | grep Mem | awk '{print int($3/$2*100)}')
    SWAP_USED=$(free -h | grep Swap | awk '{print $3}')
    SWAP_TOTAL=$(free -h | grep Swap | awk '{print $2}')
    DISK_USED=$(df -h / | awk 'NR==2 {print $3}')
    DISK_TOTAL=$(df -h / | awk 'NR==2 {print $2}')
    DISK_PERCENT=$(df -h / | awk 'NR==2 {print $5}')
    LOAD=$(uptime | awk -F'load average:' '{print $2}')

    echo "Current Resources:"
    echo "  CPU:  ${CPU_CURRENT}%"
    echo "  RAM:  ${RAM_USED}/${RAM_TOTAL} (${RAM_PERCENT}%)"
    echo "  Swap: ${SWAP_USED}/${SWAP_TOTAL}"
    echo "  Disk: ${DISK_USED}/${DISK_TOTAL} (${DISK_PERCENT})"
    echo "  Load:${LOAD}"
    echo ""

    # Historical averages
    if [ -f ~/agents/logs/resource-usage.log ]; then
        echo "7-Day Averages:"
        AVG_CPU=$(tail -n 2000 ~/agents/logs/resource-usage.log | awk -F',' '{sum+=$2; count++} END {printf "%.1f", sum/count}')
        PEAK_CPU=$(tail -n 2000 ~/agents/logs/resource-usage.log | awk -F',' '{if($2>max) max=$2} END {printf "%.1f", max}')
        AVG_RAM=$(tail -n 2000 ~/agents/logs/resource-usage.log | awk -F',' '{sum+=$3; count++} END {printf "%.1f", sum/count}')
        PEAK_RAM=$(tail -n 2000 ~/agents/logs/resource-usage.log | awk -F',' '{if($3>max) max=$3} END {printf "%.1f", max}')

        echo "  Avg CPU:  ${AVG_CPU}%"
        echo "  Peak CPU: ${PEAK_CPU}%"
        echo "  Avg RAM:  ${AVG_RAM}%"
        echo "  Peak RAM: ${PEAK_RAM}%"
        echo ""

        echo "Scale Assessment:"
        if (( $(echo "$AVG_CPU < 30" | bc -l) )) && \
           (( $(echo "$PEAK_CPU < 60" | bc -l) )) && \
           (( $(echo "$AVG_RAM < 50" | bc -l) )) && \
           (( $(echo "$PEAK_RAM < 75" | bc -l) )); then
            echo "  ✅ Could potentially scale down"
            echo "     (Run analyze-usage.sh for details)"
        elif (( $(echo "$AVG_CPU > 70" | bc -l) )) || \
             (( $(echo "$AVG_RAM > 85" | bc -l) )); then
            echo "  ⚠️  Consider scaling up"
        else
            echo "  ✅ Current size is appropriate"
        fi
    else
        echo "Historical Data:"
        echo "  (No data yet - monitoring not started)"
        echo ""
        echo "  Start monitoring with:"
        echo "  tmux new -d -s resource-monitor 'bash ~/scripts/monitoring/resource-stats.sh'"
    fi

    echo ""
    echo "Active Agents: $(tmux ls 2>/dev/null | grep -c agent || echo 0)"
    echo "Tmux Sessions: $(tmux ls 2>/dev/null | wc -l || echo 0)"
    echo ""
    echo "======================================"
    echo "Refreshing in 5s... (Ctrl+C to exit)"

    sleep 5
done
