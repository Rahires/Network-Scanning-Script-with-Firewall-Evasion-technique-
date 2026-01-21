#!/bin/bash

# ==========================================================
# Project Title : Advanced Network Scanning Tool (GUI)
# Degree        : B.Sc Final Year Project
# Author        : Sahebrao Rahire
# Year          : 2026
# License       : GNU GPL v2
# ==========================================================
#
# DISCLAIMER:
# This tool is for EDUCATIONAL and AUTHORIZED use only.
# Unauthorized scanning is illegal.
# ==========================================================

# ------------------------------
# Dependency Checks
# ------------------------------
for cmd in zenity nmap curl jq; do
    if ! command -v $cmd &>/dev/null; then
        zenity --error --text="$cmd is required but not installed!"
        exit 1
    fi
done

# ------------------------------
# Target Validation
# ------------------------------
validate_target() {
    [[ $1 =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || \
    [[ $1 =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/([0-9]|[1-2][0-9]|3[0-2])$ ]] || \
    [[ $1 =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}-[0-9]{1,3}$ ]] || \
    [[ $1 =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]
}

# ------------------------------
# Target Input
# ------------------------------
TARGET=$(zenity --entry \
    --title="🔍 Advanced Network Scanning Tool" \
    --text="Enter Target:\n(IP / CIDR / Range / Domain)" \
    --width=420)

[[ -z "$TARGET" ]] && exit 1

validate_target "$TARGET" || {
    zenity --error --text="Invalid target format!"
    exit 1
}

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
    --width=580 --height=420)

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
if [[ "$SCAN" =~ ^(7|8)$ ]]; then
    SHODAN_API_KEY=$(zenity --password \
        --title="🔐 Shodan API Key" \
        --text="Enter your Shodan API Key:")

    [[ -z "$SHODAN_API_KEY" ]] && {
        zenity --error --text="Shodan API key is required!"
        exit 1
    }
fi

# ------------------------------
# Scan Logic
# ------------------------------
case $SCAN in
    1) CMD="sudo nmap -sT -sV -O -F $TARGET" ;;
    2) CMD="sudo nmap -sU -sV -T3 $TARGET" ;;
    3) CMD="sudo nmap -sS -sV -T3 $TARGET" ;;
    4) CMD="nmap -sn $TARGET" ;;
    5) CMD="sudo nmap -sS -f -D RND:5 --source-port 53 -Pn $TARGET" ;;
    6) CMD="sudo nmap -sV --script vuln -p- $TARGET" ;;

    7)
        validate_target "$TARGET" || {
            zenity --error --text="Shodan IP scan requires a single IP!"
            exit 1
        }

        (
            echo "30"; echo "# Querying Shodan..."
            RESPONSE=$(curl -s "https://api.shodan.io/shodan/host/$TARGET?key=$SHODAN_API_KEY")

            echo "70"; echo "# Parsing results..."
            {
                echo "========== SHODAN IP INTELLIGENCE =========="
                echo "$RESPONSE" | jq -r '
                    "IP Address   : \(.ip_str)",
                    "Organization : \(.org // "N/A")",
                    "ISP          : \(.isp // "N/A")",
                    "OS           : \(.os // "Unknown")",
                    "Country      : \(.country_name // "N/A")",
                    "Open Ports   : \(.ports | join(", "))"
                '
            } > "$REPORT"

            echo "100"; echo "# Done"
        ) | zenity --progress --title="Shodan IP Intelligence" --auto-close
        ;;

    8)
        QUERY=$(zenity --entry \
            --title="🔎 Shodan Search" \
            --text="Enter Shodan Search Query:")

        [[ -z "$QUERY" ]] && exit 1

        (
            echo "30"; echo "# Searching Shodan..."
            RESPONSE=$(curl -s \
                "https://api.shodan.io/shodan/host/search?key=$SHODAN_API_KEY&query=$QUERY")

            echo "70"; echo "# Parsing results..."
            {
                echo "========== SHODAN SEARCH RESULTS =========="
                echo "$RESPONSE" | jq -r '
                    .matches[] |
                    "IP: \(.ip_str) | Port: \(.port) | Org: \(.org // "N/A") | Country: \(.location.country_name // "N/A")"
                '
            } > "$REPORT"

            echo "100"; echo "# Done"
        ) | zenity --progress --title="Shodan Search" --auto-close
        ;;
esac

# ------------------------------
# Run Nmap Scans
# ------------------------------
if [[ "$SCAN" =~ ^[1-6]$ ]]; then
    (
        echo "20"; echo "# Running Nmap Scan..."
        $CMD -oN "$REPORT"
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
