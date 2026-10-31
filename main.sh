#!/usr/bin/env bash
# ==============================================================================
# LinOps Toolkit - Unified Administration & Security Operations Suite
# ==============================================================================

#set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source all modular tools
source "$SCRIPT_DIR/modules/mod_organize.sh"
source "$SCRIPT_DIR/modules/mod_password.sh"
source "$SCRIPT_DIR/modules/mod_health.sh"
source "$SCRIPT_DIR/modules/mod_diagnostics.sh"
source "$SCRIPT_DIR/modules/mod_portscan.sh"
source "$SCRIPT_DIR/modules/mod_netmap.sh"
source "$SCRIPT_DIR/modules/mod_fingerprint.sh"
source "$SCRIPT_DIR/modules/mod_vulncheck.sh"

BLUE='\033[0;34m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

display_banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    cat << "EOF"
_      _                  _______          _ _    _ _   
 | |    (_)                |__   __|        | | |  (_) |  
 | |     _ _ __  _   ___  __  | | ___   ___ | | | ___| |_ 
 | |    | | '_ \| | | \ \/ /  | |/ _ \ / _ \| | |/ / | __|
 | |____| | | | | |_| |>  <   | | (_) | (_) | |   <| | |_ 
 |______|_|_| |_|\__,_/_/\_\  |_|\___/ \___/|_|_|\_\_|\__|      Experimental.v2


  AN INTERACTIVE LINUX & SECCURITY SANDBOX       
EOF
    echo -e "${NC}"
    echo -e "${BLUE}OS: $(uname -s) $(uname -r) | Host: $(uname -n) | Date: $(date '+%Y-%m-%d')${NC}"
    echo "=================================================================="
}

main_menu() {
    while true; do
        display_banner
        echo " [1] File Organizer (Batch Categorizer)"
        echo " [2] Password Strength & Policy Checker"
        echo " [3] System Health & Metrics Monitor"
	# this is useful for checking toolkit
        echo " [4] Run Full System Diagnostics(Only useful for checking toolkit integrity)"
	echo " [5] Network Port Scanner"
	echo " [6] Network Device Mapper"
	echo " [7] Service Fingerprinter"
	echo " [8] Vulnerability Checker"
        echo " [Q] Exit Toolkit"
        echo "------------------------------------------------------------------"
        read -rp "Select an option [1-8 / Q]: " choice

        case "$choice" in
            1)
                run_file_organizer
                ;;
            2)
                run_password_checker
                ;;
            3)
                run_health_monitor
                ;;
            4)
                echo -e "\nRunning automated test sequence..."
                run_diagnostics
                ;;
	   6)
		run_network_mapper
		;;
            [qQ])
                echo -e "\nExiting LinOps Toolkit. Goodbye!"
                exit 0
                ;;
	    5)
		run_port_scanner
		;;
	    7)
		run_fingerprinter
		;;
	    8)
		run_vuln_checker
		;;
            *)
                echo -e "\nInvalid selection. Press [Enter] to try again..."
                read -r
                ;;
        esac
    done
}

main_menu
