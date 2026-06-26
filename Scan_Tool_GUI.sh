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
# Full license text:
# https://www.gnu.org/licenses/old-licenses/gpl-2.0.html
#
# ---------------------- THIRD-PARTY ------------------------
#
# Nmap:
#   - Copyright (c) Gordon "Fyodor" Lyon
#   - Licensed under Nmap Public Source License (GPLv2-based)
#   - See: https://nmap.org/npsl/
#
# Shodan:
#   - Copyright (c) Shodan LLC
#   - Requires a Shodan API key
#   - See: https://www.shodan.io/terms
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

# FIX 1: Removed 'set -o errexit' — it conflicts with zenity
#         cancel actions (non-zero exit) and validate functions
#         returning 1. Using explicit checks instead.
set -o pipefail
set -o nounset

# ------------------------------
# Dependency Checks
# FIX 2: Check zenity first separately — if zenity missing,
#         we can't show GUI errors, so fall back to echo
# ------------------------------
if ! command -v zenity &>/dev/null; then
    echo "[!] zenity is not installed. Run: sudo apt-get install -y zenity"
    exit 1
fi

for cmd in nmap curl jq; do
    if ! command -v "$cmd" &>/dev/null; then
        zenity --error --title="Missing Dependency" \
               --text="Required tool not found: $cmd\n\nRun:\n  sudo apt-get install -y $cmd"
        exit 1
    fi
done

# ------------------------------
# Target Validation
# FIX 3: Wrapped in subshell so 'return 1' never triggers
#         outer pipefail/nounset unexpectedly
# ------------------------------
validate_target() {
    local t="$1"
    [[ "$t" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]                              && return 0
    [[ "$t" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/([0-9]|[1-2][0-9]|3[0-2])$ ]]   && return 0
    [[ "$t" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}-[0-9]{1,3}$ ]]                   && return 0
    [[ "$t" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]                              && return 0
    return 1
}

# ------------------------------
# Target Input
# ------------------------------
TARGET=$(zenity --entry \
    --title="Advanced Network Scanning Tool" \
    --text="Enter Target:\n(IP / CIDR / Range / Domain)" \
    --width=420) || exit 0   # FIX 4: exit 0 on cancel — not an error

[[ -z "$TARGET" ]] && exit 0

if ! validate_target "$TARGET"; then
    zenity --error --title="Invalid Target" \
           --text="Invalid target format!\n\nExamples:\n  192.168.1.1\n  192.168.1.0/24\n  192.168.1.1-50\n  example.com"
    exit 1
fi

# ------------------------------
# Scan Selection
# ------------------------------
SCAN=$(zenity --list --radiolist \
    --title="Select Scan Type" \
    --column="Select" --column="ID" --column="Scan Type" \
    TRUE  1 "TCP Scan" \
    FALSE 2 "UDP Scan" \
    FALSE 3 "SYN Scan" \
    FALSE 4 "Ping Scan" \
    FALSE 5 "Firewall Evasion Scan" \
    FALSE 6 "Vulnerability Scan (NSE)" \
    FALSE 7 "Shodan IP Intelligence" \
    FALSE 8 "Shodan Search Query" \
    --width=580 --height=420) || exit 0   # FIX 5: exit 0 on cancel

[[ -z "$SCAN" ]] && exit 0

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
        --title="Shodan API Key" \
        --text="Enter your Shodan API Key:") || exit 0

    if [[ -z "$SHODAN_API_KEY" ]]; then
        zenity --error --title="API Key Required" \
               --text="Shodan API key is required for this scan type."
        exit 1
    fi
fi

# ------------------------------
# Scan Logic
# FIX 6: Removed quotes inside CMD string — they were being
#         passed literally to nmap. Target is validated above
#         so no injection risk. Quotes go on the eval call.
# ------------------------------
case "$SCAN" in
    1) CMD="sudo nmap -sT -sV -O -F $TARGET" ;;
    2) CMD="sudo nmap -sU -sV -T3 $TARGET" ;;
    3) CMD="sudo nmap -sS -sV -T3 $TARGET" ;;
    4) CMD="nmap -sn $TARGET" ;;
    5) CMD="sudo nmap -sS -f -D RND:5 --source-port 53 -Pn $TARGET" ;;
    6) CMD="sudo nmap -sV --script vuln -p- $TARGET" ;;

    7)
        # Shodan IP Intelligence — single IP only
        if ! [[ "$TARGET" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
            zenity --error --title="Invalid Target" \
                   --text="Shodan IP scan requires a single IP address.\nNo CIDR, range, or domain."
            exit 1
        fi

        (
            echo "30"; echo "# Querying Shodan..."
            RESPONSE=$(curl -s --fail \
                "https://api.shodan.io/shodan/host/$TARGET?key=$SHODAN_API_KEY" || echo "")

            echo "70"; echo "# Parsing results..."
            {
                echo "========== SHODAN IP INTELLIGENCE =========="
                if [[ -z "$RESPONSE" ]] || echo "$RESPONSE" | grep -q '"error"'; then
                    echo "No Shodan data available or API error."
                else
                    echo "$RESPONSE" | jq -r '
                        "IP Address   : \(.ip_str)",
                        "Organization : \(.org // "N/A")",
                        "ISP          : \(.isp // "N/A")",
                        "OS           : \(.os // "Unknown")",
                        "Country      : \(.country_name // "N/A")",
                        "Open Ports   : \(.ports | join(", "))"
                    '
                fi
            } > "$REPORT"

            echo "100"; echo "# Done"
        ) | zenity --progress --title="Shodan IP Intelligence" \
                   --auto-close --percentage=0 --width=400
        ;;

    8)
        QUERY=$(zenity --entry \
            --title="Shodan Search" \
            --text="Enter Shodan Search Query:" \
            --width=420) || exit 0

        [[ -z "$QUERY" ]] && exit 0

        (
            echo "30"; echo "# Searching Shodan..."
            RESPONSE=$(curl -s --fail \
                "https://api.shodan.io/shodan/host/search?key=$SHODAN_API_KEY&query=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$QUERY")" || echo "")

            echo "70"; echo "# Parsing results..."
            {
                echo "========== SHODAN SEARCH RESULTS =========="
                if [[ -z "$RESPONSE" ]] || echo "$RESPONSE" | grep -q '"error"'; then
                    echo "No results or API error."
                else
                    echo "$RESPONSE" | jq -r '
                        .matches[]? |
                        "IP: \(.ip_str) | Port: \(.port) | Org: \(.org // "N/A") | Country: \(.location.country_name // "N/A")"
                    '
                fi
            } > "$REPORT"

            echo "100"; echo "# Done"
        ) | zenity --progress --title="Shodan Search" \
                   --auto-close --percentage=0 --width=400
        ;;
esac

# ------------------------------
# Run Nmap Scans (options 1-6)
# FIX 7: Added error handling for nmap failure — previously
#         a failed scan would silently produce an empty report
# ------------------------------
if [[ "$SCAN" =~ ^[1-6]$ ]]; then
    (
        echo "10"; echo "# Starting scan on $TARGET..."
        echo "20"; echo "# Running: $CMD"

        # FIX 8: Capture nmap exit code without triggering pipefail
        if eval "$CMD" -oN "$REPORT" 2>&1; then
            echo "100"; echo "# Scan Complete!"
        else
            echo "100"; echo "# Scan finished (some errors may have occurred)"
        fi
    ) | zenity --progress \
        --title="Scanning $TARGET..." \
        --percentage=0 \
        --auto-close \
        --width=400
fi

# ------------------------------
# Show Report
# FIX 9: Added check — if report is empty or missing,
#         show a warning instead of blank text-info window
# ------------------------------
if [[ ! -f "$REPORT" ]] || [[ ! -s "$REPORT" ]]; then
    zenity --warning --title="Empty Report" \
           --text="Scan completed but the report is empty.\nThe target may be unreachable."
    exit 0
fi

zenity --text-info \
    --title="Scan Report — $TARGET" \
    --filename="$REPORT" \
    --width=900 \
    --height=600

zenity --info \
    --title="Completed" \
    --text="Scan completed!\n\nReport saved at:\n$(pwd)/$REPORT"
