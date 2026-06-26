#!/bin/bash
# ==========================================================
# Project Title : Advanced Network Scanning Tool (CLI)
# Degree        : B.Sc Final Year Project
# Author        : Sahebrao Rahire
# Year          : 2026
# License       : GNU GPL v2
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
#   - Subject to Shodan Terms of Service
#   - https://www.shodan.io/terms
#
# ---------------------- DISCLAIMER -------------------------
#
# This tool is for educational, research, and authorized
# security testing purposes ONLY.
#
# Unauthorized scanning is illegal and unethical.
# The author is NOT responsible for any misuse.
#
# ==========================================================

# FIX 1: Removed 'set -o errexit' — it fatally conflicts with:
#         - validate functions that return 1 (treated as crash)
#         - arithmetic ((octet <= 255)) returning 1 = false
#         - || return 1 patterns inside loops
#         Using explicit if/then checks throughout instead.
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
    exit 0
}
trap cleanup INT TERM

# ------------------------------
# Spinner
# FIX 2: Original used 'for i in {0..3}' with spin:$i:1
#         This works in bash but 'spin' indexing needs to be
#         safe under nounset. Rewrote to use index variable
#         and modulo so it never goes out of bounds.
# ------------------------------
spinner() {
    local pid="$1"
    local spin='|/-\'
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r${YELLOW}[+] Scanning... ${spin:$i:1}${RESET}"
        sleep 0.1
        i=$(( (i + 1) % 4 ))
    done
    printf "\r${GREEN}[✓] Scan finished          ${RESET}\n"
}

# ------------------------------
# Check dependencies
# ------------------------------
require_cmd() {
    local cmd="$1"
    if ! command -v "$cmd" &>/dev/null; then
        echo -e "${RED}[!] Required command not found: $cmd${RESET}"
        echo -e "${YELLOW}    Install with: sudo apt-get install -y $cmd${RESET}"
        exit 1
    fi
}

# ------------------------------
# Auto Install Nmap
# ------------------------------
check_nmap() {
    if ! command -v nmap &>/dev/null; then
        echo -e "${YELLOW}[!] Nmap not found. Installing...${RESET}"
        if command -v apt-get &>/dev/null; then
            sudo apt-get update -qq && sudo apt-get install -y nmap
        elif command -v apt &>/dev/null; then
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
# FIX 3: All validate_* functions previously used
#         '|| return 1' and '((arithmetic))' which both
#         trigger set -o errexit as fatal errors.
#         Now wrapped in explicit if blocks — safe without errexit.
# ------------------------------
validate_ip() {
    local ip="$1"
    if ! [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        return 1
    fi
    # FIX 4: Arithmetic check wrapped in if — avoids errexit trap
    local IFS='.'
    local octet
    for octet in $ip; do
        if [ "$octet" -lt 0 ] || [ "$octet" -gt 255 ]; then
            return 1
        fi
    done
    return 0
}

validate_cidr() {
    local cidr="$1"
    if ! [[ "$cidr" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/([0-9]|[1-2][0-9]|3[0-2])$ ]]; then
        return 1
    fi
    validate_ip "${cidr%%/*}"
}

validate_range() {
    local range="$1"
    if ! [[ "$range" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}-[0-9]{1,3}$ ]]; then
        return 1
    fi
    local base="${range%-*}"
    local last="${range##*-}"
    if ! validate_ip "$base"; then
        return 1
    fi
    if [ "$last" -lt 0 ] || [ "$last" -gt 255 ]; then
        return 1
    fi
    return 0
}

validate_domain() {
    local domain="$1"
    [[ "$domain" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]
}

# FIX 5: validate_targets previously used 'IFS=',' read -r -a TARGETS'
#         (bash array) with errexit active — any return 1 from inner
#         validate call would kill the whole script silently.
#         Rewrote using a while+read loop with explicit checks.
validate_targets() {
    local input="$1"
    local old_IFS="$IFS"
    IFS=','
    local valid=0
    local target
    for target in $input; do
        # trim whitespace
        target="${target#"${target%%[![:space:]]*}"}"
        target="${target%"${target##*[![:space:]]}"}"
        if validate_ip "$target" \
        || validate_cidr "$target" \
        || validate_range "$target" \
        || validate_domain "$target"; then
            valid=1
        else
            IFS="$old_IFS"
            return 1
        fi
    done
    IFS="$old_IFS"
    [ "$valid" -eq 1 ] && return 0 || return 1
}

# ------------------------------
# Secure Shodan Key Logic
# ------------------------------
get_shodan_key() {
    if [[ -z "${SHODAN_API_KEY:-}" ]]; then
        read -r -s -p "Enter Shodan API Key (leave empty to skip): " SHODAN_API_KEY
        echo
    fi
    if [[ -z "${SHODAN_API_KEY:-}" ]]; then
        return 1
    fi
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
        echo "[!] Shodan IP scan requires a single IP (no CIDR, range, or domain)." >> "$report"
        return
    fi

    local response
    response="$(curl -s --fail \
        "https://api.shodan.io/shodan/host/$target?key=$SHODAN_API_KEY" || true)"

    {
        echo "========== SHODAN IP INTELLIGENCE =========="
        if [[ -z "$response" ]] || echo "$response" | grep -q '"error"'; then
            echo "No Shodan data available or API error."
        else
            echo "$response" | jq -r '
                "IP Address   : \(.ip_str)",
                "Organization : \(.org // "N/A")",
                "ISP          : \(.isp // "N/A")",
                "OS           : \(.os // "Unknown")",
                "Country      : \(.country_name // "N/A")",
                "Open Ports   : \(.ports | join(", "))"
            '
        fi
    } >> "$report"
}

# ------------------------------
# Shodan Search
# ------------------------------
shodan_search_scan() {
    local report="$1"
    local query=""

    read -r -p "Enter Shodan search query: " query
    if [[ -z "$query" ]]; then
        echo "Empty Shodan query, skipping." >> "$report"
        return
    fi

    local encoded_query
    encoded_query=$(python3 -c \
        "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" \
        "$query" 2>/dev/null || echo "$query")

    local response
    response="$(curl -s --fail \
        "https://api.shodan.io/shodan/host/search?key=$SHODAN_API_KEY&query=$encoded_query" \
        || true)"

    {
        echo "========== SHODAN SEARCH RESULTS =========="
        if [[ -z "$response" ]] || echo "$response" | grep -q '"error"'; then
            echo "No results or API error."
        else
            echo "$response" | jq -r '
                .matches[]? |
                "IP: \(.ip_str) | Port: \(.port) | Org: \(.org // "N/A") | Country: \(.location.country_name // "N/A")"
            '
        fi
    } >> "$report"
}

# ------------------------------
# Menu
# ------------------------------
print_menu() {
    echo
    echo -e "${BLUE}  Select Scan Type:${RESET}"
    echo "  1. TCP Scan        — sT, service & OS detection, fast ports"
    echo "  2. UDP Scan        — sU, service detection (slower)"
    echo "  3. SYN Scan        — sS, stealthy, service detection"
    echo "  4. Ping Scan       — host discovery only"
    echo "  5. Firewall Evasion — fragmentation, decoys, source port"
    echo "  6. Vuln Scan       — NSE vuln scripts, all ports"
    echo "  7. Shodan IP       — intelligence on a single IP"
    echo "  8. Shodan Search   — query-based search"
    echo
}

# ==============================
# Program Start
# ==============================
clear
echo -e "${BLUE}"
echo "  ╔════════════════════════════════════════╗"
echo "  ║    ADVANCED NETWORK SCANNING TOOL      ║"
echo "  ║    Nmap + Optional Shodan Integration  ║"
echo "  ║    Author : Sahebrao Rahire            ║"
echo "  ╚════════════════════════════════════════╝"
echo -e "${RESET}"

# Check required tools
check_nmap
require_cmd curl
require_cmd jq

echo

# Target input
read -r -p "Enter target(s) — IP / CIDR / Range / Domain (comma-separated): " TARGET

if [[ -z "$TARGET" ]]; then
    echo -e "${RED}[!] No target entered${RESET}"
    exit 1
fi

if ! validate_targets "$TARGET"; then
    echo -e "${RED}[!] Invalid target(s): $TARGET${RESET}"
    echo -e "${YELLOW}    Examples: 192.168.1.1 | 192.168.1.0/24 | 192.168.1.1-50 | example.com${RESET}"
    exit 1
fi

echo -e "${GREEN}[✓] Target accepted: $TARGET${RESET}"

print_menu
read -r -p "Select scan (1-8): " SCAN

if ! [[ "$SCAN" =~ ^[1-8]$ ]]; then
    echo -e "${RED}[!] Invalid option. Choose 1–8.${RESET}"
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
    1) CMD="sudo nmap -sT -sV -O -F $TARGET" ;;
    2) CMD="sudo nmap -sU -sV -T3 $TARGET" ;;
    3) CMD="sudo nmap -sS -sV -T3 $TARGET" ;;
    4) CMD="nmap -sn $TARGET" ;;
    5) CMD="sudo nmap -sS -f -D RND:5 --source-port 53 -Pn $TARGET" ;;
    6) CMD="sudo nmap -sV --script vuln -p- $TARGET" ;;

    7)
        if get_shodan_key; then
            echo -e "${YELLOW}[+] Running Shodan IP Intelligence...${RESET}"
            shodan_ip_scan "$TARGET" "$REPORT"
            echo -e "${GREEN}"
            echo "  ╔════════════════════════════════════════╗"
            echo "  ║  Shodan IP Intelligence Complete       ║"
            echo "  ║  Report: $REPORT"
            echo "  ╚════════════════════════════════════════╝"
            echo -e "${RESET}"
        else
            echo -e "${YELLOW}[!] Shodan skipped — no API key provided${RESET}"
        fi
        exit 0
        ;;

    8)
        if get_shodan_key; then
            echo -e "${YELLOW}[+] Running Shodan Search...${RESET}"
            shodan_search_scan "$REPORT"
            echo -e "${GREEN}"
            echo "  ╔════════════════════════════════════════╗"
            echo "  ║  Shodan Search Complete                ║"
            echo "  ║  Report: $REPORT"
            echo "  ╚════════════════════════════════════════╝"
            echo -e "${RESET}"
        else
            echo -e "${YELLOW}[!] Shodan skipped — no API key provided${RESET}"
        fi
        exit 0
        ;;
esac

# ------------------------------
# Run Nmap (options 1–6)
# FIX 6: Original ran nmap in background with spinner but
#         the output file '-oN $REPORT' wasn't guaranteed to
#         complete before spinner ended. Now wait explicitly.
# ------------------------------
if [[ "$SCAN" =~ ^[1-6]$ ]]; then
    echo -e "${YELLOW}[+] Running: $CMD${RESET}"
    echo

    # Run in background and capture PID for spinner
    bash -c "$CMD -oN \"$REPORT\"" &
    cmd_pid=$!
    spinner "$cmd_pid"

    # FIX 7: Wait for background job and capture its exit code
    if wait "$cmd_pid"; then
        echo -e "${GREEN}[✓] Nmap completed successfully${RESET}"
    else
        echo -e "${YELLOW}[!] Nmap exited with errors (partial results may exist)${RESET}"
    fi
fi

# ------------------------------
# Completion
# ------------------------------
echo -e "${GREEN}"
echo "  ╔════════════════════════════════════════╗"
echo "  ║  Scan Completed Successfully           ║"
echo "  ║  Report: $REPORT"
echo "  ╚════════════════════════════════════════╝"
echo -e "${RESET}"
