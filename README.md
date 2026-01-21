Advanced Network Scanning Tool (GUI)

Welcome to the Advanced Network Scanning Tool, a Bash‑based GUI application built using Nmap, Zenity, and Shodan API.
This tool provides multiple network scanning techniques, firewall evasion methods, and vulnerability detection, all through an interactive graphical interface.

This project is developed as a B.Sc Final Year Project (2026) for educational and authorized security testing purposes.

Features
🔍 Nmap Scanning Options
Scan Type	Description
🔹 TCP Scan (-sT)	Standard TCP connect scan
🔹 UDP Scan (-sU)	UDP port scan (requires sudo)
🔹 SYN Scan (-sS)	Stealth SYN scan (requires sudo)
🔹 Ping Scan (-sn)	Host discovery / ping sweep
🔹 Firewall Evasion Scan	Fragmentation, decoys & source‑port spoofing
🔹 Vulnerability Scan	NSE vulnerability scripts on all ports

Shodan Intelligence (Optional)

🔹 Shodan IP Intelligence

🔹 Shodan Search Queries

🔐 Secure API key input via GUI

🖥️ GUI Capabilities

Zenity‑based interactive windows

Input validation (IP / CIDR / Range / Domain)

Progress bar during scans

Automatic report generation

Timestamp‑based scan logs

Prerequisites

Linux‑based OS (Ubuntu, Kali, Debian, Fedora, Arch)

Nmap

Zenity

curl

jq

sudo privileges (for advanced scans)

Optional: Shodan API Key

Installation & Usage (Linux)
1️⃣ Clone the Repository

git clone https://github.com/Rahires/Advanced-Network-Scanning-Tool.git
cd Advanced-Network-Scanning-Tool

2️⃣ Install Required Packages
sudo apt update
sudo apt install nmap zenity curl jq -y

3️⃣ Make Script Executable
chmod +x Advanced_Scan_GUI.sh


4️⃣ Run the Tool
./Advanced_Scan_GUI.sh


⚠️ Some scan types require sudo/root privileges


Scan Reports

All scan results are saved automatically in:

reports/scan_YYYYMMDD_HHMMSS.txt


Reports include:

Target details

Scan type

Nmap or Shodan output

Timestamp

License

This project is licensed under the GNU General Public License v2.0 (GPL‑2.0).

🔗 https://www.gnu.org/licenses/old-licenses/gpl-2.0.html

⚠️ Disclaimer

WARNING:
This tool is intended only for educational, research, and authorized penetration testing.

Scanning networks or systems without explicit permission is illegal and unethical.

The author is not responsible for misuse, damage, or legal consequences arising from the use of this tool.

👉❤💕Contributing

Contributions are welcome!

Open issues

Submit pull requests

Suggest improvements







