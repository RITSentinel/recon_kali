# 🔍 Recon Automation Suite

This project provides a dual-script system to automate the setup and execution of advanced reconnaissance workflows on Kali Linux. It is designed for ethical hacking, penetration testing, bug bounty hunting, and research **only** with explicit authorization.

---

## ⚙️ Components

### 1. `kali_recon_setup.sh` – Recon‑Only Provisioning Script
- Installs **only** reconnaissance & OSINT tools (small footprint).
- Applies system hardening:
  - Enables UFW firewall with default‑deny rules.
  - Installs `fail2ban`, `proxychains4`, `tor`, `macchanger`, and other stealth helpers.
  - Randomizes MAC address and hostname on boot.
- Drops a Markdown summary report plus the **Run‑Recon.desktop** launcher on the Desktop.

### 2. `kali_full_setup.sh` – Full Kali Environment Provisioner
- Everything in the recon setup **plus** the full `kali-linux-default` toolset.
- Same hardening steps as above.
- Summary report saved to the Desktop.

### 3. `recon.sh` – Guided Recon Launcher
- Performs deep passive and semi‑active reconnaissance.
- Supports:
  - Stealth mode (`--stealth`) for randomized MAC and Tor routing.
  - Masking mode (`--mask`) for proxychains‑over‑Tor.
  - Dry‑run mode (`--dry-run`) to preview commands with no changes.
  - Self‑healing logic for hung or failed tools.
  - JSON summary and organized reports saved per target.
- Tools invoked: `whois`, `theHarvester`, `amass`, `nmap`, `gau`, `ffuf`, `sqlmap`, and more.

---

## 🚀 Quick Start

1. **Lite (recon‑only) setup**  
   ```bash
   chmod +x kali_recon_setup.sh
   ./kali_recon_setup.sh
   ```

   **or**  

   **Full setup**  
   ```bash
   chmod +x kali_full_setup.sh
   ./kali_full_setup.sh
   ```

2. **Run recon against a target:**  
   ```bash
   chmod +x recon.sh
   ./recon.sh example.com --stealth
   ```

3. **Check output:**  
   - Reports and logs are saved under `~/reports/` *and* on the Desktop.  
   - A Markdown summary (`*Setup‑Report‑*.md`) plus JSON subdomain summary are generated.  
   - If you’re unsure how to interpret the report, see the **🤖 Need help** section below.

### 🤖 Need help reading the setup or recon reports?

If the Markdown summary on your Desktop feels cryptic, copy‑paste its contents into your preferred AI assistant with a prompt like:

> “Explain this Kali setup report for a non‑technical user and highlight any actions I should double‑check.”

The report is deliberately AI‑friendly (Markdown, bullet‑points) so large‑language models can break it down for you.

---

## ⚖️ Legal & Ethical Notice

> This toolkit is strictly for:
> - Educational use
> - Penetration testing with **explicit written permission**
> - Legal bug bounty engagements
>
> Unauthorized use is strictly prohibited and may violate laws and terms of service.

---

## 📁 Output Structure

```
~/reports/
├── target.com_YYYYMMDD_HHMM/
│   ├── whois.txt
│   ├── amass_passive.txt
│   ├── gau.txt
│   ├── recon_summary.json
│   ├── bughunter.log
│   └── ...
```

---

## 🧠 Notes

- GUI tools like Maltego and SpiderFoot must be run manually.
- Ensure Tor is running before using `--mask` mode.
- Internet access is required for tool installations and passive recon data scraping.

---

## 👤 Maintainer

Built by John  field-ready OSINT and recon system.