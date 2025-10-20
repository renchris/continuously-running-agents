#!/bin/bash
###############################################################################
# Resource Statistics Logger
#
# Logs CPU, RAM, Load, Swap, and Disk usage every 5 minutes
# Used for long-term scaling decision analysis
#
# Usage: Run in tmux background session
#   tmux new -d -s resource-monitor "bash ~/scripts/monitoring/resource-stats.sh"
###############################################################################

LOG_FILE=~/agents/logs/resource-usage.log
INTERVAL=300  # 5 minutes

# Ensure log directory exists
mkdir -p ~/agents/logs

echo "Starting resource monitoring - logging to $LOG_FILE"
echo "Timestamp,CPU%,RAM%,Load1m,Swap%,Disk%" > $LOG_FILE

while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    MEM=$(free | grep Mem | awk '{print ($3/$2) * 100.0}')
    LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}')
    SWAP=$(free | grep Swap | awk '{if($2>0) print ($3/$2) * 100.0; else print 0}')
    DISK=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')

    echo "$TIMESTAMP,$CPU,$MEM,$LOAD,$SWAP,$DISK" >> $LOG_FILE

    sleep $INTERVAL
done
