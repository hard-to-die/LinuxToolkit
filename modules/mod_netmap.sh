#!/usr/bin/env bash

# Fallback colors (used when run standalone)
RED="${RED:-\033[0;31m}"
GREEN="${GREEN:-\033[0;32m}"
YELLOW="${YELLOW:-\033[1;33m}"
BLUE="${BLUE:-\033[0;34m}"
CYAN="${CYAN:-\033[0;36m}"
BOLD="${BOLD:-\033[1m}"
NC="${NC:-\033[0m}"

run_network_mapper() {
    clear
    echo "================================================="
    echo "         MODULE: Network Device Mapper           "
    echo "================================================="

    # Detect local IP
    local LOCAL_IP
    LOCAL_IP=$(ip -4 addr show | grep inet | grep -v 127.0.0.1 | awk '{print $2}' | cut -d/ -f1 | head -1)

    if [[ -z "$LOCAL_IP" ]]; then
        echo -e "${RED}[-] Could not detect local IP.${NC}"
        read -rp "Press [Enter] to return..."
        return 1
    fi

    local SUBNET
    SUBNET=$(echo "$LOCAL_IP" | cut -d. -f1-3).0/24

    echo -e "${CYAN}[i] Your IP: $LOCAL_IP${NC}"
    echo -e "${CYAN}[i] Scanning subnet: $SUBNET${NC}"
    echo "-------------------------------------------------"

    # Check for nmap
    if ! command -v nmap &>/dev/null; then
        echo -e "${RED}[-] nmap is not installed.${NC}"
        echo -e "${YELLOW}[!] Install it: sudo pacman -S nmap${NC}"
        read -rp "Press [Enter] to return..."
        return 1
    fi

    echo -e "${BLUE}[*] Discovering live devices...${NC}"
    echo ""

    # Run nmap ping scan
    local nmap_output
    nmap_output=$(nmap -sn "$SUBNET" 2>/dev/null)

    # Parse results
    local -a DEVICES=()
    # Extract unique IPs from nmap output
local -a DEVICES=()

# Get all IPs that responded (one per line, deduplicated)
local ips
ips=$(echo "$nmap_output" | grep -oP 'Nmap scan report for (?:\S+ \()?\K[0-9.]+' | sort -u)

if [[ -z "$ips" ]]; then
    echo -e "${YELLOW}[!] No devices found.${NC}"
    read -rp "Press [Enter] to return..."
    return 1
fi

# Build DEVICES array with IP and MAC
while IFS= read -r ip; do
    # Try to find MAC address for this IP
    local mac
    mac=$(echo "$nmap_output" | grep -A2 "Nmap scan report for .*$ip" | grep -oP 'MAC Address: \K[0-9A-Fa-f:]+' | head -1)
    [[ -z "$mac" ]] && mac="unknown"
    DEVICES+=("$ip|$mac")
done <<< "$ips"

    if [[ ${#DEVICES[@]} -eq 0 ]]; then
        echo -e "${YELLOW}[!] No devices found.${NC}"
        read -rp "Press [Enter] to return..."
        return 1
    fi

    # Display devices
    printf "%-5s %-18s %-20s %s\n" "#" "IP ADDRESS" "MAC ADDRESS" "HOSTNAME"
    echo "-------------------------------------------------"

    local i=1
    for entry in "${DEVICES[@]}"; do
        local ip="${entry%%|*}"
        local mac="${entry##*|}"
        local hostname
        hostname=$(getent hosts "$ip" 2>/dev/null | awk '{print $2}' || echo "-")
        [[ -z "$hostname" ]] && hostname="-"

        printf "%-5s %-18s %-20s %s\n" "$i" "$ip" "$mac" "$hostname"
        ((i++))
    done

    echo "-------------------------------------------------"
    echo -e "Total: ${BOLD}${CYAN}${#DEVICES[@]}${NC} device(s) found."

    # Log results
    local LOG_FILE="./logs/netmap.log"
    mkdir -p "$(dirname "$LOG_FILE")"
    {
        echo "=== Scan at $(date '+%Y-%m-%d %H:%M:%S') ==="
        echo "Subnet: $SUBNET"
        for entry in "${DEVICES[@]}"; do
            echo "  ${entry%%|*} | ${entry##*|}"
        done
        echo ""
    } >> "$LOG_FILE"

    echo -e "\nLog updated at: $LOG_FILE"

    # Offer to scan a device
    echo ""
    read -rp "Scan ports of a device? Enter # or [Enter] to skip: " pick

    if [[ -n "$pick" ]] && [[ "$pick" =~ ^[0-9]+$ ]] && (( pick >= 1 && pick <= ${#DEVICES[@]} )); then
        local selected="${DEVICES[$((pick-1))]}"
        local target_ip="${selected%%|*}"

        echo -e "\n${CYAN}[*] Launching port scanner for $target_ip...${NC}"
        sleep 1

        # Call the port scanner with the selected IP
        if declare -f run_port_scanner &>/dev/null; then
            run_port_scanner "$target_ip"
        else
            echo -e "${YELLOW}[!] Port scanner module not loaded.${NC}"
            read -rp "Press [Enter] to return..."
        fi
    else
        read -rp "Press [Enter] to return to menu..."
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_network_mapper
fi
