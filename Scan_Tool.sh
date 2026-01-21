#!/bin/bash

# ==========================================================
# Project Title : Advanced Network Scanning Tool
# Degree        : B.Sc Final Year Project
# Author        : Sahebrao Rahire
# Year          : 2026
# ==========================================================
#
# ---------------------- LICENSE NOTICE ---------------------
#
# Copyright (c) 2026 Sahebrao Rahire
#
# This project is released under the GNU General Public
# License v2.0 (GPLv2).
#
# You are free to use, modify, and distribute this software
# under the terms of the GNU GPL v2 or later.
#
# This software is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
# PURPOSE.
#
# Full license text:
# https://www.gnu.org/licenses/old-licenses/gpl-2.0.html
#
# ---------------------- THIRD-PARTY ------------------------
#
# Nmap:
#   - Copyright (c) Gordon "Fyodor" Lyon
#   - Licensed under GNU GPL v2
#   - https://nmap.org/book/man-legal.html
#
# Shodan:
#   - Copyright (c) Shodan LLC
#   - This tool uses the Shodan REST API
#   - Subject to Shodan Terms of Service
#   - https://www.shodan.io/terms
#
# ---------------------- DISCLAIMER -------------------------
#
# DISCLAIMER:
# This tool is developed strictly for educational,
# research, and authorized security testing purposes.
#
# Unauthorized scanning of networks or systems that you do
# not own or have explicit permission to test is illegal
# and unethical.
#
# The author is NOT responsible for any misuse, damage,
# or legal consequences resulting from the use of this tool.
#
# Users are solely responsible for ensuring compliance with
# applicable laws, regulations, and organizational policies.
#
# By using this tool, you agree that you understand and
# accept these terms.
#
# ==========================================================

# ------------------------------
# Colors
# ------------------------------
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"

# ------------------------------
# Spinner
# ------------------------------
spinner() {
    local pid=$!
    local spin='|/-\'
    while ps -p $pid &>/dev/null; do
        for i in {0..3}; do
            printf "\r${YELLOW}[+] Scanning... ${spin:$i:1}${RESET}"
            sleep 0.1
        done
    done
    printf "\r${GREEN}[✓] Scan finished${RESET}\n"
}

# ------------------------------
# Auto Install Nmap
# ------------------------------
check_nmap() {
    if ! command -v nmap &>/dev/null; then
        echo -e "${YELLOW}[!] Nmap not found. Installing...${RESET}"

        if command -v apt &>/dev/null; then
            sudo apt update && sudo apt install -y nmap
        elif command -v yum &>/dev/null; then
            sudo yum install -y nmap
        elif command -v dnf &>/dev/null; then
            sudo dnf install -y nmap
        elif command -v pacman &>/dev/null; then
            sudo pacman -Sy nmap --noconfirm
        else
            echo -e "${RED}[!] Unsupported package manager${RESET}"
            exit 1
        fi
    fi
    echo -e "${GREEN}[✓] Nmap is ready${RESET}"
}

# ------------------------------
# Validation Functions
# ------------------------------
validate_ip() {
    [[ $1 =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]
}

validate_cidr() {
    [[ $1 =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/([0-9]|[1-2][0-9]|3[0-2])$ ]]
}

validate_range() {
    [[ $1 =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}-[0-9]{1,3}$ ]]
}

validate_domain() {
    [[ $1 =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]
}

validate_targets() {
    IFS=',' read -ra TARGETS <<< "$1"
    for target in "${TARGETS[@]}"; do
        target=$(echo "$target" | xargs)
        validate_ip "$target" \
        || validate_cidr "$target" \
        || validate_range "$target" \
        || validate_domain "$target" \
        || return 1
    done
    return 0
}

# ------------------------------
# Secure Shodan Key Logic
# ------------------------------
get_shodan_key() {
    if [[ -z "$SHODAN_API_KEY" ]]; then
        read -s -p "Enter Shodan API Key (leave empty to skip Shodan): " SHODAN_API_KEY
        echo
    fi
    [[ -z "$SHODAN_API_KEY" ]] && return 1
    return 0
}

# ------------------------------
# Shodan IP Intelligence
# ------------------------------
shodan_ip_scan() {
    local target="$1"
    local report="$2"

    validate_ip "$target" || {
        echo "[!] Shodan IP scan requires a single IP address" >> "$report"
        return
    }

    response=$(curl -s "https://api.shodan.io/shodan/host/$target?key=$SHODAN_API_KEY")

    if echo "$response" | grep -q '"error"'; then
        echo "No Shodan data available" >> "$report"
        return
    fi

    echo -e "\n========== SHODAN IP INTELLIGENCE ==========" >> "$report"
    echo "$response" | jq -r '
        "IP Address   : \(.ip_str)",
        "Organization : \(.org // "N/A")",
        "ISP          : \(.isp // "N/A")",
        "OS           : \(.os // "Unknown")",
        "Country      : \(.country_name // "N/A")",
        "Open Ports   : \(.ports | join(", "))"
    ' >> "$report"
}

# ------------------------------
# Shodan Search
# ------------------------------
shodan_search_scan() {
    local report="$1"
    read -p "Enter Shodan search query: " query

    response=$(curl -s "https://api.shodan.io/shodan/host/search?key=$SHODAN_API_KEY&query=$query")

    if echo "$response" | grep -q '"error"'; then
        echo "No results or API error" >> "$report"
        return
    fi

    echo -e "\n========== SHODAN SEARCH RESULTS ==========" >> "$report"
    echo "$response" | jq -r '
        .matches[] |
        "IP: \(.ip_str) | Port: \(.port) | Org: \(.org // "N/A") | Country: \(.location.country_name // "N/A")"
    ' >> "$report"
}

# ------------------------------
# Program Start
# ------------------------------
clear
echo -e "${BLUE}=============================================="
echo "      ADVANCED NETWORK SCANNING TOOL"
echo "      Secure Nmap + Optional Shodan"
echo "==============================================${RESET}"

check_nmap

read -p "Enter target(s) (IP / CIDR / Range / Domain, comma-separated): " TARGET
validate_targets "$TARGET" || {
    echo -e "${RED}[!] Invalid target(s) provided${RESET}"
    exit 1
}

echo
echo "1. TCP Scan"
echo "2. UDP Scan"
echo "3. SYN Scan"
echo "4. Ping Scan"
echo "5. Firewall Evasion Scan"
echo "6. Vulnerability Scan"
echo "7. Shodan IP Intelligence (Optional)"
echo "8. Shodan Search (Optional)"
read -p "Select scan (1-8): " SCAN

[[ ! "$SCAN" =~ ^[1-8]$ ]] && {
    echo -e "${RED}[!] Invalid option${RESET}"
    exit 1
}

# ------------------------------
# Report Setup
# ------------------------------
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_DIR="reports"
mkdir -p "$REPORT_DIR"
REPORT="$REPORT_DIR/scan_$TIMESTAMP.txt"

# ------------------------------
# Scan Execution
# ------------------------------
case $SCAN in
    1) CMD="sudo nmap -sT -sV -O -F $TARGET" ;;
    2) CMD="sudo nmap -sU -sV -T3 $TARGET" ;;
    3) CMD="sudo nmap -sS -sV -T3 $TARGET" ;;
    4) CMD="nmap -sn $TARGET" ;;
    5) CMD="sudo nmap -sS -f -D RND:5 --source-port 53 -Pn $TARGET" ;;
    6) CMD="sudo nmap -sV --script vuln -p- $TARGET" ;;
    7)
        get_shodan_key || { echo "[!] Shodan skipped (no API key)"; exit 0; }
        shodan_ip_scan "$TARGET" "$REPORT"
        ;;
    8)
        get_shodan_key || { echo "[!] Shodan skipped (no API key)"; exit 0; }
        shodan_search_scan "$REPORT"
        ;;
esac

if [[ "$SCAN" =~ ^[1-6]$ ]]; then
    ($CMD -oN "$REPORT") & spinner
fi

# ------------------------------
# Completion
# ------------------------------
echo -e "${GREEN}=============================================="
echo "[✓] Scan Completed Successfully"
echo "Report saved at: $REPORT"
echo "==============================================${RESET}"
