#!/bin/bash
set -euo pipefail

# ip-checker.sh - Scan a subnet range and find the first available IP address

# Default configuration
SUBNET="10.0.1"
START=200
END=254

# Usage/help text
usage() {
  echo "Usage: $(basename "$0") [-s SUBNET] [-f START] [-l END] [-h]"
  echo ""
  echo "Scan a subnet range and find the first available IP address."
  echo ""
  echo "Options:"
  echo "  -s SUBNET   Subnet prefix (default: $SUBNET)"
  echo "  -f START    First host number to check (default: $START)"
  echo "  -l END      Last host number to check (default: $END)"
  echo "  -h          Show this help message"
  echo ""
  echo "Example: $(basename "$0") -s 192.168.1 -f 100 -l 200"
  exit 0
}

# Parse CLI arguments
while getopts ":s:f:l:h" opt; do
  case $opt in
    s) SUBNET="$OPTARG" ;;
    f) START="$OPTARG" ;;
    l) END="$OPTARG" ;;
    h) usage ;;
    \?) echo "[!] Invalid option: -$OPTARG" >&2; usage ;;
    :) echo "[!] Option -$OPTARG requires an argument." >&2; usage ;;
  esac
done

echo "[*] Scanning ${SUBNET}.${START}-${END} for available IPs..."

for i in $(seq "$START" "$END"); do
    ip="${SUBNET}.${i}"
    if ! ping -c 1 -W 1 "$ip" &>/dev/null; then
        echo "✅ IP $ip is available."
        exit 0
    else
        echo "❌ IP $ip is already in use."
    fi
done

echo "🚫 No free IPs found in range."
exit 1
