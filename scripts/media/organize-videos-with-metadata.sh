#!/bin/bash

# Check if a directory was provided as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <directory>"
    exit 1
fi

# Set the directory to the provided argument
directory=$1

# Check if the provided directory exists
if [ ! -d "$directory" ]; then
    echo "Directory not found!"
    exit 1
fi

# Specify the file extensions to look for
video_extensions=("*.mkv" "*.mp4" "*.avi" "*.mov" "*.flv" "*.wmv")
related_extensions=("*.srt" "*.sub" "*.idx" "*.jpg" "*.png" "*.nfo")

# Function to move related files to the same folder
move_related_files() {
    base_filename="$1"
    folder_name="$2"

    # Loop through all related file extensions
    for ext in "${related_extensions[@]}"; do
        for related_file in "$base_filename"$ext; do
            if [ -f "$related_file" ]; then
                echo "Moving related file: $related_file -> $folder_name/"
                mv "$related_file" "$folder_name"
            fi
        done
    done
}

# Loop through all specified video files in the directory
for ext in "${video_extensions[@]}"; do
    for file in "$directory"/$ext; do
        # Check if the file exists to avoid processing non-existent files
        if [ -f "$file" ]; then
            # Extract the filename without the extension
            filename="${file%.*}"
            folder_name="${directory}/${filename##*/}"

            # Create a directory with the filename
            echo "Creating directory: $folder_name"
            mkdir -p "$folder_name"

            # Move the video file into the directory
            echo "Moving file: $file -> $folder_name/"
            mv "$file" "$folder_name"

            # Move related files (like subtitles or artwork) into the same directory
            move_related_files "$filename" "$folder_name"
        fi
    done
done

echo "All files have been organized."
