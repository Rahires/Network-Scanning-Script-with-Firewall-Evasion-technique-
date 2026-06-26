# Advanced Network Scanning Tool

> B.Sc Final Year Project — Sahebrao Rahire (2026)  
> Licensed under GNU GPL v2

A powerful Bash-based network scanning toolkit built on top of **Nmap** and **Shodan**.  
Comes in two versions — a terminal CLI tool and a graphical GUI tool — both designed for  
educational use, authorized penetration testing, and network security research.

---

## Scripts

| File | Type | Description |
|---|---|---|
| `Scan_Tool.sh` | CLI | Terminal-based scanner, works on any Kali setup |
| `Scan_Tool_GUI.sh` | GUI | Graphical interface using Zenity pop-up dialogs |

---

## Features

- TCP, UDP, SYN, and Ping scanning via Nmap
- Firewall Evasion scanning (packet fragmentation, decoys, source port spoofing)
- Vulnerability scanning using Nmap NSE scripts
- Shodan IP Intelligence — enriched data on any public IP
- Shodan Search — query-based threat intelligence
- Auto-installs missing dependencies (Nmap)
- Input validation for IP, CIDR, IP range, and domain targets
- Supports comma-separated multiple targets
- Auto-saves scan reports with timestamps to a `reports/` folder
- Spinner animation during scans (CLI)
- Color-coded terminal output (CLI)
- Clean Ctrl+C exit handling

---

## Requirements

| Tool | Purpose | Install |
|---|---|---|
| `nmap` | Core scanning engine | `sudo apt-get install -y nmap` |
| `curl` | Shodan API requests | `sudo apt-get install -y curl` |
| `jq` | Parse Shodan JSON responses | `sudo apt-get install -y jq` |
| `python3` | URL-encode Shodan queries | Pre-installed on Kali |
| `zenity` | GUI dialogs (GUI version only) | `sudo apt-get install -y zenity` |
| `bash` | Script interpreter | Pre-installed on Kali |

---

## Installation

### Step 1 — Update your system

```bash
sudo apt-get update && sudo apt-get upgrade -y
```

### Step 2 — Install all dependencies

```bash
sudo apt-get install -y nmap curl jq zenity python3
```

### Step 3 — Clone the repository

```bash
git clone https://github.com/Rahires/Network-Scanning-Script-with-Firewall-Evasion-technique-.git
cd Network-Scanning-Script-with-Firewall-Evasion-technique-
```

### Step 4 — Make scripts executable

```bash
chmod +x Scan_Tool.sh
chmod +x Scan_Tool_GUI.sh
```

---

## Usage

### CLI Version (Recommended)

Works on any Kali setup including headless/terminal-only environments.

```bash
sudo ./Scan_Tool.sh
```

Follow the on-screen prompts:

```
Enter target(s) — IP / CIDR / Range / Domain (comma-separated): 192.168.1.1

  Select Scan Type:
  1. TCP Scan        — sT, service & OS detection, fast ports
  2. UDP Scan        — sU, service detection (slower)
  3. SYN Scan        — sS, stealthy, service detection
  4. Ping Scan       — host discovery only
  5. Firewall Evasion — fragmentation, decoys, source port
  6. Vuln Scan       — NSE vuln scripts, all ports
  7. Shodan IP       — intelligence on a single IP
  8. Shodan Search   — query-based search

Select scan (1-8): 1
```

---

### GUI Version

Requires a desktop environment (GNOME / XFCE). Kali with a desktop installed.

```bash
sudo ./Scan_Tool_GUI.sh
```

A series of graphical pop-up windows will guide you through:
1. Enter your target
2. Select your scan type
3. Enter Shodan API key (if using options 7 or 8)
4. Watch the progress bar
5. View the report in a pop-up window

---

## Supported Target Formats

| Format | Example |
|---|---|
| Single IP | `192.168.1.1` |
| CIDR range | `192.168.1.0/24` |
| IP range | `192.168.1.1-50` |
| Domain name | `example.com` |
| Multiple targets | `192.168.1.1, 10.0.0.1, example.com` |

---

## Scan Types Explained

### 1. TCP Scan (`-sT`)
Performs a full TCP connect scan with service and OS detection on fast/common ports.  
Most reliable. Easiest to detect. Good general-purpose starting point.

```bash
# Equivalent nmap command
sudo nmap -sT -sV -O -F <target>
```

### 2. UDP Scan (`-sU`)
Scans UDP ports with service detection. Slower than TCP but finds services  
like DNS (53), SNMP (161), and DHCP (67) that TCP misses.

```bash
sudo nmap -sU -sV -T3 <target>
```

### 3. SYN Scan (`-sS`)
Sends SYN packets only — never completes the TCP handshake.  
Stealthier than TCP scan. Requires root. Industry standard for pen testing.

```bash
sudo nmap -sS -sV -T3 <target>
```

### 4. Ping Scan (`-sn`)
Host discovery only. Checks which hosts are alive without scanning ports.  
Fast. Useful for mapping large networks before deeper scanning.

```bash
nmap -sn <target>
```

### 5. Firewall Evasion Scan
Combines multiple evasion techniques to bypass basic firewalls and IDS:
- `-f` — fragments packets into smaller pieces
- `-D RND:5` — uses 5 random decoy IPs to confuse logging
- `--source-port 53` — spoofs source as DNS port (often allowed through firewalls)
- `-Pn` — skips ping, assumes host is up

```bash
sudo nmap -sS -f -D RND:5 --source-port 53 -Pn <target>
```

### 6. Vulnerability Scan (`--script vuln`)
Runs Nmap's built-in NSE vulnerability scripts against all 65535 ports.  
Checks for known CVEs, misconfigurations, and exploitable services.  
Slowest scan — can take a long time on large targets.

```bash
sudo nmap -sV --script vuln -p- <target>
```

### 7. Shodan IP Intelligence
Queries the Shodan API for enriched threat intelligence on a single public IP.  
Returns: organization, ISP, OS, country, and open ports seen by Shodan crawlers.  
Requires a free or paid Shodan API key.

### 8. Shodan Search
Runs a free-text search against the Shodan database.  
Example queries: `apache country:IN`, `port:22 org:Amazon`, `webcam has_screenshot:true`  
Requires a Shodan API key.

---

## Shodan API Key

Options 7 and 8 require a Shodan API key.

1. Register free at [https://account.shodan.io/register](https://account.shodan.io/register)
2. Find your API key at [https://account.shodan.io](https://account.shodan.io)
3. Enter it when prompted by the script

You can also set it as an environment variable to avoid typing it every time:

```bash
export SHODAN_API_KEY="your_api_key_here"
sudo -E ./Scan_Tool.sh
```

---

## Reports

Every scan automatically saves a timestamped report:

```
reports/
└── scan_20260101_120000.txt
```

View your reports:

```bash
# List all reports
ls -lh reports/

# View latest report
cat reports/$(ls -t reports/ | head -1)
```

---

## Troubleshooting

| Error | Cause | Fix |
|---|---|---|
| `Permission denied` | Not using sudo | Run with `sudo ./Scan_Tool.sh` |
| `nmap: command not found` | Nmap not installed | `sudo apt-get install -y nmap` |
| `jq: command not found` | jq not installed | `sudo apt-get install -y jq` |
| `zenity: command not found` | Zenity not installed | `sudo apt-get install -y zenity` |
| GUI window doesn't open | No desktop environment | Use `Scan_Tool.sh` (CLI) instead |
| Shodan returns API error | Wrong or expired key | Check key at account.shodan.io |
| `sh: bad syntax` | Running with `sh` not `bash` | Use `sudo ./Scan_Tool.sh` not `sudo sh` |
| Scan shows no results | Host may be down or filtered | Try `-Pn` flag or Ping Scan first |

---

## Project Structure

```
Network-Scanning-Script-with-Firewall-Evasion-technique-/
│
├── Scan_Tool.sh          # CLI version (terminal)
├── Scan_Tool_GUI.sh      # GUI version (graphical)
├── README.md             # This file
└── reports/              # Auto-created, stores scan results
    └── scan_YYYYMMDD_HHMMSS.txt
```

---

## Third-Party Tools Used

**Nmap**
- Copyright (c) Gordon "Fyodor" Lyon
- Licensed under the Nmap Public Source License (GPLv2-based)
- https://nmap.org/npsl/

**Shodan**
- Copyright (c) Shodan LLC
- Used via REST API — requires API key
- Subject to Shodan Terms of Service
- https://www.shodan.io/terms

---

## License

This project is released under the **GNU General Public License v2.0 (GPLv2)**.

You are free to use, modify, and distribute this software under the terms of GPLv2.  
Full license: https://www.gnu.org/licenses/old-licenses/gpl-2.0.html

---

## Disclaimer

> This tool is developed strictly for **educational, research, and authorized  
> security testing purposes only.**
>
> Unauthorized scanning of networks or systems that you do not own or have  
> **explicit written permission** to test is **illegal and unethical** under the  
> Computer Misuse Act and similar laws worldwide.
>
> The author is **NOT responsible** for any misuse, damage, or legal consequences  
> resulting from the use of this tool.
>
> By using this tool, you confirm that you have proper authorization for all  
> targets you scan.

---

## Author

**Sahebrao Rahire**  
B.Sc Final Year Project — 2026  
GitHub: [github.com/Rahires](https://github.com/Rahires)
