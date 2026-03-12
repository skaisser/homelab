#!/bin/bash

# Check if a directory was provided
if [ -z "$1" ]; then
  echo "Usage: $0 <directory>"
  exit 1
fi

# Target directory
TARGET_DIR="$1"

# Supported video file extensions (add more as needed)
VIDEO_EXTENSIONS="mp4|mkv|avi|mov|flv|wmv"

# Find video files recursively and move them to the target directory
find "$TARGET_DIR" -mindepth 2 -type f -iregex ".*\.\($VIDEO_EXTENSIONS\)$" -exec mv -v {} "$TARGET_DIR" \;

echo "All video files have been moved to $TARGET_DIR."
