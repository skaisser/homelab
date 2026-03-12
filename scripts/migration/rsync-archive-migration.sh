#!/bin/bash
set -euo pipefail

# rsync-archive-migration.sh - Script to migrate archive data between storage locations

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] <source> <destination>

Migrate archive data between storage locations using rsync.

Arguments:
  source        Source archive directory (e.g., /mnt/data/source/archive)
  destination   Destination archive directory (e.g., /mnt/data/destination/archive)

Options:
  -h, --help    Show this help message and exit

Environment Variables:
  LOG_DIR       Override log directory (default: /var/log/rsync-archive-migration)

Examples:
  $(basename "$0") /mnt/data/source/archive /mnt/data/destination/archive
  LOG_DIR=/tmp/logs $(basename "$0") /mnt/data/source /mnt/data/dest
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
    read -rp "Enter source archive directory: " SRC
  fi
  read -rp "Enter destination archive directory: " DST
fi

# Configuration
LOG_DIR="${LOG_DIR:-/var/log/rsync-archive-migration}"
DATE=$(date +%Y%m%d_%H%M%S)
LOGFILE="${LOG_DIR}/rsync_archive_migration_${DATE}.log"

mkdir -p "$LOG_DIR"

echo "🌀 Starting migration from $SRC to $DST at $(date)" | tee -a "$LOGFILE"

rsync -aHAX --remove-source-files \
  --info=progress2 --stats \
  --inplace --no-whole-file \
  "$SRC/" "$DST/" \
  | tee -a "$LOGFILE"

echo "✅ Migration finished at $(date)" | tee -a "$LOGFILE"
