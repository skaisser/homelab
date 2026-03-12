#!/bin/bash
set -euo pipefail

# rsync-single-move.sh - Script to move files with high performance (single rsync process)

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] <source> <destination>

Move files between directories using a single high-performance rsync process.

Arguments:
  source        Source directory to move files from (e.g., /mnt/data/source)
  destination   Destination directory to move files to (e.g., /mnt/data/destination)

Options:
  -h, --help    Show this help message and exit

Environment Variables:
  LOG_DIR       Override log directory (default: /var/log/rsync-single-move)
  CHOWN_USER    Owner:group to set on transferred files (default: 1000:1000)

Examples:
  $(basename "$0") /mnt/data/source /mnt/data/destination
  CHOWN_USER=1001:1001 $(basename "$0") /mnt/data/source /mnt/data/destination
  LOG_DIR=/tmp/logs $(basename "$0") /mnt/data/source /mnt/data/destination
EOF
  exit 0
}

# Parse flags
for arg in "$@"; do
  case "$arg" in
    -h|--help) usage ;;
  esac
done

# Get source and destination from arguments or prompt
if [ $# -ge 2 ]; then
  SRC="$1"
  DST="$2"
else
  if [ $# -eq 1 ]; then
    SRC="$1"
  else
    read -rp "Enter source directory: " SRC
  fi
  read -rp "Enter destination directory: " DST
fi

# Configuration
CHOWN_USER="${CHOWN_USER:-1000:1000}" # Owner:group to set on transferred files (override via env var)
LOG_DIR="${LOG_DIR:-/var/log/rsync-single-move}"
LOCKFILE="/tmp/$(basename "$0").lock"
DATE=$(date +%Y%m%d_%H%M%S)
LOGFILE="${LOG_DIR}/rsync_single_${DATE}.log"

# Cleanup function
cleanup() {
  echo "[*] Cleaning up and exiting..." | tee -a "$LOGFILE"
  rm -f "$LOCKFILE"
  exit 1
}

# Trap signals
trap cleanup SIGHUP SIGINT SIGTERM

# Check lockfile
if [ -f "$LOCKFILE" ]; then
  pid=$(cat "$LOCKFILE")
  if ps -p "$pid" > /dev/null 2>&1; then
    echo "[!] Another instance is already running (PID: $pid)."
    exit 1
  else
    echo "[*] Lock file found but process not running. Continuing..."
  fi
fi

# Create lock file and log directory
echo "$$" > "$LOCKFILE"
mkdir -p "$LOG_DIR"

# Check if source and destination exist
if [ ! -d "$SRC" ]; then
  echo "[!] Source directory $SRC does not exist!" | tee -a "$LOGFILE"
  cleanup
fi

if [ ! -d "$DST" ]; then
  echo "[*] Creating destination directory $DST..." | tee -a "$LOGFILE"
  mkdir -p "$DST" || { echo "[!] Failed to create $DST"; cleanup; }
fi

# Check available disk space
SRC_SIZE=$(du -s "$SRC" | awk '{print $1}')
DST_AVAIL=$(df -k "$DST" | awk 'NR==2 {print $4}')
if [ "$SRC_SIZE" -gt "$DST_AVAIL" ]; then
  echo "[!] Not enough space. Need ${SRC_SIZE}KB but only ${DST_AVAIL}KB available." | tee -a "$LOGFILE"
  cleanup
fi

# Start the transfer
echo "[*] Starting rsync from $SRC to $DST" | tee -a "$LOGFILE"
echo "[*] Started at $(date)" | tee -a "$LOGFILE"
echo "[*] Log file: $LOGFILE" | tee -a "$LOGFILE"

ionice -c 2 -n 0 taskset -c 0-60 rsync -avh \
  --remove-source-files \
  --inplace \
  --no-whole-file \
  --info=progress2 \
  --chown="$CHOWN_USER" \
  "$SRC/" "$DST/" >> "$LOGFILE" 2>&1

RSYNC_STATUS=$?

# Cleanup empty directories
echo "[*] Removing empty directories..." | tee -a "$LOGFILE"
find "$SRC" -type d -empty -delete

REMAINING=$(find "$SRC" -type f | wc -l)
if [ "$RSYNC_STATUS" -eq 0 ] && [ "$REMAINING" -eq 0 ]; then
  echo "[✓] Transfer completed successfully." | tee -a "$LOGFILE"
else
  echo "[!] $REMAINING files were not moved. Check the log for details." | tee -a "$LOGFILE"
fi

echo "[*] Finished at $(date)" | tee -a "$LOGFILE"
echo "[*] Total duration: $SECONDS seconds" | tee -a "$LOGFILE"

rm -f "$LOCKFILE"
exit "$RSYNC_STATUS"
