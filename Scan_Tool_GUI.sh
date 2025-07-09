#!/bin/bash

# Ask for target using Zenity input box
Target=$(zenity --entry \
    --title="🔍 Scan Tool GUI" \
    --text="Enter the target IP address or domain:" \
    --width=400)

# If user cancels or leaves blank
if [ -z "$Target" ]; then
    zenity --error --title="❌ Error" --text="Target is required!"
    exit 1
fi

# Show scan type selection
ScanType=$(zenity --list --radiolist \
    --title="⚙️ Select Scan Type" \
    --column="Select" --column="Option" --column="Description" \
    TRUE 1 "TCP Scan" \
    FALSE 2 "UDP Scan" \
    FALSE 3 "SYN Scan" \
    FALSE 4 "Ping Scan" \
    FALSE 5 "Firewall Evasion Scan" \
    FALSE 6 "Vulnerability Scan (NSE)" \
    --height=350 --width=550)

# If no scan type selected
if [ -z "$ScanType" ]; then
    zenity --error --title="❌ Error" --text="Scan type is required!"
    exit 1
fi

# Confirm scan
zenity --question \
    --title="🛡️ Confirm Scan" \
    --text="Proceed with scanning:\n\nTarget: $Target\nScan Type: $ScanType?" \
    --width=400

if [ $? -ne 0 ]; then
    zenity --info --title="Cancelled" --text="Scan cancelled by user."
    exit 0
fi

# Check if Scan_Tool.sh is executable
if [ ! -x ./Scan_Tool.sh ]; then
    zenity --error --title="❌ Script Error" --text="Scan_Tool.sh not found or not executable!"
    exit 1
fi

# Create temporary output file
TempOutput=$(mktemp)

# Show progress bar while scan runs
(
    echo "10"; echo "# Preparing scan..."
    sleep 1

    echo "30"; echo "# Running scan..."
    OUTPUT=$(./Scan_Tool.sh <<EOF
$Target
$ScanType
EOF
)

    # Format output into structured report
    {
        echo "===== Scan Report ====="
        echo "Target       : $Target"
        echo "Scan Type    : $ScanType"
        echo "Scan Time    : $(date)"
        echo ""
        echo "===== Results ====="
        echo "$OUTPUT"
        echo ""
        echo "===== End of Report ====="
    } > "$TempOutput"

    echo "80"; echo "# Finalizing..."
    sleep 1
    echo "100"; echo "# Scan Complete!"
) | zenity --progress \
    --title="🔄 Scanning in Progress" \
    --text="Starting scan..." \
    --percentage=0 \
    --auto-close \
    --width=500

# If scan failed or cancelled
if [ $? -ne 0 ]; then
    zenity --error --title="❌ Interrupted" --text="The scan was interrupted or failed."
    rm -f "$TempOutput"
    exit 1
fi

# Display formatted results
zenity --text-info \
    --title="📄 Scan Report" \
    --filename="$TempOutput" \
    --width=800 \
    --height=600 \
    --ok-label="Done"

# Ask user if they want to save the report
zenity --question \
    --title="💾 Save Report?" \
    --text="Would you like to save this scan report?" \
    --width=400

if [ $? -eq 0 ]; then
    SavePath=$(zenity --file-selection --save --confirm-overwrite \
        --title="Save Scan Report" \
        --filename="scan-report-$(date +%Y%m%d-%H%M%S).txt")

    if [ -n "$SavePath" ]; then
        cp "$TempOutput" "$SavePath"
        zenity --info --title="✅ Saved" --text="Report saved to:\n$SavePath"
    fi
fi

# Clean up
rm -f "$TempOutput"
