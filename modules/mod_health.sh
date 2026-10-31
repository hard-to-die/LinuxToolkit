#!/usr/bin/env bash

run_health_monitor() {
    clear
    echo "================================================="
    echo "       MODULE: System Resource Health Check      "
    echo "================================================="

    local CPU_THRESHOLD=80
    local RAM_THRESHOLD=80
    local DISK_THRESHOLD=85
    local LOG_FILE="./health.log"

    local RED='\033[0;31m'
    local GREEN='\033[0;32m'
    local YELLOW='\133[1;33m'
    local NC='\033[0m'

    # CPU Check
    local cpu_idle
    cpu_idle=$(vmstat 1 2 | tail -1 | awk '{print $15}')
    local cpu_usage=$(( 100 - cpu_idle ))

    # Memory Check
    local mem_total mem_available
    mem_total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
    mem_available=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
    local mem_pct=$(( ((mem_total - mem_available) * 100) / mem_total ))

    # Disk Check
    local disk_usage
    disk_usage=$(df / --output=pcent | tail -1 | tr -dc '0-9')

    # Status Evaluation
    echo -e "Metric\t\tUsage\t\tThreshold\tStatus"
    echo "-------------------------------------------------"

    # CPU status
    if (( cpu_usage >= CPU_THRESHOLD )); then
        printf "CPU\t\t%d%%\t\t%d%%\t\t${RED}[CRITICAL]${NC}\n" "$cpu_usage" "$CPU_THRESHOLD"
    else
        printf "CPU\t\t%d%%\t\t%d%%\t\t${GREEN}[HEALTHY]${NC}\n" "$cpu_usage" "$CPU_THRESHOLD"
    fi

    # RAM status
    if (( mem_pct >= RAM_THRESHOLD )); then
        printf "Memory\t\t%d%%\t\t%d%%\t\t${RED}[CRITICAL]${NC}\n" "$mem_pct" "$RAM_THRESHOLD"
    else
        printf "Memory\t\t%d%%\t\t%d%%\t\t${GREEN}[HEALTHY]${NC}\n" "$mem_pct" "$RAM_THRESHOLD"
    fi

    # Disk status
    if (( disk_usage >= DISK_THRESHOLD )); then
        printf "Disk (/)\t%d%%\t\t%d%%\t\t${RED}[CRITICAL]${NC}\n" "$disk_usage" "$DISK_THRESHOLD"
    else
        printf "Disk (/)\t%d%%\t\t%d%%\t\t${GREEN}[HEALTHY]${NC}\n" "$disk_usage" "$DISK_THRESHOLD"
    fi

    # Log to file
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] CPU: ${cpu_usage}% | RAM: ${mem_pct}% | DISK: ${disk_usage}%" >> "$LOG_FILE"
    echo -e "\nLog updated at: $LOG_FILE"
    echo "================================================="
    read -rp "Press [Enter] to return to menu..."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_health_monitor
fi
