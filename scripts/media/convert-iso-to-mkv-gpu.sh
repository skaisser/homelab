#!/bin/bash

# Usage: ./convert_iso_to_mkv_with_gpu.sh /path/to/movies

# Check if NVIDIA GPU is available
if ! command -v nvidia-smi &> /dev/null; then
    echo "NVIDIA GPU not found. Please ensure you have NVIDIA drivers installed."
    exit 1
fi

# Path to the movie directory
MOVIE_PATH=$1

# Check if the path is passed and exists
if [ -z "$MOVIE_PATH" ] || [ ! -d "$MOVIE_PATH" ]; then
    echo "Please provide a valid path to your movie directory."
    exit 1
fi

# Function to convert ISO to MKV
convert_iso_to_mkv() {
    iso_file="$1"
    mkv_file="${iso_file%.*}.mkv"  # Replace .iso with .mkv

    echo "Converting: $iso_file to $mkv_file"

    # Use ffmpeg with NVIDIA GPU hardware acceleration
    ffmpeg -hide_banner -loglevel info -hwaccel nvdec -i "$iso_file" \
    -map 0:v:0 -map 0:a:0 -c:v h264_nvenc -c:a copy "$mkv_file"

    if [ $? -eq 0 ]; then
        echo "Successfully converted: $iso_file to $mkv_file"
        # Delete the .iso file after successful conversion
        rm "$iso_file"
        echo "Deleted original ISO: $iso_file"
    else
        echo "Failed to convert: $iso_file"
    fi
}

# Find all .iso files in the directory and convert them
find "$MOVIE_PATH" -type f -name "*.iso" | while read -r iso_file; do
    convert_iso_to_mkv "$iso_file"
done

echo "Conversion process complete!"
