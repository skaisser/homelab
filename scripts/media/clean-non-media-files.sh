#!/bin/bash
set -euo pipefail

# media-cleaner.sh
# Usage: ./media-cleaner.sh [--dry-run] /path/to/folder

DRY_RUN=false
START_PATH=""

# Check if the first argument is --dry-run
if [ "${1:-}" == "--dry-run" ]; then
  DRY_RUN=true
  START_PATH="${2:-}"
else
  START_PATH="${1:-}"
fi

if [ -z "$START_PATH" ]; then
  echo "❌ Start path not provided."
  echo "👉 Usage: ./media-cleaner.sh [--dry-run] /mnt/media/data/media/movies"
  exit 1
fi

echo "🧹 Cleaning unnecessary files in: $START_PATH"
echo "📂 Keeping: .mkv .mp4 .avi .mov .wmv .m4v .srt .ass .sub .iso"

if $DRY_RUN; then
  echo "🔍 Dry-run mode enabled (no files will be deleted)"
  find "$START_PATH" -type f \
    ! \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" \
    -o -iname "*.mov" -o -iname "*.wmv" -o -iname "*.m4v" \
    -o -iname "*.srt" -o -iname "*.ass" -o -iname "*.sub" \
    -o -iname "*.iso" \) \
    -print
else
  find "$START_PATH" -type f \
    ! \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" \
    -o -iname "*.mov" -o -iname "*.wmv" -o -iname "*.m4v" \
    -o -iname "*.srt" -o -iname "*.ass" -o -iname "*.sub" \
    -o -iname "*.iso" \) \
    -print -delete
  echo "✅ Cleanup completed."
fi
