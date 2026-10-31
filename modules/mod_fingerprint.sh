#!/usr/bin/env bash

# Fallback colors
RED="${RED:-\033[0;31m}"
GREEN="${GREEN:-\033[0;32m}"
YELLOW="${YELLOW:-\033[1;33m}"
BLUE="${BLUE:-\033[0;34m}"
CYAN="${CYAN:-\033[0;36m}"
BOLD="${BOLD:-\033[1m}"
NC="${NC:-\033[0m}"

run_fingerprinter() {
    clear
    echo "================================================="
    echo "       MODULE: Service Fingerprinter             "
    echo "================================================="

    local LOCAL_IP
    LOCAL_IP="${1:-$(ip -4 addr show | grep inet | grep -v 127.0.0.1 | awk '{print $2}' | cut -d/ -f1 | head -1)}"

    if [[ -z "$LOCAL_IP" ]]; then
        echo -e "${RED}[-] Could not detect local IP.${NC}"
        read -rp "Press [Enter] to return..."
        return 1
    fi

    read -rp "Enter target IP [Default: $LOCAL_IP]: " TARGET
    TARGET="${TARGET:-$LOCAL_IP}"

    read -rp "Enter ports to fingerprint [Default: 1-1024]: " PORT_RANGE
    PORT_RANGE="${PORT_RANGE:-1-1024}"

    if ! command -v nmap &>/dev/null; then
        echo -e "${RED}[-] nmap is not installed.${NC}"
        echo -e "${YELLOW}[!] Install it: sudo pacman -S nmap${NC}"
        read -rp "Press [Enter] to return..."
        return 1
    fi

    echo -e "\n${CYAN}[*] Testing connectivity to $TARGET...${NC}"
    if ! ping -c 1 -W 2 "$TARGET" &>/dev/null; then
        echo -e "${RED}[-] Host unreachable.${NC}"
        read -rp "Press [Enter] to return..."
        return 1
    fi
    echo -e "${GREEN}[+] Host is reachable.${NC}"

    echo -e "\n${CYAN}[*] Fingerprinting services on $TARGET ($PORT_RANGE)...${NC}"
    echo -e "${YELLOW}[!] This may take a minute (version detection is slower).${NC}"
    echo "-------------------------------------------------"

    local LOG_FILE="./logs/fingerprint.log"
    mkdir -p "$(dirname "$LOG_FILE")"

    # Run nmap with version detection
    local nmap_output
    nmap_output=$(nmap -sV -p "$PORT_RANGE" --open -T4 "$TARGET" 2>/dev/null)

    # Display results
    echo "$nmap_output"

    # Parse and show a clean summary
    echo "-------------------------------------------------"
    echo -e "${CYAN}[*] Service Summary:${NC}"
    echo ""

    local found=0
    while IFS= read -r line; do
        if [[ "$line" =~ ^([0-9]+)/tcp[[:space:]]+open[[:space:]]+([^[:space:]]+)[[:space:]]*(.*) ]]; then
            local port="${BASH_REMATCH[1]}"
            local service="${BASH_REMATCH[2]}"
            local version="${BASH_REMATCH[3]}"
            printf "  %-8s %-20s %s\n" "$port/tcp" "$service" "$version"
            ((found++))
        fi
    done <<< "$nmap_output"

    if (( found == 0 )); then
        echo -e "  ${YELLOW}No open ports found in range $PORT_RANGE.${NC}"
    fi

    # Log
    {
        echo "=== Fingerprint at $(date '+%Y-%m-%d %H:%M:%S') ==="
        echo "Target: $TARGET | Ports: $PORT_RANGE"
        echo "$nmap_output"
        echo ""
    } >> "$LOG_FILE"

    echo ""
    echo -e "Log updated at: $LOG_FILE"
    echo "================================================="
    read -rp "Press [Enter] to return to menu..."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_fingerprinter
fi
