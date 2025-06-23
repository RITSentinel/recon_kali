#!/bin/bash
# ====================================================================
#  recon.sh  –  Guided Recon Launcher
#  Author : John   
# ====================================================================

# ⚖️ LEGAL NOTICE:
# This script is for educational use, legal penetration testing,
# or authorized bug bounty programs *with explicit permission only*.
# Unauthorized scanning or exploitation is prohibited and may be illegal.

echo "⚖️  EDUCATIONAL / AUTHORIZED USE ONLY"
read -p 'Do you have explicit permission to scan the target? (yes/no) ' ACK
if [[ "$ACK" != "yes" ]]; then
  echo "Aborting. Authorization not confirmed."
  exit 1
fi

TARGET="${1:-}"
MODE="${2:-normal}"  # Options: normal, stealth, mask

# Interactive prompt if target not supplied
if [[ -z "$TARGET" ]]; then
  read -rp "Enter target domain or IP: " TARGET
  if [[ -z "$TARGET" ]]; then
    echo "No target provided. Exiting."
    exit 1
  fi
fi

# Environment Setup
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_DIR="reports/${TARGET}_${TIMESTAMP}"
mkdir -p "$OUTPUT_DIR"
LOGFILE="$OUTPUT_DIR/recon.log"
SUMMARY_JSON="$OUTPUT_DIR/summary.json"

log() { echo -e "[$(date +%H:%M:%S)] $1" | tee -a "$LOGFILE"; }
run() {
  timeout 300 "$@" || log "⚠️ Timed out or failed: $*"
  sleep 1
}

log "📁 Starting recon for: $TARGET in mode: $MODE"

# Stealth / Mask Mode Handling
if [[ "$MODE" == "stealth" ]]; then
  log "🕵️ Stealth mode activated: Randomizing MAC address"
  IFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
  sudo macchanger -r "$IFACE"
elif [[ "$MODE" == "mask" ]]; then
  log "🕵️ Masking enabled: Routing via Tor"
  sudo systemctl start tor || true
  export PROXYCHAINS_CONF_FILE=/etc/proxychains4.conf
  run proxychains4 curl -s https://check.torproject.org/ > "$OUTPUT_DIR/tor_check.html"
fi

# Tool list
TOOLS=(whois dig nslookup theHarvester sublist3r assetfinder amass httprobe gau waybackurls \
       shodan dmitry fierce recon-ng gospider torsocks lynx nuclei ffuf sqlmap subfinder wappalyzer)

log "🔧 Verifying tool installation..."
MISSING=false
for tool in "${TOOLS[@]}"; do
  if ! command -v $tool &>/dev/null; then
    log "❌ Missing: $tool"
    MISSING=true
  else
    log "✅ Found: $tool"
  fi
  sleep 0.5

done
if [ "$MISSING" = true ]; then
  log "🛑 Missing tools. Exiting."
  exit 1
fi

# Recon Sequence
log "🚀 Running recon tasks..."

run whois $TARGET > "$OUTPUT_DIR/whois.txt"
run dig +trace $TARGET > "$OUTPUT_DIR/dig_trace.txt"
run nslookup $TARGET > "$OUTPUT_DIR/nslookup.txt"
run theHarvester -d $TARGET -b all -f "$OUTPUT_DIR/theHarvester"
run sublist3r -d $TARGET -o "$OUTPUT_DIR/sublist3r.txt"
run assetfinder --subs-only $TARGET > "$OUTPUT_DIR/assetfinder.txt"
run amass enum -passive -d $TARGET -o "$OUTPUT_DIR/amass.txt"
run cat "$OUTPUT_DIR/assetfinder.txt" | httprobe > "$OUTPUT_DIR/httprobe.txt"
run gau $TARGET > "$OUTPUT_DIR/gau.txt"
echo $TARGET | waybackurls > "$OUTPUT_DIR/waybackurls.txt"
run curl -s "https://crt.sh/?q=%25.$TARGET&output=json" > "$OUTPUT_DIR/crtsh.json"
run dmitry -winsepfb $TARGET > "$OUTPUT_DIR/dmitry.txt"
run fierce --domain $TARGET > "$OUTPUT_DIR/fierce.txt"
run gospider -s https://$TARGET -o "$OUTPUT_DIR/gospider"
run lynx -dump https://$TARGET > "$OUTPUT_DIR/lynx.txt"
run recon-ng -w $TARGET -m recon.domains-hosts.bing_domain_web -x "run; exit" > "$OUTPUT_DIR/recon-ng.txt"
run shodan domain $TARGET > "$OUTPUT_DIR/shodan.txt"
run torsocks curl -s https://check.torproject.org/ > "$OUTPUT_DIR/tor_check.html"
run nuclei -u https://$TARGET -silent > "$OUTPUT_DIR/nuclei.txt"
run ffuf -u https://$TARGET/FUZZ -w /usr/share/seclists/Discovery/Web-Content/common.txt -mc all -t 25 > "$OUTPUT_DIR/ffuf.txt"
run sqlmap -u "https://$TARGET" --batch --crawl=1 --level=2 --risk=1 > "$OUTPUT_DIR/sqlmap.txt"
run subfinder -d $TARGET -o "$OUTPUT_DIR/subfinder.txt"
run wappalyzer $TARGET > "$OUTPUT_DIR/wappalyzer.json"

# Summary Report
cat <<EOF > "$SUMMARY_JSON"
{
  "target": "$TARGET",
  "timestamp": "$(date --iso-8601=seconds)",
  "subdomains_found": {
    "subfinder": $(wc -l < "$OUTPUT_DIR/subfinder.txt" 2>/dev/null || echo 0),
    "assetfinder": $(wc -l < "$OUTPUT_DIR/assetfinder.txt" 2>/dev/null || echo 0),
    "amass": $(wc -l < "$OUTPUT_DIR/amass.txt" 2>/dev/null || echo 0)
  },
  "live_hosts": $(wc -l < "$OUTPUT_DIR/httprobe.txt" 2>/dev/null || echo 0),
  "output_directory": "$OUTPUT_DIR"
}
EOF

log "✅ Recon complete. Summary saved to $SUMMARY_JSON"
echo "📄 View results: less $LOGFILE"
echo "🗃️  View JSON: cat $SUMMARY_JSON"