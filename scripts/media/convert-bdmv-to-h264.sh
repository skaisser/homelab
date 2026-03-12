#!/bin/bash

# Check if the path is provided as an argument
if [ -z "$1" ]; then
  echo "Usage: $0 <path_to_bdmv_folder>"
  exit 1
fi

# Define the path to the BDMV folder
BDMV_PATH="$1"

# Check if the BDMV folder exists
if [ ! -d "$BDMV_PATH" ]; then
  echo "Error: BDMV folder '$BDMV_PATH' not found."
  exit 1
fi

# Output directory for the converted files (outside the container)
OUTPUT_DIR="${BDMV_PATH%/*}/h264_output"
mkdir -p "$OUTPUT_DIR"

# Find the largest M2TS file within the BDMV structure (main movie)
M2TS_FILE=$(find "$BDMV_PATH" -name "*.m2ts" -printf "%s %p\n" | sort -nr | head -n 1 | awk '{print $2}')

# Check if an M2TS file was found
if [ -z "$M2TS_FILE" ]; then
  echo "Error: No M2TS file found in '$BDMV_PATH'."
  exit 1
fi

# Construct the output file name (outside the container)
OUTPUT_FILE="$OUTPUT_DIR/$(basename "$BDMV_PATH").mkv"

# Run ffmpeg within the Docker container
docker exec -i ffmpeg-nvidia ffmpeg \
       -hwaccel cuda -i "$M2TS_FILE" \
       -c:v h264_nvenc -preset slow -crf 20 \
       -c:a copy \
       -map 0 \
       "$OUTPUT_FILE"

echo "Conversion complete! Output file: $OUTPUT_FILE"
