#!/bin/bash

# Ask for target using Zenity input box
Target=$(zenity --entry \
    --title="🔍 Scan Tool GUI" \
    --text="Enter the target IP address or domain:" \
    --width=400)

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

# Check if Scan_Tool.sh exists and is executable
if [ ! -x ./Scan_Tool.sh ]; then
    zenity --question --title="❌ Script Error" --text="Scan_Tool.sh is not executable. Attempt to fix?"
    if [ $? -eq 0 ]; then
        chmod +x ./Scan_Tool.sh || zenity --error --text="Could not make it executable."
    else
        exit 1
    fi
fi

# Format target for filename (e.g., scanme.nmap.org -> scanme_nmap_org)
CleanTarget=$(echo "$Target" | sed 's/[^a-zA-Z0-9]/_/g')
Timestamp=$(date +%Y%m%d_%H%M%S)
FinalReport="scan_output_${CleanTarget}_${Timestamp}.txt"
TempOutput=$(mktemp)

(
    echo "10"; echo "# Preparing scan..."
    sleep 1
    echo "30"; echo "# Running scan..."

    # Run scan and format output
    OUTPUT=$(./Scan_Tool.sh <<EOF
$Target
$ScanType
EOF
)

    {
        echo "[+] Running scan on $Target..."
        case "$ScanType" in
            1) echo "[+] TCP Scan (fast)";;
            2) echo "[+] UDP Scan";;
            3) echo "[+] SYN Scan";;
            4) echo "[+] Ping Scan";;
            5) echo "[+] Firewall Evasion Scan";;
            6) echo "[+] Vulnerability Scan (NSE)";;
        esac

        echo ""
        echo "$OUTPUT"
        echo ""
        echo "Scan report saved to: $FinalReport"
        echo "✔ Scan complete. Output saved to: $FinalReport"
    } > "$FinalReport"

    cp "$FinalReport" "$TempOutput"

    echo "90"; echo "# Finalizing..."
    sleep 1
    echo "100"; echo "# Scan Complete!"
) | zenity --progress \
    --title="🔄 Scanning in Progress" \
    --text="Starting scan..." \
    --percentage=0 \
    --auto-close \
    --width=500

if [ $? -ne 0 ]; then
    zenity --error --title="❌ Interrupted" --text="The scan was interrupted or failed."
    rm -f "$TempOutput"
    exit 1
fi

zenity --text-info \
    --title="📄 Scan Report" \
    --filename="$TempOutput" \
    --width=800 \
    --height=600 \
    --ok-label="Done"

zenity --question \
    --title="💾 Save Report?" \
    --text="Would you like to save this scan report?" \
    --width=400

if [ $? -eq 0 ]; then
    SavePath=$(zenity --file-selection --save --confirm-overwrite \
        --title="Save Scan Report" \
        --filename="$FinalReport")

    if [ -n "$SavePath" ]; then
        cp "$FinalReport" "$SavePath"
        zenity --info --title="✅ Saved" --text="Report saved to:\n$SavePath"
    fi
fi

rm -f "$TempOutput"
