run_network_info() {
    clear
    echo "================================================="
    echo "          MODULE: Network Information            "
    echo "================================================="

    echo -e "\n${CYAN}[*] Local IP:${NC}"
    ip -4 addr show | grep inet | grep -v 127.0.0.1 | awk '{print "    " $2}'

    echo -e "\n${CYAN}[*] Gateway:${NC}"
    ip route | grep default | awk '{print "    " $3}'

    echo -e "\n${CYAN}[*] DNS:${NC}"
    grep nameserver /etc/resolv.conf | awk '{print "    " $2}'

    echo -e "\n${CYAN}[*] Public IP:${NC}"
    echo "    $(curl -s ifconfig.me 2>/dev/null || echo 'Unavailable')"

    echo "================================================="
    read -rp "Press [Enter] to return to menu..."
}
