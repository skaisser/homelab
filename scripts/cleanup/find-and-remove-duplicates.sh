#!/bin/bash
# ==============================================================================
# find-and-remove-duplicates.sh
#
# Finds duplicate files within a directory tree using MD5 checksums.
# Supports two modes:
#   --keep-largest  (default): keeps the largest file among duplicates
#   --keep-first:              keeps the first occurrence found
#
# Supports --dry-run to report duplicates without deleting anything.
#
# Consolidated from: cleanup_script.sh, delete_duplicates.sh
# ==============================================================================
set -euo pipefail

# --- Defaults -----------------------------------------------------------------
MODE="keep-largest"
DRY_RUN=false
TARGET_DIR=""

# --- Help ---------------------------------------------------------------------
usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] <directory>

Find and remove duplicate files using MD5 checksums.

Options:
  --keep-largest   Keep the largest file among duplicates (default)
  --keep-first     Keep the first occurrence found
  --dry-run        Report duplicates without deleting anything
  -h, --help       Show this help message

Examples:
  $(basename "$0") /path/to/dir
  $(basename "$0") --keep-first --dry-run /path/to/dir
EOF
    exit 0
}

# --- Parse arguments ----------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --keep-largest) MODE="keep-largest"; shift ;;
        --keep-first)   MODE="keep-first"; shift ;;
        --dry-run)      DRY_RUN=true; shift ;;
        -h|--help)      usage ;;
        -*)             echo "Error: Unknown option '$1'" >&2; usage ;;
        *)
            if [[ -z "$TARGET_DIR" ]]; then
                TARGET_DIR="$1"
            else
                echo "Error: Unexpected argument '$1'" >&2
                usage
            fi
            shift
            ;;
    esac
done

if [[ -z "$TARGET_DIR" ]]; then
    echo "Error: Directory path is required." >&2
    usage
fi

if [[ ! -d "$TARGET_DIR" ]]; then
    echo "Error: Directory '$TARGET_DIR' does not exist." >&2
    exit 1
fi

# --- Detect md5 command -------------------------------------------------------
if command -v md5sum &>/dev/null; then
    md5cmd() { md5sum "$1" | awk '{print $1}'; }
elif command -v md5 &>/dev/null; then
    md5cmd() { md5 -q "$1"; }
else
    echo "Error: Neither md5sum nor md5 found." >&2
    exit 1
fi

# --- Detect stat for file size ------------------------------------------------
if stat --version &>/dev/null 2>&1; then
    # GNU stat
    filesize() { stat -c%s "$1"; }
else
    # BSD stat (macOS)
    filesize() { stat -f%z "$1"; }
fi

# --- Main logic ---------------------------------------------------------------
echo "Searching for duplicate files in '$TARGET_DIR' (mode: $MODE, dry-run: $DRY_RUN)..."

# Use a temp file to avoid subshell variable scoping issues with pipes
tmp_filelist=$(mktemp)
trap 'rm -f "$tmp_filelist"' EXIT

find "$TARGET_DIR" -type f > "$tmp_filelist"

total_files=$(wc -l < "$tmp_filelist")
processed=0
deleted=0

declare -A file_hashes
declare -A file_sizes

while IFS= read -r file; do
    ((processed++)) || true

    checksum=$(md5cmd "$file")
    file_size=$(filesize "$file")

    if [[ -n "${file_hashes[$checksum]:-}" ]]; then
        # Duplicate found
        if [[ "$MODE" == "keep-first" ]]; then
            echo "Duplicate: '$file' (of '${file_hashes[$checksum]}')"
            if [[ "$DRY_RUN" == false ]]; then
                rm -f "$file"
                echo "  -> Deleted: '$file'"
            else
                echo "  -> Would delete: '$file'"
            fi
            ((deleted++)) || true
        else
            # keep-largest
            existing_size="${file_sizes[$checksum]}"
            if [[ "$file_size" -gt "$existing_size" ]]; then
                echo "Duplicate pair: '$file' (${file_size}B) vs '${file_hashes[$checksum]}' (${existing_size}B)"
                if [[ "$DRY_RUN" == false ]]; then
                    rm -f "${file_hashes[$checksum]}"
                    echo "  -> Deleted smaller: '${file_hashes[$checksum]}'"
                else
                    echo "  -> Would delete smaller: '${file_hashes[$checksum]}'"
                fi
                file_hashes["$checksum"]="$file"
                file_sizes["$checksum"]="$file_size"
            else
                echo "Duplicate pair: '$file' (${file_size}B) vs '${file_hashes[$checksum]}' (${existing_size}B)"
                if [[ "$DRY_RUN" == false ]]; then
                    rm -f "$file"
                    echo "  -> Deleted smaller: '$file'"
                else
                    echo "  -> Would delete smaller: '$file'"
                fi
            fi
            ((deleted++)) || true
        fi
    else
        file_hashes["$checksum"]="$file"
        file_sizes["$checksum"]="$file_size"
    fi

    if (( processed % 100 == 0 )); then
        echo "Progress: $processed / $total_files files processed..."
    fi
done < "$tmp_filelist"

echo ""
echo "Done. Processed $processed files, found $deleted duplicate(s)."
if [[ "$DRY_RUN" == true && "$deleted" -gt 0 ]]; then
    echo "(Dry run -- no files were deleted.)"
fi
