#!/bin/bash
# ==============================================================================
# audit-video-folders.sh
#
# Finds folders containing multiple video files and reports:
#   - Folder path
#   - Number of video files
#   - Individual file names and sizes
#   - Total size of video files in the folder
#
# This is a read-only / safe operation -- nothing is modified.
#
# Consolidated from: count_videos_with_folders.sh, find_large_video_folders.sh
# ==============================================================================
set -euo pipefail

# --- Video extensions ---------------------------------------------------------
VIDEO_PATTERN='*.mp4 *.mkv *.avi *.mov *.flv *.wmv *.webm *.mpeg *.mpg *.m4v *.3gp *.ts *.m2ts'

is_video_file() {
    local file="$1"
    case "${file,,}" in
        *.mp4|*.mkv|*.avi|*.mov|*.flv|*.wmv|*.webm|*.mpeg|*.mpg|*.m4v|*.3gp|*.ts|*.m2ts)
            return 0 ;;
        *)
            return 1 ;;
    esac
}

# --- Human-readable size helper -----------------------------------------------
human_size() {
    local bytes="$1"
    if command -v numfmt &>/dev/null; then
        numfmt --to=iec --suffix=B "$bytes"
    else
        # Fallback: manual conversion
        if (( bytes >= 1073741824 )); then
            echo "$(( bytes / 1073741824 ))GiB"
        elif (( bytes >= 1048576 )); then
            echo "$(( bytes / 1048576 ))MiB"
        elif (( bytes >= 1024 )); then
            echo "$(( bytes / 1024 ))KiB"
        else
            echo "${bytes}B"
        fi
    fi
}

# --- File size in bytes (cross-platform) --------------------------------------
filesize() {
    if stat --version &>/dev/null 2>&1; then
        stat -c%s "$1"
    else
        stat -f%z "$1"
    fi
}

# --- Help ---------------------------------------------------------------------
usage() {
    cat <<EOF
Usage: $(basename "$0") <directory>

Find folders containing multiple video files and report details.

This is a read-only operation -- no files or folders are modified.

Supported video extensions:
  mp4, mkv, avi, mov, flv, wmv, webm, mpeg, mpg, m4v, 3gp, ts, m2ts

Arguments:
  directory   Path to the media directory to scan

Examples:
  $(basename "$0") /mnt/media/movies
  $(basename "$0") /srv/tv-shows
EOF
    exit 0
}

# --- Parse arguments ----------------------------------------------------------
if [[ $# -lt 1 ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    usage
fi

SEARCH_DIR="$1"

if [[ ! -d "$SEARCH_DIR" ]]; then
    echo "Error: Directory '$SEARCH_DIR' does not exist." >&2
    exit 1
fi

# --- Main logic ---------------------------------------------------------------
echo "Scanning for folders with multiple video files in '$SEARCH_DIR'..."
echo ""

folders_found=0

while IFS= read -r dir; do
    video_count=0
    total_size=0
    video_files=()

    for file in "$dir"/*; do
        [[ -f "$file" ]] || continue
        if is_video_file "$file"; then
            ((video_count++)) || true
            fsize=$(filesize "$file")
            total_size=$((total_size + fsize))
            video_files+=("$(basename "$file")|$fsize")
        fi
    done

    if (( video_count > 1 )); then
        ((folders_found++)) || true
        echo "Folder: $dir"
        echo "  Video files: $video_count"
        for entry in "${video_files[@]}"; do
            fname="${entry%%|*}"
            fsize="${entry##*|}"
            echo "    $fname  ($(human_size "$fsize"))"
        done
        echo "  Total size: $(human_size "$total_size")"
        echo "-------------------------------------"
    fi
done < <(find "$SEARCH_DIR" -type d)

echo ""
if [[ "$folders_found" -eq 0 ]]; then
    echo "No folders with multiple video files found."
else
    echo "Found $folders_found folder(s) with multiple video files."
fi

exit 0
