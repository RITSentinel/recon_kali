#!/bin/bash
# ===============================================================
#  kali_full_setup.sh  –  Full Kali Recon Environment Provisioner
#  Author : John          
#  Purpose: Install a complete Kali recon workstation, harden basics,
#           and drop a one‑click launcher on the Desktop.
#  Usage  : ./kali_full_setup.sh [--debug]
# ===============================================================
# Detect device model
MODEL=$(sudo dmidecode -s system-product-name 2>/dev/null || hostnamectl | grep "Hardware" | awk -F: '{print $2}' | xargs)
echo "🖥️ Detected system: $MODEL"

# Load device-specific hotkeys (if available)
HOTKEY_DIR="$HOME/.config/hotkeys"
mkdir -p "$HOTKEY_DIR"
case "$MODEL" in
  *MacBook*)   cp hotkeys/mac.conf "$HOTKEY_DIR/custom.conf" ;;
  *XPS*|*Dell*) cp hotkeys/dell.conf "$HOTKEY_DIR/custom.conf" ;;
  *ThinkPad*)  cp hotkeys/thinkpad.conf "$HOTKEY_DIR/custom.conf" ;;
  *)           cp hotkeys/default.conf "$HOTKEY_DIR/custom.conf" ;;
esac

set -euo pipefail
 # ----- Self‑healing prep & optional debug -----
if [[ "${1-}" == "--debug" ]]; then
  set -x   # verbose tracing
  echo "[DEBUG] Mode enabled"
fi

export DEBIAN_FRONTEND=noninteractive

echo "[SELF‑HEAL] Clearing potential APT locks..."
sudo rm -f /var/lib/dpkg/lock-frontend /var/cache/apt/archives/lock || true
sudo dpkg --configure -a  || true
sudo apt --fix-broken install -y || true
LOGFILE="$HOME/kali_full_setup-install.log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "📦 Starting full recon setup (This may take a while)..."

# --- 1. Update & Upgrade System ---
echo "🔄 Updating system..."
sudo apt update -y && sudo apt upgrade -y && sudo apt dist-upgrade -y
sudo apt autoremove -y && sudo apt clean

# --- 2. Install Kali Recon Tools ---
echo "🛠️ Installing Kali Linux scanning & recon tools..."

if sudo apt install -y kali-linux-headless; then
  echo "[✔] Installed: kali-linux-headless $(date)" >> "$LOGFILE"
else
  echo "[✘] Failed: kali-linux-headless $(date)" >> "$LOGFILE"
fi

if sudo apt install -y kali-tools-top10 kali-tools-information-gathering kali-tools-vulnerability kali-tools-web kali-tools-wireless kali-tools-exploitation; then
  echo "[✔] Installed: kali-tools-top10 kali-tools-information-gathering kali-tools-vulnerability kali-tools-web kali-tools-wireless kali-tools-exploitation $(date)" >> "$LOGFILE"
else
  echo "[✘] Failed: one or more kali tool groups (top10, information-gathering, vulnerability, web, wireless, exploitation) $(date)" >> "$LOGFILE"
fi

# --- 3. Basic Hardening ---
echo "🛡️ Setting up firewall and protection tools..."
sudo apt install -y ufw fail2ban net-tools
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw enable || true

echo "🔐 Enabling IP spoof protection..."
echo 1 | sudo tee /proc/sys/net/ipv4/conf/all/rp_filter
sudo sysctl -w net.ipv4.conf.all.rp_filter=1
sudo sysctl -p

# --- 4. Anonymity Tools ---
echo "🕵️ Installing anonymity tools (Tor, Macchanger, ProxyChains)..."
sudo apt install -y tor macchanger proxychains4

echo "🔁 Randomizing MAC address on boot..."
echo -e '#!/bin/bash\nmacchanger -r eth0' | sudo tee /etc/network/if-pre-up.d/macchanger
sudo chmod +x /etc/network/if-pre-up.d/macchanger

echo "🎭 Setting anonymous hostname..."
sudo hostnamectl set-hostname "anon-$(tr -dc A-Za-z0-9 </dev/urandom | head -c 6)"

# --- 5. Configure ProxyChains for Tor ---
echo "🔧 Configuring ProxyChains..."
sudo sed -i 's/^#dynamic_chain/dynamic_chain/' /etc/proxychains4.conf
sudo sed -i 's/^strict_chain/#strict_chain/' /etc/proxychains4.conf
sudo sed -i 's/^#proxy_dns/proxy_dns/' /etc/proxychains4.conf
sudo sed -i '$a socks5  127.0.0.1 9050' /etc/proxychains4.conf

# --- 6. Start Tor ---
echo "🚀 Starting Tor service..."
sudo systemctl enable tor
sudo systemctl start tor

# --- 7. User Feedback with whiptail ---
echo "📣 Showing completion dialog..."
sudo apt install -y whiptail
whiptail --title "Setup Complete" --msgbox "Recon environment installed successfully!\nReport will be on Desktop." 10 60

# --- 8. Prompt to run scan ---
if whiptail --yesno "Would you like to run a scan now?" 10 60; then
    TARGET=$(whiptail --inputbox "Enter target IP or domain for recon:" 10 60 --title "Target Entry" 3>&1 1>&2 2>&3)
    echo "🧠 Starting scan on $TARGET..."
    echo "Scan started on $TARGET at $(date)" >> "$LOGFILE"
    nmap -sV "$TARGET" | tee -a "$LOGFILE"
else
    echo "🔕 User chose not to start scan now." >> "$LOGFILE"
fi

# --- 9. Final Cleanup ---
echo "🧹 Cleaning up..."
sudo apt autoremove -y
sudo apt autoclean -y
sudo updatedb

# --- 10. Output Final Report ---
DESKTOP_DIR="$HOME/Desktop"
REPORT_NAME="KaliFullSetup-Report-$(date +%Y%m%d_%H%M).log"

echo "📝 Creating setup summary report..."
cp "$LOGFILE" "$DESKTOP_DIR/$REPORT_NAME" 2>/dev/null || mkdir -p "$DESKTOP_DIR" && cp "$LOGFILE" "$DESKTOP_DIR/$REPORT_NAME"

echo ""
echo "✅ All done! Your Kali recon environment is now ready."
echo "📄 Setup report saved to: $DESKTOP_DIR/$REPORT_NAME"
echo "🧠 Remember: After running this, use your recon script separately to scan."

# --- 11. Create Desktop Launcher ---
LAUNCHER_PATH="$DESKTOP_DIR/Run-Kali-Recon.desktop"
cat > "$LAUNCHER_PATH" <<EOF
[Desktop Entry]
Version=1.0
Name=Run Recon Scan
Comment=Launch recon scan setup
Exec=/bin/bash /home/$USER/Project/recon/recon.sh
Icon=utilities-terminal
Terminal=true
Type=Application
Categories=Utility;
EOF
chmod +x "$LAUNCHER_PATH"

# Note: A clickable desktop launcher 'Run-Kali-Recon.desktop' has been added to your Desktop for easier execution.