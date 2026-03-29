#!/usr/bin/env python3
import sys
import subprocess
import os

def generate_report(finding, target):
    """
    Calls the local Dolphin model to synthesize a high-fidelity, payout-ready report.
    """
    print(f"[*] Synthesizing High-Fidelity Report for: {target}")
    
    prompt = f"""
    ### BOUNTY-BOT-v1: MISSION REPORT SYNTHESIS ###
    Target Domain: {target}
    Raw Discovery Data: {finding}
    
    Task: Synthesize a professional Bug Bounty report that maximizes the probability of a 'High' or 'Critical' triage and payout.
    
    Report Requirements:
    1. **Title**: Concise and impactful (e.g., [Vulnerability Type] on [Subdomain]).
    2. **Executive Summary**: 2-3 sentences explaining the risk to the business.
    3. **Technical Details**: 
       - Vulnerability Type
       - Severity (CVSS Score estimate)
       - Impacted URL/Endpoint
    4. **Proof of Concept (PoC)**: Clear, numbered steps to reproduce. Include the exact curl command or payload.
    5. **Impact Assessment**: What can an attacker actually DO? (e.g., Data exfiltration, Account takeover).
    6. **Remediation**: Crisp, actionable steps for the engineering team to fix the flaw.
    
    Tone: Senior Security Researcher. Precise, objective, and polite. No conversational filler.
    """
    
    try:
        # Offload to Dolphin
        result = subprocess.run(['dolphin', prompt], capture_output=True, text=True)
        return result.stdout
    except Exception as e:
        return f"Error offloading to Dolphin: {e}"

def main():
    if len(sys.argv) < 3:
        print("Usage: reporter.py <nuclei_output_file> <target_name>")
        sys.exit(1)

    input_file = sys.argv[1]
    target = sys.argv[2]
    
    if not os.path.exists(input_file):
        print(f"[!] Input file {input_file} not found.")
        sys.exit(1)

    with open(input_file, 'r') as f:
        findings = f.readlines()

    if not findings:
        print("[*] No findings to report.")
        return

    report_dir = f"/home/crex/bounty-bot/reports/{target}"
    os.makedirs(report_dir, exist_ok=True)

    for i, finding in enumerate(findings):
        if not finding.strip(): continue
        
        report_content = generate_report(finding.strip(), target)
        report_path = os.path.join(report_dir, f"finding_{i+1}.md")
        
        # Crisp output: Header + Findings + Evidence
        full_output = f"# BUG BOUNTY REPORT: {target}\n\n"
        full_output += report_content
        full_output += "\n\n---\n### RAW EVIDENCE (NUCLEI DATA)\n"
        full_output += f"```\n{finding.strip()}\n```\n"
        
        with open(report_path, 'w') as rf:
            rf.write(full_output)
        
        print(f"[+] Crisp report generated: {report_path}")

if __name__ == "__main__":
    main()
