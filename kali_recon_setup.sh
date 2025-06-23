#!/bin/bash

# ===============================================================
#  kali_recon_setup.sh  –  Lightweight Recon‑Only Provisioner
#  Author : John           
#  Purpose: Install ONLY reconnaissance & OSINT tools on Kali,
#           then drop a one‑click Desktop launcher to run recon.sh.
#  Usage  : ./kali_recon_setup.sh [--debug]
# ===============================================================

# ----- Self‑healing prep & optional debug -----
set -euo pipefail
if [[ "${1-}" == "--debug" ]]; then
  set -x   # verbose tracing
  echo "[DEBUG] Mode enabled"
fi

export DEBIAN_FRONTEND=noninteractive
echo "[SELF-HEAL] Clearing potential APT locks..."
sudo rm -f /var/lib/dpkg/lock-frontend /var/cache/apt/archives/lock || true
sudo dpkg --configure -a  || true
sudo apt --fix-broken install -y || true

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Tools list - recon and OSINT tools only
TOOLS=(
  "nmap"
  "masscan"
  "theharvester"
  "dnsenum"
  "sublist3r"
  "amass"
  "gobuster"
  "whois"
  "nikto"
  "whatweb"
  "curl"
  "wget"
)

# Timeout for each tool installation (seconds)
INSTALL_TIMEOUT=120

# Log file on Desktop
TIMESTAMP=$(date +"%Y%m%d_%H%M")
REPORT_FILE="$HOME/Desktop/Recon-Report-$TIMESTAMP.log"

echo -e "${CYAN}Starting Kali Recon Setup...${NC}"
echo -e "${CYAN}Installing recon and OSINT tools only.${NC}"
echo -e "${CYAN}All output will be logged to ${REPORT_FILE}${NC}"

echo -e "===== Recon Setup Log - $(date) =====" > "$REPORT_FILE"

# Update package lists first
echo -e "${YELLOW}Updating package lists...${NC}"
if sudo apt-get update >> "$REPORT_FILE" 2>&1; then
  echo -e "${GREEN}Package lists updated successfully.${NC}"
else
  echo -e "${RED}Failed to update package lists. Continuing anyway.${NC}"
fi

# Function to install a tool with timeout and self-healing
install_tool() {
  local tool=$1
  echo -e "${BLUE}Installing $tool...${NC}" | tee -a "$REPORT_FILE"
  # Try install with timeout
  if timeout $INSTALL_TIMEOUT sudo apt-get install -y "$tool" >> "$REPORT_FILE" 2>&1; then
    echo -e "${GREEN}$tool installed successfully.${NC}" | tee -a "$REPORT_FILE"
  else
    echo -e "${YELLOW}Initial install of $tool failed or timed out. Retrying...${NC}" | tee -a "$REPORT_FILE"
    # Try fix broken installs and retry
    sudo apt-get install -f -y >> "$REPORT_FILE" 2>&1
    if timeout $INSTALL_TIMEOUT sudo apt-get install -y "$tool" >> "$REPORT_FILE" 2>&1; then
      echo -e "${GREEN}$tool installed successfully on retry.${NC}" | tee -a "$REPORT_FILE"
    else
      echo -e "${RED}Failed to install $tool after retry.${NC}" | tee -a "$REPORT_FILE"
    fi
  fi
}

# Install each tool
for tool in "${TOOLS[@]}"; do
  install_tool "$tool"
done

echo -e "${GREEN}All tool installations attempted.${NC}"

# Create clickable launcher shortcut on Desktop
LAUNCHER="$HOME/Desktop/Run-Recon.desktop"
echo -e "${BLUE}Creating recon launcher on Desktop...${NC}"
cat > "$LAUNCHER" <<EOF
[Desktop Entry]
Version=1.0
Name=Run Recon Scan
Comment=Launch guided recon scan
Exec=/bin/bash /home/$USER/Project/recon/recon.sh
Icon=utilities-terminal
Terminal=true
Type=Application
Categories=Utility;
EOF
chmod +x "$LAUNCHER"
echo -e "${GREEN}Recon launcher created at $LAUNCHER${NC}"

# Summary report header
{
  echo "===== Recon Setup Summary Report ====="
  echo "Date: $(date)"
  echo ""
  echo "Installed tools status:"
} >> "$REPORT_FILE"

# Check installed tools and append status
for tool in "${TOOLS[@]}"; do
  if command -v "$tool" >/dev/null 2>&1; then
    echo "$tool: Installed" >> "$REPORT_FILE"
  else
    echo "$tool: Not Installed" >> "$REPORT_FILE"
  fi
done

echo -e "${CYAN}Setup summary report saved to ${REPORT_FILE}${NC}"
