# 🚀 Network Scanning Script with Firewall Evasion Techniques

Welcome to this powerful **Bash-based Nmap scanning tool** that offers multiple scanning options with stealth and vulnerability detection features — all through an interactive menu!

---

## ✨ Features

| Scan Type                   | Description                                                  |
|-----------------------------|--------------------------------------------------------------|
| 🔹 **TCP Scan** (`-sT`)        | Basic TCP connect scan (no root required)                   |
| 🔹 **UDP Scan** (`-sU`)        | UDP port scan (requires `sudo`)                             |
| 🔹 **SYN Scan** (`-sS`)        | Stealth SYN scan (requires `sudo`)                          |
| 🔹 **Ping Scan** (`-sn`)       | Host discovery ping sweep                                   |
| 🔹 **Firewall Evasion Scan**  | Uses fragmentation, source port spoofing & MAC spoofing    |
| 🔹 **Vulnerability Scan**     | Runs Nmap Scripting Engine (NSE) vuln scripts on all ports |

---

## 📋 Prerequisites

- **Nmap** must be installed on your system  
- **sudo** privileges are required for UDP, SYN, firewall evasion, and vuln scans  
- Tested on Linux (Debian/Ubuntu recommended)

---

## ⚙️ Installation & Usage

### 1. Clone the repository

```bash
git clone https://github.com/Rahires/Network-Scanning-Script-with-Firewall-Evasion-technique-.git
cd Network-Scanning-Script-with-Firewall-Evasion-technique-

2. Install Nmap
sudo apt update

sudo apt install nmap
3. Make scripts executable
chmod +x Scan_Tool.sh
chmod +x Scan_Tool_GUI.sh

4. Run the GUI version for interactive scanning
./Scan_Tool_GUI.sh

🛡️ License
This project is licensed under the GPLv2 License (General Public License version 2).
Read more: GNU GPLv2

⚠️ Disclaimer
Warning: Always have explicit permission before scanning any networks or systems.
Unauthorized scanning is illegal and unethical. Use this tool responsibly.

🙌 Contributing
Feel free to open issues or submit pull requests to improve this tool.
Your feedback and contributions are highly appreciated!

📬 Contact
Created by Sahebrao Shivaji Rahire
GitHub: https://github.com/Rahires

Happy scanning! 🔍🚀



2## 📱 How to Install and Run on Mobile (Android)

You can run this network scanning tool on your Android phone using **Termux**, a powerful terminal emulator and Linux environment.

### Step 1: Install Termux

- Go to the Google Play Store or [F-Droid](https://f-droid.org/en/packages/com.termux/) and install **Termux**.

### Step 2: Update packages in Termux

Open Termux and run:
pkg update && pkg upgrade

Step 3: Install required packages
pkg install git
pkg install nmap
pkg install bash
Note: Some scans (like SYN scan) may not work fully without root access on mobile devices.

Step 4: Clone the repository
git clone https://github.com/Rahires/Network-Scanning-Script-with-Firewall-Evasion-technique-.git
cd Network-Scanning-Script-with-Firewall-Evasion-technique-

Step 5: Make the script executable
chmod +x Scan_Tool.sh
chmod +x Scan_Tool_GUI.sh

Step 6: Run the script
./Scan_Tool_GUI.sh

## 💻 How to Run on Windows

This tool is written in Bash and relies on **Nmap**, so here’s how to set it up on Windows 

---
 ### Running on Windows

#### Option 1: Using Windows Subsystem for Linux (WSL)

1. **Install WSL:**

- Open PowerShell as Administrator and run:

  ```powershell
  wsl --install
Restart your computer if prompted.

Open WSL Terminal:

Launch the Ubuntu (or your chosen Linux distro) app from the Start menu.

Install required packages inside WSL:
sudo apt update
sudo apt install git nmap bash

Clone your repository and run the script:
git clone https://github.com/Rahires/Network-Scanning-Script-with-Firewall-Evasion-technique-.git
cd Network-Scanning-Script-with-Firewall-Evasion-technique-
chmod +x Scan_Tool.sh Scan_Tool_GUI.sh
./Scan_Tool_GUI.sh

Running on macOS
Open Terminal.

Install Homebrew (if not already installed):
/bin/bash -c "$(curl -fsS https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
Install Nmap and Git:
brew install nmap git

Clone the repository and run the script:
git clone https://github.com/Rahires/Network-Scanning-Script-with-Firewall-Evasion-technique-.git
cd Network-Scanning-Script-with-Firewall-Evasion-technique-
chmod +x Scan_Tool.sh Scan_Tool_GUI.sh
./Scan_Tool_GUI.sh
