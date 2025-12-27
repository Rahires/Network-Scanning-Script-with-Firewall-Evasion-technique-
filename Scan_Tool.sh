#!/bin/bash

# Nmap Copyright and License
# Nmap (Network Mapper) - Free and Open Source Tool for Network Exploration
# Copyright (C) 1996-2025 Gordon Lyon (Fyodor)
# Nmap is licensed under the GPLv2 License (General Public License version 2).
# For more details, visit: https://nmap.org/

# Ask for target IP or domain
read -p "Enter a target: " Target

# Scan type menu
echo "Select a scan type..."
echo -e "\n1. TCP Scan"
echo -e "2. UDP Scan"
echo -e "3. SYN Scan"
echo -e "4. Ping Scan"
echo -e "5. Firewall Evasion Scan"
echo -e "6. Vulnerability Scan (Using NSE)"
read -p "Enter your choice (1-6): " scan_type

# Validate input
if ! [[ "$scan_type" =~ ^[1-6]$ ]]; then
    echo "Invalid option selected."
    exit 1
fi

# Process the selected scan type
if [ "$scan_type" -eq 1 ]; then
    echo -e "\n[+] Running TCP Scan..."
    sudo nmap -sT -v -O -sV -F "$Target"

elif [ "$scan_type" -eq 2 ]; then
    echo -e "\n[+] Running UDP Scan..."
    sudo nmap -sU -v -O -sV -T3 "$Target"

elif [ "$scan_type" -eq 3 ]; then
    echo -e "\n[+] Running SYN Scan..."
    sudo nmap -sS -v -O -sV -T3 "$Target"

elif [ "$scan_type" -eq 4 ]; then
    echo -e "\n[+] Running Ping Scan (Host Discovery Only)..."
    nmap -sn -v -T3 "$Target"

elif [ "$scan_type" -eq 5 ]; then
    echo -e "\n[+] Running Firewall Evasion Scan..."
    sudo nmap -sS -f \
        -D RND:5 \
        --source-port 53 \
        --spoof-mac 00:11:22:33:44:55 \
        --data-length 200 \
        -Pn -T2 -v "$Target"

elif [ "$scan_type" -eq 6 ]; then
    echo -e "\n[+] Running Vulnerability Scan (Using NSE)..."
    sudo nmap -sV --script vuln -p- -T3 "$Target"
fi
