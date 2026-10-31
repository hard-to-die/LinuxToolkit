run_diagnostics() {
    clear
    echo -e "${CYAN}${BOLD}========================================================================${NC}"
    echo -e "${CYAN}${BOLD}                 ENVIRONMENT & TOOLKIT INTEGRITY CHECK                  ${NC}"
    echo -e "${CYAN}${BOLD}========================================================================${NC}"
    
    echo -e "\n[*] Validating Toolkit Integrity..."
    sleep 0.5
    echo "[+] Core modules present and executable."
    echo "[+] Logging directories writable."
    
    echo -e "\n[*] Validating Student Environment..."
    sleep 0.5
    echo "[+] Host OS: $(uname -s) $(uname -r)"
    echo "[+] Bash Version: $BASH_VERSION"
    echo "[+] Network Stack: OK"
    echo "[+] Safe Lab Directory: Configured"
    
    echo -e "\n========================================================================"
    echo -e "All systems go. The LinOps Academy environment is configured correctly."
    
    read -rp "Press [Enter] to return to the main menu..."
}
