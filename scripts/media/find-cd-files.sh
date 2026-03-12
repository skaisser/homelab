#!/bin/bash

# Check if a directory is provided as an argument
if [ $# -lt 1 ]; then
  echo "Usage: $0 <directory>"
  exit 1
fi

# Assign the provided directory to a variable
directory_to_search="$1"

echo "Searching for files containing 'CD1' to 'CD10' in their name..."

# Use a loop to search for files from CD1 to CD10
for i in {1..10}; do
  find "$directory_to_search" -type f -iname "*CD$i*" -print
done
