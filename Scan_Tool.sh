#!/bin/bash

# ==========================================================
# Project Title : Network Scanning Tool
# Degree        : B.Sc Final Year Project
# Author        : Sahebrao Rahire
# Description   : Real-time Nmap scanning with validation,
#                 auto-installation, reporting, colors,
#                 and progress visualization.
# ==========================================================
#
# Copyright (c) 2026 Sahebrao Rahire
#
# This project makes use of Nmap (https://nmap.org/).
# Nmap is licensed under the GNU General Public License v2 (GPLv2).
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
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
# Spinner (Progress Indicator)
# ------------------------------
spinner() {
    local pid=$!
    local delay=0.1
    local spinstr='|/-\'
    while ps -p $pid &>/dev/null; do
        for i in {0..3}; do
            printf "\r${YELLOW}[+] Scanning... ${spinstr:$i:1}${RESET}"
            sleep $delay
        done
    done
    printf "\r${GREEN}[✓] Scan finished${RESET}\n"
}

# ------------------------------
# Check & Install Nmap
# ------------------------------
check_nmap() {
    if ! command -v nmap &>/dev/null; then
        echo -e "${RED}[!] Nmap not found.${RESET}"
        read -p "Install Nmap now? (y/n): " choice
        [[ ! "$choice" =~ ^[Yy]$ ]] && exit 1

        echo -e "${BLUE}[+] Installing Nmap...${RESET}"
        if command -v apt &>/dev/null; then
            sudo apt update && sudo apt install -y nmap
        elif command -v yum &>/dev/null; then
            sudo yum install -y nmap
        elif command -v dnf &>/dev/null; then
            sudo dnf install -y nmap
        elif command -v pacman &>/dev/null; then
            sudo pacman -Sy nmap --noconfirm
        else
            echo -e "${RED}[!] Unsupported package manager.${RESET}"
            exit 1
        fi
    fi
    echo -e "${GREEN}[✓] Nmap ready${RESET}"
}

# ------------------------------
# Validation Functions
# ------------------------------
validate_ip() { [[ $1 =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; }
validate_cidr() { [[ $1 =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/([0-9]|[1-2][0-9]|3[0-2])$ ]]; }
validate_range() { [[ $1 =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}-[0-9]{1,3}$ ]]; }
validate_domain() { [[ $1 =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; }

validate_targets() {
    IFS=',' read -ra T <<< "$1"
    for t in "${T[@]}"; do
        validate_ip "$t" || validate_cidr "$t" || validate_range "$t" || validate_domain "$t" || return 1
    done
}

# ------------------------------
# Start Program
# ------------------------------
clear
echo -e "${BLUE}=============================================="
echo "      ADVANCED NETWORK SCANNING TOOL"
echo "==============================================${RESET}"

check_nmap

read -p "Enter target(s): " TARGET
validate_targets "$TARGET" || { echo -e "${RED}[!] Invalid target${RESET}"; exit 1; }

echo
echo "1. TCP Scan"
echo "2. UDP Scan"
echo "3. SYN Scan"
echo "4. Ping Scan"
echo "5. Firewall Evasion Scan"
echo "6. Vulnerability Scan"
read -p "Select scan (1-6): " SCAN

[[ ! "$SCAN" =~ ^[1-6]$ ]] && { echo -e "${RED}[!] Invalid option${RESET}"; exit 1; }

# ------------------------------
# Report Setup
# ------------------------------
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_DIR="reports"
mkdir -p "$REPORT_DIR"

TXT="$REPORT_DIR/scan_$TIMESTAMP.txt"
XML="$REPORT_DIR/scan_$TIMESTAMP.xml"
HTML="$REPORT_DIR/scan_$TIMESTAMP.html"

# ------------------------------
# Scan Execution
# ------------------------------
echo -e "${YELLOW}[+] Scan started on $TARGET${RESET}"

case $SCAN in
    1) CMD="sudo nmap -sT -sV -O -F $TARGET" ;;
    2) CMD="sudo nmap -sU -sV -T3 $TARGET" ;;
    3) CMD="sudo nmap -sS -sV -T3 $TARGET" ;;
    4) CMD="nmap -sn $TARGET" ;;
    5) CMD="sudo nmap -sS -f -D RND:5 --source-port 53 -Pn $TARGET" ;;
    6) CMD="sudo nmap -sV --script vuln -p- $TARGET" ;;
esac

($CMD -oN "$TXT" -oX "$XML") & spinner

# ------------------------------
# HTML Report
# ------------------------------
if command -v xsltproc &>/dev/null; then
    xsltproc "$XML" -o "$HTML"
    echo -e "${GREEN}[✓] HTML report generated${RESET}"
else
    echo -e "${YELLOW}[!] xsltproc not found (HTML skipped)${RESET}"
fi

# ------------------------------
# Completion
# ------------------------------
echo -e "${GREEN}=============================================="
echo "[✓] Scan Completed Successfully"
echo "Reports saved in: $REPORT_DIR"
echo "TXT : $TXT"
echo "XML : $XML"
echo "HTML: $HTML"
echo "==============================================${RESET}"
