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
#   - https://nmap.org/book/man-legal.html [web:14]
#
# Shodan:
#   - Copyright (c) Shodan LLC
#   - This tool uses the Shodan REST API
#   - Subject to Shodan Terms of Service
#   - https://www.shodan.io/terms [web:21]
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

set -o errexit
set -o pipefail
set -o nounset

# ------------------------------
# Colors
# ------------------------------
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"

# ------------------------------
# Trap for clean exit
# ------------------------------
cleanup() {
    echo -e "\n${YELLOW}[!] Exiting...${RESET}"
}
trap cleanup INT TERM

# ------------------------------
# Spinner
# ------------------------------
spinner() {
    local pid="$1"
    local spin='|/-\'
    while kill -0 "$pid" 2>/dev/null; do
        for i in {0..3}; do
            printf "\r${YELLOW}[+] Scanning... ${spin:$i:1}${RESET}"
            sleep 0.1
        done
    done
    printf "\r${GREEN}[✓] Scan finished${RESET}\n"
}

# ------------------------------
# Check dependencies
# ------------------------------
require_cmd() {
    local cmd="$1"
    if ! command -v "$cmd" &>/dev/null; then
        echo -e "${RED}[!] Required command not found: $cmd${RESET}"
        exit 1
    fi
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
            echo -e "${RED}[!] Unsupported package manager. Install nmap manually.${RESET}"
            exit 1
        fi
    fi
    echo -e "${GREEN}[✓] Nmap is ready${RESET}"
}

# ------------------------------
# Validation Functions
# ------------------------------
validate_ip() {
    local ip="$1"
    [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || return 1

    IFS='.' read -r -a octets <<< "$ip"
    for octet in "${octets[@]}"; do
        ((octet >= 0 && octet <= 255)) || return 1
    done
    return 0
}

validate_cidr() {
    local cidr="$1"
    [[ "$cidr" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/([0-9]|[1-2][0-9]|3[0-2])$ ]] || return 1
    validate_ip "${cidr%%/*}"
}

validate_range() {
    local range="$1"
    [[ "$range" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}-[0-9]{1,3}$ ]] || return 1

    local base="${range%-*}"
    local last="${range##*-}"
    validate_ip "$base" || return 1
    ((last >= 0 && last <= 255)) || return 1
}

validate_domain() {
    local domain="$1"
    [[ "$domain" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]
}

validate_targets() {
    local input="$1"
    IFS=',' read -ra TARGETS <<< "$input"
    for target in "${TARGETS[@]}"; do
        target="$(echo "$target" | xargs)"
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
    if [[ -z "${SHODAN_API_KEY:-}" ]]; then
        read -s -p "Enter Shodan API Key (leave empty to skip Shodan): " SHODAN_API_KEY
        echo
    fi
    [[ -z "${SHODAN_API_KEY:-}" ]] && return 1
    export SHODAN_API_KEY
    return 0
}

# ------------------------------
# Shodan IP Intelligence
# ------------------------------
shodan_ip_scan() {
    local target="$1"
    local report="$2"

    if ! validate_ip "$target"; then
        echo "[!] Shodan IP scan requires a single IP address (no CIDR, range, or domain)." >> "$report"
        return
    fi

    local response
    response="$(curl -s --fail "https://api.shodan.io/shodan/host/$target?key=$SHODAN_API_KEY" || true)"

    if [[ -z "$response" ]] || echo "$response" | grep -q '"error"'; then
        echo "No Shodan data available or API error" >> "$report"
        return
    fi

    echo -e "\n========== SHODAN IP INTELLIGENCE ==========" >> "$report"
    echo "$response" | jq -r '
        "IP Address   : \(.ip_str)",
        "Organization : \(.org // \"N/A\")",
        "ISP          : \(.isp // \"N/A\")",
        "OS           : \(.os // \"Unknown\")",
        "Country      : \(.country_name // \"N/A\")",
        "Open Ports   : \(.ports | join(\", \"))"
    ' >> "$report"
}

# ------------------------------
# Shodan Search
# ------------------------------
shodan_search_scan() {
    local report="$1"
    local query

    read -p "Enter Shodan search query: " query
    [[ -z "$query" ]] && {
        echo "Empty Shodan query, skipping." >> "$report"
        return
    }

    local response
    response="$(curl -s --fail "https://api.shodan.io/shodan/host/search?key=$SHODAN_API_KEY&query=$query" || true)"

    if [[ -z "$response" ]] || echo "$response" | grep -q '"error"'; then
        echo "No results or API error" >> "$report"
        return
    fi

    echo -e "\n========== SHODAN SEARCH RESULTS ==========" >> "$report"
    echo "$response" | jq -r '
        .matches[]? |
        "IP: \(.ip_str) | Port: \(.port) | Org: \(.org // \"N/A\") | Country: \(.location.country_name // \"N/A\")"
    ' >> "$report"
}

# ------------------------------
# Menu
# ------------------------------
print_menu() {
    echo
    echo "1. TCP Scan (sT, service & OS detection, fast ports)"
    echo "2. UDP Scan (sU, service detection, slower)"
    echo "3. SYN Scan (sS, stealthy, service detection)"
    echo "4. Ping Scan (host discovery only)"
    echo "5. Firewall Evasion Scan (fragmentation, decoys, source port tricks)"
    echo "6. Vulnerability Scan (vuln scripts, all ports)"
    echo "7. Shodan IP Intelligence (single IP)"
    echo "8. Shodan Search (query-based)"
}

# ------------------------------
# Program Start
# ------------------------------
clear
echo -e "${BLUE}=============================================="
echo "      ADVANCED NETWORK SCANNING TOOL"
echo "      Secure Nmap + Optional Shodan"
echo "==============================================${RESET}"

# Check required tools
check_nmap
require_cmd curl
require_cmd jq

# Targets
read -p "Enter target(s) (IP / CIDR / Range / Domain, comma-separated): " TARGET
if ! validate_targets "$TARGET"; then
    echo -e "${RED}[!] Invalid target(s) provided${RESET}"
    exit 1
fi

print_menu
read -p "Select scan (1-8): " SCAN

if [[ ! "$SCAN" =~ ^[1-8]$ ]]; then
    echo -e "${RED}[!] Invalid option${RESET}"
    exit 1
fi

# ------------------------------
# Report Setup
# ------------------------------
TIMESTAMP="$(date +"%Y%m%d_%H%M%S")"
REPORT_DIR="reports"
mkdir -p "$REPORT_DIR"
REPORT="$REPORT_DIR/scan_$TIMESTAMP.txt"

# ------------------------------
# Scan Execution
# ------------------------------
CMD=""

case "$SCAN" in
    1)
        CMD="sudo nmap -sT -sV -O -F $TARGET"
        ;;
    2)
        CMD="sudo nmap -sU -sV -T3 $TARGET"
        ;;
    3)
        CMD="sudo nmap -sS -sV -T3 $TARGET"
        ;;
    4)
        CMD="nmap -sn $TARGET"
        ;;
    5)
        CMD="sudo nmap -sS -f -D RND:5 --source-port 53 -Pn $TARGET"
        ;;
    6)
        CMD="sudo nmap -sV --script vuln -p- $TARGET"
        ;;
    7)
        if get_shodan_key; then
            shodan_ip_scan "$TARGET" "$REPORT"
            echo -e "${GREEN}=============================================="
            echo "[✓] Shodan IP Intelligence Completed"
            echo "Report saved at: $REPORT"
            echo "==============================================${RESET}"
        else
            echo "[!] Shodan skipped (no API key)"
        fi
        exit 0
        ;;
    8)
        if get_shodan_key; then
            shodan_search_scan "$REPORT"
            echo -e "${GREEN}=============================================="
            echo "[✓] Shodan Search Completed"
            echo "Report saved at: $REPORT"
            echo "==============================================${RESET}"
        else
            echo "[!] Shodan skipped (no API key)"
        fi
        exit 0
        ;;
esac

if [[ "$SCAN" =~ ^[1-6]$ ]]; then
    echo -e "${YELLOW}[+] Running: $CMD${RESET}"
    # Run scan in background, attach spinner
    bash -c "$CMD -oN \"$REPORT\"" &
    cmd_pid=$!
    spinner "$cmd_pid"
fi

# ------------------------------
# Completion
# ------------------------------
echo -e "${GREEN}=============================================="
echo "[✓] Scan Completed Successfully"
echo "Report saved at: $REPORT"
echo "==============================================${RESET}"
