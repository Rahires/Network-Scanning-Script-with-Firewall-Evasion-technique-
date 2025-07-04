#!/bin/bash



# Ask for target using Zenity input box
Target=$(zenity --entry \
    --title="Nmap GUI" \
    --text="Enter the target IP or domain:")

# If user cancels or leaves blank
if [ -z "$Target" ]; then
    zenity --error --text="Target is required!"
    exit 1
fi

# Show scan type selection using Zenity radio list
ScanType=$(zenity --list --radiolist \
    --title="Select Scan Type" \
    --column="Select" --column="Option" --column="Description" \
    TRUE 1 "TCP Scan" \
    FALSE 2 "UDP Scan" \
    FALSE 3 "SYN Scan" \
    FALSE 4 "Ping Scan" \
    FALSE 5 "Firewall Evasion Scan" \
    FALSE 6 "Vulnerability Scan (NSE)" \
    --height=300 --width=500)

# If no scan type selected
if [ -z "$ScanType" ]; then
    zenity --error --text="Scan type is required!"
    exit 1
fi

# Run original script with inputs passed via stdin
OUTPUT=$(./Scan_Tool.sh <<< "$Target"$'\n'"$ScanType" 2>&1)

# Show result in a scrollable text window
zenity --text-info \
    --title="Nmap Scan Results" \
    --width=800 \
    --height=600 \
    --filename=<(echo "$OUTPUT")
