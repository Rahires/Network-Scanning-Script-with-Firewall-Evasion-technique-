# Network-Scanning-Script-with-Firewall-Evasion-technique-
# Nmap Scan Project

This project provides a simple Bash script to perform various Nmap network scans. The user can choose different scan types (TCP, UDP, SYN, Ping, Firewall Evasion, and Vulnerability Scanning) through an interactive prompt.

## Features
- TCP Scan (-sT)
- UDP Scan (-sU)
- SYN Scan (-sS)
- Ping Scan (-sn)
- Firewall Evasion Scan
- Vulnerability Scan using Nmap Scripting Engine (NSE)

## Prerequisites
- *Nmap* must be installed on your system.
- *sudo* privileges are required for certain scan types (e.g., SYN scan).

## Installation

1. Clone this repository:
    bash
    git clone https://github.com/Rahires/Network-Scanning-Script-with-Firewall-Evasion-technique-.git
    cd Network-Scanning-Script-with-Firewall-Evasion-technique-
    

2. Ensure Nmap is installed:
    bash
    sudo apt install nmap

3. Make the script executable:
    bash
    chmod +x Scan_Tool.sh
   chmod +x Scan_Tool_GUI.sh
    

5. Run the script:
    bash
    ./Scan_Tool_GUI.sh
    

## License
This project is licensed under the GPLv2 License (General Public License version 2).


