run_port_scanner() {
    clear
    echo "================================================="
    echo "        MODULE: Network Port Scanner             "
    echo "================================================="
# taking argu... for netmap
    local LOCAL_IP
    LOCAL_IP="${1:-$(ip -4 addr show | grep inet | grep -v 127.0.0.1 | awk '{print $2}' | cut -d/ -f1 | head -1)}"

    if [[ -z "$LOCAL_IP" ]]; then
        echo -e "${RED}[-] Could not detect local IP.${NC}"
        read -rp "Press [Enter] to return..."
        return 1
    fi

    echo -e "${CYAN}[i] Your local IP: $LOCAL_IP${NC}"
    echo ""
    echo " [1] Scan my own machine or targetted ($LOCAL_IP)"
    echo " [2] Scan another device (enter IP manually)"
    echo " [3] Discover devices on my network"
    echo " [B] Back to menu"
    echo "-------------------------------------------------"
    read -rp "Select [1-3 / B]: " SCAN_CHOICE

    local TARGET=""
    case "$SCAN_CHOICE" in
        1)
            TARGET="$LOCAL_IP"
            ;;
        2)
            read -rp "Enter target IP or hostname: " TARGET
            ;;
        3)
            local SUBNET
            SUBNET=$(echo "$LOCAL_IP" | cut -d. -f1-3).0/24

            echo -e "\n${CYAN}[*] Scanning network: $SUBNET${NC}"
            if command -v nmap &>/dev/null; then
                nmap -sn "$SUBNET" | grep "Nmap scan report" | awk '{print $5}'
            else
                ip neigh show | awk '{print $1}'
            fi

            echo ""
            read -rp "Enter target IP from the list above: " TARGET
            ;;
        [bB])
            return 0
            ;;
        *)
            echo -e "${RED}[-] Invalid selection.${NC}"
            read -rp "Press [Enter] to return..."
            return 1
            ;;
    esac

    if [[ -z "$TARGET" ]]; then
        echo -e "${RED}[-] No target specified.${NC}"
        read -rp "Press [Enter] to return..."
        return 1
    fi

    read -rp "Enter port range [Default: 1-1024]: " PORT_RANGE
    PORT_RANGE="${PORT_RANGE:-1-1024}"

    # Parse range
    local START_PORT="${PORT_RANGE%%-*}"
    local END_PORT="${PORT_RANGE##*-}"

    if ! [[ "$START_PORT" =~ ^[0-9]+$ && "$END_PORT" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}[-] Error: Invalid port range format.${NC}"
        read -rp "Press [Enter] to return..."
        return 1
    fi

    if (( START_PORT < 1 || END_PORT > 65535 || START_PORT > END_PORT )); then
        echo -e "${RED}[-] Error: Port range must be 1-65535 and start <= end.${NC}"
        read -rp "Press [Enter] to return..."
        return 1
    fi

    # Connectivity check
    echo -e "\n${CYAN}[*] Testing connectivity to $TARGET...${NC}"
    if ! ping -c 1 -W 2 "$TARGET" &>/dev/null; then
        echo -e "${RED}[-] Host unreachable.${NC}"
        read -rp "Press [Enter] to return..."
        return 1
    fi
    echo -e "${GREEN}[+] Host is reachable.${NC}"

    echo -e "\n${CYAN}[*] Scanning ports $START_PORT-$END_PORT on $TARGET...${NC}"
    echo "-------------------------------------------------"
    printf "PORT\tSTATE\n"

    local open_count=0
    local total_ports=$(( END_PORT - START_PORT + 1 ))
    local LOG_FILE="./logs/portscan.log"
    mkdir -p "$(dirname "$LOG_FILE")"

    if command -v nmap &>/dev/null; then
        echo -e "${BLUE}[i] Using nmap (fast mode)${NC}"
        echo "-------------------------------------------------"

        local nmap_output
        nmap_output=$(nmap -p "$PORT_RANGE" --open -T4 "$TARGET" 2>/dev/null)

        while IFS= read -r line; do
            if [[ "$line" =~ ^([0-9]+)/tcp[[:space:]]+open ]]; then
                local port="${BASH_REMATCH[1]}"
                echo -e "$port/tcp\t${GREEN}OPEN${NC}"
                ((open_count++))
            fi
        done <<< "$nmap_output"
    else
        echo -e "${YELLOW}[!] nmap not found. Falling back to /dev/tcp (slow mode).${NC}"
        echo "-------------------------------------------------"

        for (( port=START_PORT; port<=END_PORT; port++ )); do
            if timeout 0.3 bash -c "echo > /dev/tcp/$TARGET/$port" 2>/dev/null; then
                echo -e "$port/tcp\t${GREEN}OPEN${NC}"
                ((open_count++))
            fi
        done
    fi

    echo "-------------------------------------------------"
    echo -e "Scan complete: ${BOLD}${CYAN}$open_count${NC} open port(s) out of ${BOLD}${CYAN}$total_ports${NC} scanned."

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Target: $TARGET | Range: $PORT_RANGE | Open: $open_count" >> "$LOG_FILE"
    echo -e "\nLog updated at: $LOG_FILE"
    echo "================================================="
    read -rp "Press [Enter] to return to menu..."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_port_scanner
fi
