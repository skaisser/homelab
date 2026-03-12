#!/bin/bash
set -euo pipefail

# remove-empty-files-and-dirs.sh - Deletes zero-byte files and empty directories

# Function to print help message
print_help() {
  echo "Usage: $0 [path]"
  echo ""
  echo "Deletes zero-byte files and empty directories recursively."
  echo ""
  echo "Arguments:"
  echo "  path    Path to the directory to clean (required)"
  echo ""
  echo "Options:"
  echo "  -h, --help    Show this help message and exit"
  echo ""
  echo "Environment variables:"
  echo "  LOG_DIR    Directory for the deletion log file (default: directory of this script)"
  echo ""
  echo "Example:"
  echo "  $0 /mnt/storage/media"
  echo "  LOG_DIR=/var/log $0 /mnt/storage/media"
}

# Check if help option is provided
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  print_help
  exit 0
fi

# Set the initial path to search from
search_path="${1:-}"

# Check if the initial path was provided and is a valid directory
if [[ -z "$search_path" ]]; then
  echo "Error: Initial path not provided. Please specify a directory."
  print_help
  exit 1
elif [[ ! -d "$search_path" ]]; then
  echo "Error: '$search_path' is not a valid directory."
  exit 1
fi

# Function to delete zero-byte files and empty folders recursively
delete_zero_byte_files_and_empty_folders() {
  # Log the start of the process
  logger "Starting deletion of zero-byte files and empty folders..."

  # Print progress message to console
  echo -e "\nDeleting zero-byte files and empty folders...\n"

  # Delete zero-byte files immediately
  find "$search_path" -type f -size 0c -print0 | while IFS= read -r -d '' file; do
    echo "Deleted zero-byte file: $file"
    rm -v "$file"
  done

  # Delete empty folders immediately
  find "$search_path" -type d -empty -print0 | while IFS= read -r -d '' folder; do
    echo "Deleted empty folder: $folder"
    rmdir -v "$folder"
  done

  # Log the end of the process
  logger "Deletion of zero-byte files and empty folders complete."
  echo -e "\n\nDeletion of zero-byte files and empty folders complete.\n"
}

# Set up logging to a file named 'deletion.log'
LOG_DIR="${LOG_DIR:-$(dirname "$0")}"
exec > >(tee "${LOG_DIR}/deletion.log") 2>&1

# Call the function to delete zero-byte files and empty folders recursively
delete_zero_byte_files_and_empty_folders
