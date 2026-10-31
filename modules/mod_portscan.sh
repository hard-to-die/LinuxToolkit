#!/usr/bin/env bash
# ==============================================================================
# Module: Network Port Scanner (Multithreaded)
# Description: Uses native Bash /dev/tcp with parallel batch processing.
# ==============================================================================

run_port_scanner() {
    clear
    echo -e "${CYAN}${BOLD}========================================================================${NC}"
    echo -e "${CYAN}${BOLD}               MULTITHREADED NETWORK PORT SCANNER                       ${NC}"
    echo -e "${CYAN}${BOLD}========================================================================${NC}"
    
    read -rp "Enter target IP or hostname (e.g., 127.0.0.1 or scanme.nmap.org): " target
    if [[ -z "$target" ]]; then
        echo -e "\n[!] Target cannot be empty."
        read -rp "Press [Enter] to return..."
        return
    fi

    echo " [1] Scan Common Ports (21, 22, 23, 25, 53, 80, 443, 445, 3389)"
    echo " [2] Scan Custom Range (e.g., 1-1000)"
    read -rp "Select scan type [1-2]: " scan_type

    local ports=()
    if [[ "$scan_type" == "1" ]]; then
        ports=(21 22 23 25 53 80 110 139 443 445 3306 3389 8080)
    elif [[ "$scan_type" == "2" ]]; then
        read -rp "Enter start port: " start_port
        read -rp "Enter end port: " end_port
        for ((i=start_port; i<=end_port; i++)); do
            ports+=($i)
        done
    else
        echo -e "\n[!] Invalid selection."
        read -rp "Press [Enter] to return..."
        return
    fi

    echo -e "\n[*] Scanning $target with 50 concurrent threads..."
    echo -e "------------------------------------------------------------------------"
    
    # Use a temporary file to safely count results from background subshells
    local tmp_file=$(mktemp)
    local count=0

    for port in "${ports[@]}"; do
        # Launch each port scan as a background process
        (
            if timeout 1 bash -c "echo >/dev/tcp/$target/$port" 2>/dev/null; then
                echo -e "[+] Port ${BOLD}$port${NC} is ${BLUE}OPEN${NC}"
                echo "$port" >> "$tmp_file"
            fi
        ) &
        
        # Batch limiter: Wait for every 50 background jobs to finish before continuing
        ((count++))
        if (( count % 50 == 0 )); then
            wait
        fi
    done
    
    # Catch any remaining jobs
    wait 

    echo -e "------------------------------------------------------------------------"
    local open_ports=$(wc -l < "$tmp_file")
    rm -f "$tmp_file" # Clean up
    
    echo -e "Scan complete. Found $open_ports open port(s)."
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] Scanned $target - Found $open_ports open ports" >> "$SCRIPT_DIR/portscan.log"
    
    read -rp "Press [Enter] to return to main menu..."
}
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_port_scanner
fi
