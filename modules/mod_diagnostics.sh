run_diagnostics() {
    clear
    echo "================================================="
    echo "       SUITE: Full System Diagnostics            "
    echo "================================================="
    
    echo -e "\n[*] 1. Validating Toolkit Modules..."
    for mod in mod_health.sh mod_organize.sh mod_password.sh; do
        if [[ -f "$SCRIPT_DIR/modules/$mod" ]]; then
            echo -e "    - $mod: \033[0;32m[FOUND]\033[0m"
        else
            echo -e "    - $mod: \033[0;31m[MISSING]\033[0m"
        fi
    done

    echo -e "\n[*] 2. Core System Metrics..."
    echo "    - Uptime     : $(uptime -p 2>/dev/null || uptime)"
    echo "    - Active User: $(whoami)"
    echo "    - Kernel     : $(uname -r)"

    echo -e "\n[*] 3. Network Connectivity..."
    if ping -c 1 -W 2 8.8.8.8 &>/dev/null; then
        echo -e "    - Internet Connectivity: \033[0;32m[CONNECTED]\033[0m"
    else
        echo -e "    - Internet Connectivity: \033[0;31m[OFFLINE]\033[0m"
    fi

    echo -e "\n[*] 4. Running Hardware Health Check..."
    echo "-------------------------------------------------"
    # Call the actual monitor without its interactive pause
    local CPU_THRESHOLD=80
    local RAM_THRESHOLD=80
    local DISK_THRESHOLD=85

    local cpu_idle=$(vmstat 1 2 | tail -1 | awk '{print $15}')
    local cpu_usage=$(( 100 - cpu_idle ))

    local mem_total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
    local mem_available=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
    local mem_pct=$(( ((mem_total - mem_available) * 100) / mem_total ))

    local disk_usage=$(df / --output=pcent | tail -1 | tr -dc '0-9')

    printf "CPU: %d%% | RAM: %d%% | Root Disk: %d%%\n" "$cpu_usage" "$mem_pct" "$disk_usage"
    echo "================================================="
    read -rp "Diagnostics complete. Press [Enter] to return..."
}
