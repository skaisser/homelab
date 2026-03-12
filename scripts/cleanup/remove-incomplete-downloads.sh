#!/bin/bash
set -euo pipefail

# remove-incomplete-downloads.sh - Removes incomplete download files (.fuse_hidden*, .partial, .!qB)

usage() {
  echo "Usage: $0 [path]"
  echo ""
  echo "Removes incomplete download files (.fuse_hidden*, .partial, .!qB) from a directory tree."
  echo ""
  echo "Arguments:"
  echo "  path    Path to the directory to clean (prompted if omitted)"
  echo ""
  echo "Options:"
  echo "  -h, --help    Show this help message and exit"
  echo ""
  echo "Example:"
  echo "  $0 /mnt/storage/downloads"
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

# Check if a directory path was provided as an argument, otherwise prompt the user for the path
if [[ $# -ge 1 ]]; then
  BASE_DIR="$1"
else
  read -rp "Please provide the path to the directory: " BASE_DIR
fi

# Check if the provided directory exists
if [[ ! -d "$BASE_DIR" ]]; then
  echo "Error: Directory '$BASE_DIR' does not exist."
  exit 1
fi

# Ensure that the script is not run on sensitive directories
if [[ "$BASE_DIR" == "/" || "$BASE_DIR" == "/home" ]]; then
  echo "Error: Unsafe to run on root or home directories."
  exit 1
fi

# Find and delete files ending with .fuse_hidden*, .partial, or .!qB, and output the file names as they are deleted
echo "Searching and deleting files in '$BASE_DIR'..."
find "$BASE_DIR" -type f \( -name "*.fuse_hidden*" -o -name "*.partial" -o -name "*.!\qB" \) -exec rm -vf {} + 2> /dev/null

if [[ $? -eq 0 ]]; then
  echo "Cleanup complete!"
else
  echo "Error occurred during cleanup."
fi
