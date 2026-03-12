#!/bin/bash
set -euo pipefail

# rsync-parallel-move.sh - Script to move files using parallel rsync processes
# Optimized for high-performance servers

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] <source> <destination>

Move files between directories using parallel rsync processes.

Arguments:
  source        Source directory to move files from (e.g., /mnt/data/source)
  destination   Destination directory to move files to (e.g., /mnt/data/destination)

Options:
  -h, --help    Show this help message and exit

Environment Variables:
  LOG_DIR       Override log directory (default: /var/log/rsync-parallel-move)
  MAX_JOBS      Number of parallel rsync jobs (default: 24)

Examples:
  $(basename "$0") /mnt/data/source /mnt/data/destination
  MAX_JOBS=48 $(basename "$0") /mnt/data/source /mnt/data/destination
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
LOG_DIR="${LOG_DIR:-/var/log/rsync-parallel-move}"
MAX_JOBS="${MAX_JOBS:-24}"   # Adjust based on your server's capabilities (32-48 for very powerful servers)
LOCKFILE="/tmp/$(basename "$0").lock"
DATE=$(date +%Y%m%d_%H%M%S)
LOGFILE="${LOG_DIR}/rsync_parallel_${DATE}.log"

# Function for cleanup on exit
cleanup() {
  echo "[!] Script interrupted. Cleaning up..." | tee -a "$LOGFILE"
  rm -f "$LOCKFILE"
  exit 1
}

# Trap signals for proper cleanup
trap cleanup SIGHUP SIGINT SIGTERM

# Check if already running
if [ -f "$LOCKFILE" ]; then
  pid=$(cat "$LOCKFILE")
  if ps -p "$pid" > /dev/null 2>&1; then
    echo "[!] Another instance is already running (PID: $pid). Exiting."
    exit 1
  else
    echo "[*] Lock file found but process not running. Continuing..."
  fi
fi

# Create lock file
echo "$$" > "$LOCKFILE"

# Create log directory
mkdir -p "$LOG_DIR"

# Check if source and destination exist
if [ ! -d "$SRC" ]; then
  echo "[!] Source directory $SRC does not exist!" | tee -a "$LOGFILE"
  cleanup
fi

if [ ! -d "$DST" ]; then
  echo "[*] Destination directory $DST does not exist. Creating..." | tee -a "$LOGFILE"
  mkdir -p "$DST"
  if [ $? -ne 0 ]; then
    echo "[!] Failed to create destination directory $DST" | tee -a "$LOGFILE"
    cleanup
  fi
fi

# Check disk space
SRC_SIZE=$(du -s "$SRC" | awk '{print $1}')
DST_AVAIL=$(df -k "$DST" | awk 'NR==2 {print $4}')

if [ "$SRC_SIZE" -gt "$DST_AVAIL" ]; then
  echo "[!] Not enough space in destination. Need ${SRC_SIZE}KB but only ${DST_AVAIL}KB available." | tee -a "$LOGFILE"
  cleanup
fi

# Start the transfer
echo "[*] Starting parallel rsync move from $SRC to $DST with $MAX_JOBS jobs" | tee -a "$LOGFILE"
echo "[*] Started at $(date)" | tee -a "$LOGFILE"
echo "[*] Log file: $LOGFILE" | tee -a "$LOGFILE"

# Count total files for progress reporting
echo "[*] Counting files (this may take a moment)..." | tee -a "$LOGFILE"
TOTAL_FILES=$(find "$SRC" -type f | wc -l)
echo "[*] Found $TOTAL_FILES files to transfer" | tee -a "$LOGFILE"

# Disable errexit for the parallel pipeline (individual rsync failures are handled below)
set +e

# Perform the transfer
find "$SRC" -type f | \
  parallel -j"$MAX_JOBS" --bar --progress \
    "ionice -c 2 -n 0 taskset -c 0-60 rsync -ah --remove-source-files --info=progress2 --inplace --no-whole-file --protect-args --relative \"{}\" \"$DST\" >> \"$LOGFILE\" 2>&1"

RSYNC_STATUS=$?

# Re-enable errexit
set -e

if [ "$RSYNC_STATUS" -ne 0 ]; then
  echo "[!] Some rsync processes encountered errors. Check the log file for details." | tee -a "$LOGFILE"
fi

echo "[*] Cleaning up empty directories..." | tee -a "$LOGFILE"
find "$SRC" -type d -empty -delete

# Final status
REMAINING_FILES=$(find "$SRC" -type f | wc -l)
if [ "$REMAINING_FILES" -eq 0 ]; then
  echo "[✓] Transfer completed successfully! All files moved." | tee -a "$LOGFILE"
else
  echo "[!] Transfer completed with issues. $REMAINING_FILES files not moved." | tee -a "$LOGFILE"
fi

echo "[*] Finished at $(date)" | tee -a "$LOGFILE"
echo "[*] Total duration: $SECONDS seconds" | tee -a "$LOGFILE"

# Remove lock file
rm -f "$LOCKFILE"

exit "$RSYNC_STATUS"
