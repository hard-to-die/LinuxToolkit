#!/usr/bin/env bash

# Fallback colors (used when run standalone)
RED="${RED:-\033[0;31m}"
GREEN="${GREEN:-\033[0;32m}"
YELLOW="${YELLOW:-\033[1;33m}"
BLUE="${BLUE:-\033[0;34m}"
CYAN="${CYAN:-\033[0;36m}"
BOLD="${BOLD:-\033[1m}"
NC="${NC:-\033[0m}"

run_vuln_checker() {
    clear
    echo "================================================="
    echo "       MODULE: Vulnerability Checker             "
    echo "================================================="

    # Locate the offline CVE database
    local CVE_DB="${SCRIPT_DIR:-.}/config/cve_db.tsv"

    # If the database file is missing, stop and tell the user
    if [[ ! -f "$CVE_DB" ]]; then
        echo -e "${RED}[-] CVE database not found: $CVE_DB${NC}"
        echo -e "${YELLOW}[!] Create it or run from the toolkit root.${NC}"
        read -rp "Press [Enter] to return..."
        return 1
    fi

    # Detect local IP (or use the one passed as argument)
    local LOCAL_IP
    LOCAL_IP="${1:-$(ip -4 addr show | grep inet | grep -v 127.0.0.1 | awk '{print $2}' | cut -d/ -f1 | head -1)}"

    # Ask for target IP (default = local IP)
    read -rp "Enter target IP [Default: $LOCAL_IP]: " TARGET
    TARGET="${TARGET:-$LOCAL_IP}"

    # Ask for port range (default = 1-1024)
    read -rp "Enter ports to check [Default: 1-1024]: " PORT_RANGE
    PORT_RANGE="${PORT_RANGE:-1-1024}"

    # nmap is required for fingerprinting
    if ! command -v nmap &>/dev/null; then
        echo -e "${RED}[-] nmap is not installed.${NC}"
        read -rp "Press [Enter] to return..."
        return 1
    fi

    # Make sure the target is reachable before scanning
    echo -e "\n${CYAN}[*] Testing connectivity to $TARGET...${NC}"
    if ! ping -c 1 -W 2 "$TARGET" &>/dev/null; then
        echo -e "${RED}[-] Host unreachable.${NC}"
        read -rp "Press [Enter] to return..."
        return 1
    fi
    echo -e "${GREEN}[+] Host is reachable.${NC}"

    # Run nmap with version detection to identify services
    echo -e "\n${CYAN}[*] Fingerprinting services on $TARGET ($PORT_RANGE)...${NC}"
    echo -e "${YELLOW}[!] This may take a minute.${NC}"
    echo "-------------------------------------------------"

    local nmap_output
    nmap_output=$(nmap -sV -p "$PORT_RANGE" --open -T4 "$TARGET" 2>/dev/null)

    # If nmap returned nothing, the target didn't respond
    if [[ -z "$nmap_output" ]]; then
        echo -e "${RED}[-] No response from $TARGET.${NC}"
        read -rp "Press [Enter] to return..."
        return 1
    fi

    # Prepare the log file
    local LOG_FILE="./logs/vulncheck.log"
    mkdir -p "$(dirname "$LOG_FILE")"

    local found=0
    local risky=0

    echo -e "\n${BOLD}VULNERABILITY REPORT (Offline Database)${NC}"
    echo "================================================="

    # Parse each nmap line that shows an open port + service + version
    while IFS= read -r line; do
        if [[ "$line" =~ ^([0-9]+)/tcp[[:space:]]+open[[:space:]]+([^[:space:]]+)[[:space:]]*(.*) ]]; then
            local port="${BASH_REMATCH[1]}"
            local service="${BASH_REMATCH[2],,}"   # lowercase service name
            local version="${BASH_REMATCH[3]}"
            ((found++))

            local status="${GREEN}[INFO]${NC}"
            local reason="No known CVEs in local database"
            local cve_matches=()

            # Look up the service + version in the offline CVE database
            while IFS=$'\t' read -r db_service db_version cve_id severity score desc; do
                [[ "$db_service" =~ ^# ]] && continue
                [[ -z "$db_service" ]] && continue

                # Match if the whole nmap line contains the service name AND version pattern
                if [[ "$line" =~ "$db_service" ]] && [[ "$line" =~ $db_version ]]; then
                    cve_matches+=("$cve_id|$severity|$score|$desc")
                fi
            done < "$CVE_DB"

            # If any CVEs matched, pick the highest severity
            if [[ ${#cve_matches[@]} -gt 0 ]]; then
                local highest_sev="Low"
                local highest_score=0

                for match in "${cve_matches[@]}"; do
                    local rest="${match#*|}"
                    local sev="${rest%%|*}"
                    rest="${rest#*|}"
                    local sc="${rest%%|*}"
                    # Compare scores using awk (handles floats without bc)
                    if awk "BEGIN {exit !($sc > $highest_score)}"; then
                        highest_score="$sc"
                        highest_sev="$sev"
                    fi
                done

                # Choose color based on highest severity
                case "$highest_sev" in
                    Critical) status="${RED}[CRITICAL]${NC}" ;;
                    High)     status="${RED}[HIGH]${NC}" ;;
                    Medium)   status="${YELLOW}[MEDIUM]${NC}" ;;
                    Low)      status="${YELLOW}[LOW]${NC}" ;;
                esac

                reason="${#cve_matches[@]} CVE(s) found (max severity: $highest_sev, score: $highest_score)"
                ((risky++))
            else
                # No CVE match — fall back to simple port-based warnings
                case "$port" in
                    21) status="${RED}[RISK]${NC}"; reason="FTP — unencrypted" ;;
                    23) status="${RED}[RISK]${NC}"; reason="Telnet — unencrypted" ;;
                    80) status="${YELLOW}[WARN]${NC}"; reason="HTTP — unencrypted" ;;
                    445) status="${RED}[RISK]${NC}"; reason="SMB — check MS17-010" ;;
                    3306) status="${RED}[RISK]${NC}"; reason="MySQL — check credentials" ;;
                    3389) status="${YELLOW}[WARN]${NC}"; reason="RDP — exposed" ;;
                    5900) status="${RED}[RISK]${NC}"; reason="VNC — often unauthenticated" ;;
                esac
            fi

            # Print the port, service, status, and reason (using %b so colors render)
            printf "%-8s %-20s " "$port/tcp" "$service"
            printf "%b" "$status"
            printf " %s\n" "$reason"

            # Print the detected version
            printf "         Version: %s\n" "$version"

            # Print each matching CVE
            for match in "${cve_matches[@]}"; do
                local cve="${match%%|*}"
                local rest="${match#*|}"
                local sev="${rest%%|*}"
                rest="${rest#*|}"
                local sc="${rest%%|*}"
                local desc="${rest#*|}"
                printf "           - %s (%s, %.1f): %s\n" "$cve" "$sev" "$sc" "$desc"
            done

            # Log everything to the file
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] $port/tcp $service $version | $status $reason" >> "$LOG_FILE"
            for match in "${cve_matches[@]}"; do
                echo "  CVE: $match" >> "$LOG_FILE"
            done
        fi
    done <<< "$nmap_output"

    echo "-------------------------------------------------"

    # Summary
    if (( found == 0 )); then
        echo -e "${GREEN}[+] No open ports found in range $PORT_RANGE.${NC}"
    else
        echo -e "Total services: ${BOLD}${CYAN}$found${NC}"
        echo -e "Risky/vulnerable: ${BOLD}${RED}$risky${NC}"
    fi

    echo ""
    echo -e "Log updated at: $LOG_FILE"
    echo "================================================="
    read -rp "Press [Enter] to return to menu..."
}

# If executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_vuln_checker
fi
