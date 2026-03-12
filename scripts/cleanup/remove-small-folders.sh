#!/bin/bash
set -euo pipefail

# remove-small-folders.sh - Removes subdirectories below a size threshold

usage() {
  echo "Usage: $0 [options] [path] [threshold]"
  echo ""
  echo "Removes subdirectories below a given size threshold (default: 100 MB)."
  echo ""
  echo "Arguments:"
  echo "  path         Path to the parent directory (prompted if omitted)"
  echo "  threshold    Minimum folder size in MB to keep (default: 100)"
  echo ""
  echo "Options:"
  echo "  -h, --help               Show this help message and exit"
  echo "  --threshold <MB>         Set the size threshold in MB (default: 100)"
  echo ""
  echo "Examples:"
  echo "  $0 /mnt/storage/movies"
  echo "  $0 /mnt/storage/movies 200"
  echo "  $0 --threshold 50 /mnt/storage/movies"
}

# Parse arguments
THRESHOLD=100
DIRECTORY=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --threshold)
      THRESHOLD="${2:?Error: --threshold requires a value}"
      shift 2
      ;;
    *)
      if [[ -z "$DIRECTORY" ]]; then
        DIRECTORY="$1"
      elif [[ "$THRESHOLD" -eq 100 ]]; then
        THRESHOLD="$1"
      fi
      shift
      ;;
  esac
done

# Prompt for directory if not provided
if [[ -z "$DIRECTORY" ]]; then
  read -rp "Enter the path to the directory: " DIRECTORY
fi

# Check if the provided directory exists
if [[ ! -d "$DIRECTORY" ]]; then
  echo "Error: Directory '$DIRECTORY' not found!"
  exit 1
fi

echo "Removing subdirectories smaller than ${THRESHOLD}MB in '$DIRECTORY'..."

# Loop through all subdirectories in the provided directory
for folder in "$DIRECTORY"/*; do
  if [[ -d "$folder" ]]; then
    # Calculate the total size of the folder in MB
    folder_size=$(du -sm "$folder" | cut -f1)

    # Check if the folder size is less than the threshold
    if [[ "$folder_size" -lt "$THRESHOLD" ]]; then
      echo "Deleting folder: $folder (Size: ${folder_size}MB)"
      rm -rf "$folder"
    fi
  fi
done

echo "Cleanup completed."
