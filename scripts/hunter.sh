#!/bin/bash
# --- BOUNTY-BOT-v1: THE SOVEREIGN HUNTER ---
# Automates Recon, Scanning, and Neural Reporting.

TARGET_FILE="/home/crex/bounty-bot/authorized_targets.txt"
BASE_DIR="/home/crex/bounty-bot"
RECON_DIR="$BASE_DIR/recon"
REPORT_SCRIPT="$BASE_DIR/scripts/reporter.py"

# Verification
if [ ! -f "$TARGET_FILE" ]; then
    echo "[!] Target file not found: $TARGET_FILE"
    exit 1
fi

if [ ! -s "$TARGET_FILE" ]; then
    echo "[!] No targets found in $TARGET_FILE. Add domains to start hunting."
    exit 1
fi

echo "[*] Bounty-Bot-v1 ACTIVE. Starting the hunt..."

cat "$TARGET_FILE" | while read domain; do
    if [ -z "$domain" ]; then continue; fi
    
    echo "----------------------------------------------------"
    echo "[+] HUNTING TARGET: $domain"
    echo "----------------------------------------------------"
    
    TARGET_DIR="$RECON_DIR/$domain"
    mkdir -p "$TARGET_DIR"
    
    # 1. Subdomain Discovery
    echo "[*] Phase 1: Enumerating subdomains..."
    subfinder -d "$domain" -all -recursive -o "$TARGET_DIR/subs.txt" -silent
    
    # 2. Live Host Probing
    echo "[*] Phase 2: Probing live hosts..."
    cat "$TARGET_DIR/subs.txt" | httpx -title -tech-detect -status-code -o "$TARGET_DIR/live.txt" -silent
    
    # 3. Endpoint Crawling
    echo "[*] Phase 3: Crawling endpoints..."
    cat "$TARGET_DIR/subs.txt" | katana -d 3 -jc -o "$TARGET_DIR/urls.txt" -silent
    
    # 4. Vulnerability Scanning (Nuclei)
    echo "[*] Phase 4: Scanning for Critical/High vulnerabilities..."
    # Only scan live hosts to save time/resources
    /home/crex/cyber-tools/bin/nuclei -l "$TARGET_DIR/live.txt" -severity critical,high -o "$TARGET_DIR/nuclei_hits.txt" -rl 10 -silent
    
    # 5. Neural Reporting
    if [ -s "$TARGET_DIR/nuclei_hits.txt" ]; then
        echo "[!] HITS DETECTED! Triggering Neural Reporter..."
        python3 "$REPORT_SCRIPT" "$TARGET_DIR/nuclei_hits.txt" "$domain"
    else
        echo "[*] No high-severity vulnerabilities found during this cycle."
    fi
    
    echo "[+] Mission complete for $domain. Logs saved in $TARGET_DIR"
done

echo "[*] All hunts completed. Check $BASE_DIR/reports/ for payout-ready drafts."
