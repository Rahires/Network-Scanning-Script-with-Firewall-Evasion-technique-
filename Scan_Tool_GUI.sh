#!/bin/bash

# ==========================================================
# Project Title : Advanced Network Scanning Tool (GUI)
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
#   - Nmap is distributed under the Nmap Public Source License
#     (based on GNU GPLv2 with additional terms).[web:42][web:47][web:49]
#   - See: https://nmap.org/misc/nmap-v7.80-license.txt
#          https://nmap.org/npsl/
#
# Shodan:
#   - Copyright (c) Shodan LLC
#   - This tool uses the Shodan REST API for IP lookups and search.
#   - Use of the Shodan API requires an API key and is subject to
#     Shodan's Terms of Service.[web:50]
#   - See: https://developer.shodan.io/api
#          https://www.shodan.io/terms
#
# ---------------------- DISCLAIMER -------------------------
#
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
# Dependency Checks
# ------------------------------
for cmd in zenity nmap curl jq; do
    if ! command -v "$cmd" &>/dev/null; then
        zenity --error --text="$cmd is required but not installed!"
        exit 1
    fi
done

# ------------------------------
# Target Validation
# ------------------------------
validate_target() {
    local t="$1"
    [[ "$t" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || \
    [[ "$t" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/([0-9]|[1-2][0-9]|3[0-2])$ ]] || \
    [[ "$t" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}-[0-9]{1,3}$ ]] || \
    [[ "$t" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]
}

# ------------------------------
# Target Input
# ------------------------------
TARGET=$(zenity --entry \
    --title="🔍 Advanced Network Scanning Tool" \
    --text="Enter Target:\n(IP / CIDR / Range / Domain)" \
    --width=420) || exit 1

[[ -z "$TARGET" ]] && exit 1

if ! validate_target "$TARGET"; then
    zenity --error --text="Invalid target format!"
    exit 1
fi

# ------------------------------
# Scan Selection
# ------------------------------
SCAN=$(zenity --list --radiolist \
    --title="⚙️ Select Scan Type" \
    --column="Select" --column="ID" --column="Scan Type" \
    TRUE 1 "TCP Scan" \
    FALSE 2 "UDP Scan" \
    FALSE 3 "SYN Scan" \
    FALSE 4 "Ping Scan" \
    FALSE 5 "Firewall Evasion Scan" \
    FALSE 6 "Vulnerability Scan (NSE)" \
    FALSE 7 "Shodan IP Intelligence" \
    FALSE 8 "Shodan Search Query" \
    --width=580 --height=420) || exit 1

[[ -z "$SCAN" ]] && exit 1

# ------------------------------
# Report Setup
# ------------------------------
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_DIR="reports"
mkdir -p "$REPORT_DIR"
REPORT="$REPORT_DIR/scan_$TIMESTAMP.txt"

# ------------------------------
# Shodan Key Input
# ------------------------------
SHODAN_API_KEY=""
if [[ "$SCAN" =~ ^(7|8)$ ]]; then
    SHODAN_API_KEY=$(zenity --password \
        --title="🔐 Shodan API Key" \
        --text="Enter your Shodan API Key:") || exit 1

    if [[ -z "$SHODAN_API_KEY" ]]; then
        zenity --error --text="Shodan API key is required!"
        exit 1
    fi
fi

# ------------------------------
# Scan Logic
# ------------------------------
case "$SCAN" in
    1) CMD="sudo nmap -sT -sV -O -F \"$TARGET\"" ;;
    2) CMD="sudo nmap -sU -sV -T3 \"$TARGET\"" ;;
    3) CMD="sudo nmap -sS -sV -T3 \"$TARGET\"" ;;
    4) CMD="nmap -sn \"$TARGET\"" ;;
    5) CMD="sudo nmap -sS -f -D RND:5 --source-port 53 -Pn \"$TARGET\"" ;;
    6) CMD="sudo nmap -sV --script vuln -p- \"$TARGET\"" ;;

    7)
        # Shodan IP Intelligence – requires single IP
        if ! [[ "$TARGET" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
            zenity --error --text="Shodan IP scan requires a single IP address (no CIDR/range/domain)."
            exit 1
        fi

        (
            echo "30"; echo "# Querying Shodan..."
            RESPONSE=$(curl -s --fail "https://api.shodan.io/shodan/host/$TARGET?key=$SHODAN_API_KEY" || echo "")

            echo "70"; echo "# Parsing results..."
            {
                echo "========== SHODAN IP INTELLIGENCE =========="
                if [[ -z "$RESPONSE" ]] || echo "$RESPONSE" | grep -q '"error"'; then
                    echo "No Shodan data available or API error."
                else
                    echo "$RESPONSE" | jq -r '
                        "IP Address   : \(.ip_str)",
                        "Organization : \(.org // \"N/A\")",
                        "ISP          : \(.isp // \"N/A\")",
                        "OS           : \(.os // \"Unknown\")",
                        "Country      : \(.country_name // \"N/A\")",
                        "Open Ports   : \(.ports | join(\", \"))"
                    '
                fi
            } > "$REPORT"

            echo "100"; echo "# Done"
        ) | zenity --progress --title="Shodan IP Intelligence" --auto-close --percentage=0
        ;;

    8)
        QUERY=$(zenity --entry \
            --title="🔎 Shodan Search" \
            --text="Enter Shodan Search Query:") || exit 1

        [[ -z "$QUERY" ]] && exit 1

        (
            echo "30"; echo "# Searching Shodan..."
            RESPONSE=$(curl -s --fail \
                "https://api.shodan.io/shodan/host/search?key=$SHODAN_API_KEY&query=$QUERY" || echo "")

            echo "70"; echo "# Parsing results..."
            {
                echo "========== SHODAN SEARCH RESULTS =========="
                if [[ -z "$RESPONSE" ]] || echo "$RESPONSE" | grep -q '"error"'; then
                    echo "No results or API error."
                else
                    echo "$RESPONSE" | jq -r '
                        .matches[]? |
                        "IP: \(.ip_str) | Port: \(.port) | Org: \(.org // \"N/A\") | Country: \(.location.country_name // \"N/A\")"
                    '
                fi
            } > "$REPORT"

            echo "100"; echo "# Done"
        ) | zenity --progress --title="Shodan Search" --auto-close --percentage=0
        ;;
esac

# ------------------------------
# Run Nmap Scans
# ------------------------------
if [[ "$SCAN" =~ ^[1-6]$ ]]; then
    (
        echo "20"; echo "# Running Nmap Scan..."
        eval "$CMD" -oN "$REPORT"
        echo "100"; echo "# Scan Complete!"
    ) | zenity --progress \
        --title="🔄 Scanning..." \
        --percentage=0 \
        --auto-close
fi

# ------------------------------
# Show Report
# ------------------------------
zenity --text-info \
    --title="📄 Scan Report" \
    --filename="$REPORT" \
    --width=900 \
    --height=600

zenity --info \
    --title="✅ Completed" \
    --text="Scan completed successfully!\n\nReport saved at:\n$REPORT"
