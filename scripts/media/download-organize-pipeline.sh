#!/bin/bash
set -euo pipefail
# media-workflow.sh - Wrapper script to ensure sequential execution of download and sorting
# This script first downloads files from Put.io and then sorts them

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Run the full media workflow: download from Put.io then organize with filebot.

Options:
  -h, --help             Show this help message and exit

Environment variables:
  LOG_DIR                Override log directory (default: /var/log/$(basename "$0" .sh))

Note: The individual scripts (download-from-putio.sh, organize-with-filebot.sh) will
prompt for their own paths if not already configured. You can also pass arguments to
them by setting their respective environment variables before running this script.

Examples:
  $(basename "$0")
  LOG_DIR=/var/log/media-workflow $(basename "$0")
EOF
  exit 0
}

# Parse flags
for arg in "$@"; do
  case "$arg" in
    -h|--help) usage ;;
  esac
done

# Define variables
DATE=$(date +%Y%m%d_%H%M%S)
LOG_DIR="${LOG_DIR:-/var/log/$(basename "$0" .sh)}"
LOGFILE="${LOG_DIR}/$(basename "$0" .sh)_${DATE}.log"
LOCKFILE="/tmp/$(basename "$0").lock"

# Paths to the scripts (resolve relative to this script's location)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOWNLOADER_SCRIPT="${SCRIPT_DIR}/download-from-putio.sh"
SORTER_SCRIPT="${SCRIPT_DIR}/organize-with-filebot.sh"

# Derive log directories for child scripts from LOG_DIR base
DOWNLOADER_LOG_DIR="${LOG_DIR%/*}/download-from-putio"
SORTER_LOG_DIR="${LOG_DIR%/*}/organize-with-filebot"

# Variables to track if any files were processed
FILES_DOWNLOADED=0
FILES_PROCESSED=0

# Function for cleanup on exit
cleanup() {
  rm -f "$LOCKFILE"
  echo "🛑 Wrapper script interrupted at $(date)" | tee -a "$LOGFILE"
  exit 1
}

# Capture signals for proper cleanup
trap cleanup SIGHUP SIGINT SIGTERM

# Check if already running
if [ -f "$LOCKFILE" ]; then
  pid=$(cat "$LOCKFILE")
  if ps -p "$pid" > /dev/null 2>&1; then
    echo "⚠️ Another instance is already running (PID: $pid). Exiting."
    exit 1
  else
    echo "🔄 Lock file found, but process is not running. Continuing..."
  fi
fi

# Create lock file
echo "$$" > "$LOCKFILE"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"
echo "🌀 Starting media workflow at $(date)" | tee -a "$LOGFILE"

# Step 1: Run the downloader script
echo "📥 Running download script..." | tee -a "$LOGFILE"
"$DOWNLOADER_SCRIPT"
DOWNLOAD_STATUS=$?

# We'll check for recent logs from the individual scripts to determine if they had activity

if [ $DOWNLOAD_STATUS -ne 0 ]; then
  echo "❌ Download script failed with status $DOWNLOAD_STATUS. Aborting workflow." | tee -a "$LOGFILE"
  cleanup
fi

echo "✅ Download completed successfully." | tee -a "$LOGFILE"

# Step 2: Run the sorter script
echo "🔄 Running file organizer script..." | tee -a "$LOGFILE"
"$SORTER_SCRIPT"
SORT_STATUS=$?

if [ $SORT_STATUS -ne 0 ]; then
  echo "❌ Organizer script failed with status $SORT_STATUS." | tee -a "$LOGFILE"
  # We don't exit here as the download was successful
else
  echo "✅ Organization completed successfully. $FILES_PROCESSED file(s) processed." | tee -a "$LOGFILE"
fi

# Summary
echo "📊 Workflow summary:" | tee -a "$LOGFILE"
[ $DOWNLOAD_STATUS -eq 0 ] && echo "✅ Download: Processed successfully" || echo "❌ Download: Processing failed"
[ $SORT_STATUS -eq 0 ] && echo "✅ Organization: Processed successfully" || echo "❌ Organization: Processing failed"
echo "✅ Workflow finished at $(date)" | tee -a "$LOGFILE"

# Remove lock file
rm -f "$LOCKFILE"

# Check for recent logs from the individual scripts (within the last 15 minutes)
CURRENT_TIME=$(date +%s)
FIFTEEN_MINUTES_AGO=$((CURRENT_TIME - 900)) # 15 minutes = 900 seconds

# Function to check if there are recent logs
check_recent_logs() {
  local log_dir="$1"
  local found=0

  if [ -d "$log_dir" ]; then
    # Find the most recent log file
    local recent_log
    recent_log=$(find "$log_dir" -name "*.log" -type f -mmin -15 | head -1)
    if [ -n "$recent_log" ]; then
      found=1
    fi
  fi

  echo "$found"
}

# Check if either script kept its log
DOWNLOADER_KEPT_LOG=$(check_recent_logs "$DOWNLOADER_LOG_DIR")
SORTER_KEPT_LOG=$(check_recent_logs "$SORTER_LOG_DIR")

# Remove our log if neither script kept their logs and both scripts were successful
if [ "$DOWNLOADER_KEPT_LOG" -eq 0 ] && [ "$SORTER_KEPT_LOG" -eq 0 ] && [ $DOWNLOAD_STATUS -eq 0 ] && [ $SORT_STATUS -eq 0 ]; then
  echo "ℹ️ No recent logs found from individual scripts. Removing log file..."
  rm -f "$LOGFILE"
else
  echo "ℹ️ Keeping log due to detected activity or errors"
fi

exit 0
