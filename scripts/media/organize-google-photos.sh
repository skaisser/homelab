#!/bin/bash
set -euo pipefail

# organize-google-photos.sh - Sorts a Google Photos export into photos/ and videos/ subdirectories

usage() {
  echo "Usage: $0 [path]"
  echo ""
  echo "Sorts a Google Photos export into photos/ and videos/ subdirectories."
  echo ""
  echo "Arguments:"
  echo "  path    Path to the Google Photos export directory (prompted if omitted)"
  echo ""
  echo "Options:"
  echo "  -h, --help    Show this help message and exit"
  echo ""
  echo "Example:"
  echo "  $0 /mnt/storage/google-photos-export"
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -ge 1 ]]; then
  BASE_DIR="$1"
else
  read -rp "Enter the path to your Google Photos export: " BASE_DIR
fi

if [[ ! -d "$BASE_DIR" ]]; then
  echo "Error: Directory '$BASE_DIR' does not exist."
  exit 1
fi

# Directories for videos and photos
PHOTO_DIR="$BASE_DIR/photos"
VIDEO_DIR="$BASE_DIR/videos"

# Create directories if they don't exist
mkdir -p "$PHOTO_DIR"
mkdir -p "$VIDEO_DIR"

# File extensions for photos and videos
PHOTO_EXTENSIONS="jpg jpeg png gif heic bmp tiff"
VIDEO_EXTENSIONS="mp4 mov avi mkv m4v flv wmv"

# Function to move files based on their extension
move_files() {
  local extension_list="$1"
  local target_dir="$2"

  for ext in $extension_list; do
    find "$BASE_DIR" -type f -iname "*.$ext" -not -path "$PHOTO_DIR/*" -not -path "$VIDEO_DIR/*" -exec mv {} "$target_dir" \;
  done
}

# Move photo files
echo "Moving photo files..."
move_files "$PHOTO_EXTENSIONS" "$PHOTO_DIR"

# Move video files
echo "Moving video files..."
move_files "$VIDEO_EXTENSIONS" "$VIDEO_DIR"

echo "Done. Photos in '$PHOTO_DIR', videos in '$VIDEO_DIR'."
