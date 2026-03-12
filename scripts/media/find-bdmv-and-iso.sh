#!/bin/bash

# Check if the path is provided as an argument
if [ -z "$1" ]; then
  echo "Usage: $0 <path_to_search>"
  exit 1
fi

# Define the path to search
SEARCH_PATH=$1

# Function to calculate and display folder size, path, and file type
find_folders_with_bdmv_or_iso() {
  # Find directories containing BDMV or .iso files more efficiently
  find "$SEARCH_PATH" \( -iname "BDMV" -o -iname "*.iso" \) -printf "%h\n" | sort -u | while read -r dir; do
    # Determine file type 
    file_type=""
    [ -d "$dir/BDMV" ] && file_type="BDMV"
    [ "$(find "$dir" -maxdepth 1 -iname "*.iso")" ] && file_type="${file_type} ISO"

    # Calculate the size of the folder
    folder_size=$(du -sh "$dir" | cut -f1)

    # Display the full path, size, and file type
    echo "Folder: $dir | Size: $folder_size | Contains: $file_type"
  done
}

# Call the function
find_folders_with_bdmv_or_iso
