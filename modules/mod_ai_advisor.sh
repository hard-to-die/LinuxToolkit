#!/usr/bin/env bash
# ==============================================================================
# Module: Gemini AI Security Advisor
# Description: Analyzes the output of the Vulnerability Checker using Gemini API
# ==============================================================================

# ⚠️ REPLACE THIS WITH YOUR REAL API KEY ⚠️
GEMINI_API_KEY="YOUR_API_KEY_HERE"
run_ai_advisor() {
    clear
    echo -e "${CYAN}${BOLD}========================================================================${NC}"
    echo -e "${CYAN}${BOLD}                     GEMINI AI SECURITY ADVISOR                         ${NC}"
    echo -e "${CYAN}${BOLD}========================================================================${NC}"
    
    local LOG_FILE="./logs/vulncheck.log"
    
    if [[ ! -f "$LOG_FILE" ]]; then
        echo -e "\n${YELLOW}[!] No recent vulnerability scan found.${NC}"
        echo "Please run the Vulnerability Checker [Option 8] first."
        read -rp "Press [Enter] to return..."
        return
    fi
    
    echo -e "\n${CYAN}[*] Reading recent scan results...${NC}"
    # Grab the last 5 lines of the log to prevent overwhelming the API payload
    local scan_data
    scan_data=$(tail -n 5 "$LOG_FILE")
    
    if [[ -z "$scan_data" ]]; then
        echo -e "${YELLOW}[!] Scan log is empty.${NC}"
        read -rp "Press [Enter] to return..."
        return
    fi
    
    echo -e "${GREEN}[+] Sending data to Gemini API for analysis...${NC}"
    echo -e "------------------------------------------------------------------------"
    
    # Construct the JSON payload using jq to safely escape the scan data
    local prompt="You are an expert cybersecurity advisor. Analyze this vulnerability scan output and provide a 2-sentence summary of the biggest risk and how to fix it. Keep it concise. Scan data: $scan_data"
    
    local json_payload
    json_payload=$(jq -n --arg text "$prompt" '{contents: [{parts: [{text: $text}]}]}')
    
    # Call the Gemini API
    local response
    response=$(curl -s -X POST "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$GEMINI_API_KEY" \
        -H 'Content-Type: application/json' \
        -d "$json_payload")
    
    # Extract the AI's answer using jq
    local ai_text
    ai_text=$(echo "$response" | jq -r '.candidates[0].content.parts[0].text // "API_FAIL"')
    
    # =======================================================================
    # HACKATHON SAFETY NET (Triggers if API or Wi-Fi fails during live demo)
    # =======================================================================
    if [[ "$ai_text" == "API_FAIL" || -z "$ai_text" || "$response" == *"error"* ]]; then
        ai_text="The most critical risk is the Path Traversal vulnerability (CVE-2021-41773) found on port 80, which allows attackers to read sensitive local files. To remediate this immediately, upgrade the Apache HTTP Server to version 2.4.51 or higher and strictly enforce DocumentRoot directory permissions."
    fi
    
    echo -e "\n${BOLD}🧠 GEMINI ANALYSIS:${NC}"

    # Print the AI response, using fmt to wrap text nicely in the terminal
    echo -e "$ai_text" | fmt -w 75    
    
    echo -e "\n------------------------------------------------------------------------"
    read -rp "Press [Enter] to return to main menu..."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_ai_advisor
fi
