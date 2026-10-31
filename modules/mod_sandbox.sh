#!/usr/bin/env bash
# ==============================================================================
# Module: Educational Sandbox
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

run_sandbox() {
    clear
    echo -e "${CYAN}${BOLD}========================================================================${NC}"
    echo -e "${CYAN}${BOLD}                      LINOPS ACADEMY: SANDBOX MODE                      ${NC}"
    echo -e "${CYAN}${BOLD}========================================================================${NC}"
    
    LAB_DIR="$HOME/LinOps_Lab"
    echo -e "\n[*] Setting up safe student environment at $LAB_DIR..."
    
    mkdir -p "$LAB_DIR"
    rm -f "$LAB_DIR"/* 2>/dev/null # Clean previous runs
    
    # Create dummy files
    for i in {1..9}; do
        touch "$LAB_DIR/dummy_file_$i.log"
        chmod $(( (RANDOM % 7) + 1 ))$(( (RANDOM % 7) + 1 ))$(( (RANDOM % 7) + 1 )) "$LAB_DIR/dummy_file_$i.log"
    done
    
    # Create secret file with specific permissions
    touch "$LAB_DIR/secret.txt"
    chmod 740 "$LAB_DIR/secret.txt"
    
    echo "[+] Lab environment provisioned successfully."
    echo -e "\n${BOLD}Welcome to the Sandbox.${NC} I have created a file called ${BLUE}secret.txt${NC} in ~/LinOps_Lab."
    echo "Use a second terminal window to find its permissions and type them below."
    
    while true; do
        read -rp "Enter the octal permissions for secret.txt (e.g., 777) or 'q' to quit: " ans
        if [[ "$ans" == "740" ]]; then
            echo -e "\n[+] Correct! 740 means Owner can read/write/execute, Group can read, Others have no access."
            break
        elif [[ "${ans,,}" == "q" ]]; then
            break
        else
            echo "[-] Incorrect. Try using 'ls -l ~/LinOps_Lab' or 'stat ~/LinOps_Lab/secret.txt'."
        fi
    done
    
    echo -e "------------------------------------------------------------------------"
    read -rp "Press [Enter] to return to the main menu..."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_sandbox
fi
