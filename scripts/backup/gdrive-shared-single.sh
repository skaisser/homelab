#!/bin/bash
set -euo pipefail

# =============================================================================
# gdrive-shared-single.sh
# Backup "Shared with me" files from a Google Drive account using rclone.
#
# Usage:
#   ./gdrive-shared-single.sh <rclone_remote> <destination_path>
#
# Examples:
#   ./gdrive-shared-single.sh mygdrive /mnt/backup/gdrive/shared
#   ./gdrive-shared-single.sh work-drive /data/backups/work-shared
#
# Arguments:
#   rclone_remote    - Name of the rclone remote (as configured in rclone config)
#   destination_path - Local path where shared files will be copied to
#
# Optional environment variables:
#   LOG_DIR          - Directory for log files (default: /var/log/rclone)
#   TRANSFERS        - Number of parallel transfers (default: 16)
#   CHECKERS         - Number of parallel checkers (default: 32)
# =============================================================================

if [[ $# -lt 2 ]]; then
  echo "Error: missing required arguments."
  echo "Usage: $0 <rclone_remote> <destination_path>"
  exit 1
fi

REMOTE="$1"
DEST="$2"

LOG_DIR="${LOG_DIR:-/var/log/rclone}"
TRANSFERS="${TRANSFERS:-16}"
CHECKERS="${CHECKERS:-32}"

DATE=$(date +%Y%m%d_%H%M%S)
LOGFILE="${LOG_DIR}/rclone_shared_copy_${DATE}.log"

mkdir -p "$LOG_DIR"
mkdir -p "$DEST"

echo "Starting shared-with-me Google Drive backup at $(date)" | tee -a "$LOGFILE"
echo "Remote: ${REMOTE}" | tee -a "$LOGFILE"
echo "Destination: ${DEST}" | tee -a "$LOGFILE"

rclone copy "${REMOTE}:" "$DEST" \
  --drive-shared-with-me \
  --drive-root-folder-id=root \
  --transfers="$TRANSFERS" \
  --checkers="$CHECKERS" \
  --multi-thread-streams=16 \
  --buffer-size=16M \
  --use-mmap \
  --drive-pacer-min-sleep=10ms \
  --drive-pacer-burst=200 \
  --stats=1s \
  --log-file="$LOGFILE"

echo "Backup complete at $(date)" | tee -a "$LOGFILE"
