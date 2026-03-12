#!/bin/bash
# ==============================================================================
# audit-tmdb-naming.sh
#
# Audits a media directory for folders that contain "tmdb-" in their name but
# do NOT use the proper "{tmdb-XXXXX}" brace format. Reports each folder's name
# and size, plus a total count.
#
# This is a read-only / safe operation -- nothing is modified.
#
# Consolidated from: check_tmdb_braces.sh, size_checker.sh
# ==============================================================================
set -euo pipefail

# --- Help ---------------------------------------------------------------------
usage() {
    cat <<EOF
Usage: $(basename "$0") <directory>

Audit a media directory for folders with incorrect TMDB naming.
Finds directories containing "tmdb-" but missing the required braces "{tmdb-}".

This is a read-only operation -- no files or folders are modified.

Arguments:
  directory   Path to the media directory to audit

Examples:
  $(basename "$0") /mnt/media/movies
  $(basename "$0") /srv/movies
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
echo "Auditing TMDB naming in '$SEARCH_DIR'..."
echo ""

# Use process substitution to avoid subshell scoping issues with counters
found=0
total_size_bytes=0

# Detect du flags (GNU vs BSD)
if du --version &>/dev/null 2>&1; then
    du_bytes_flag="-sb"
else
    # macOS/BSD -- -sk gives KB, there's no -b; use -s and parse
    du_bytes_flag="-sk"
fi

while IFS= read -r dir; do
    # Filter: has "tmdb-" but NOT "{tmdb-"
    dir_name=$(basename "$dir")
    if [[ "$dir_name" == *"tmdb-"* ]] && [[ "$dir_name" != *"{tmdb-"* ]]; then
        size_hr=$(du -sh "$dir" 2>/dev/null | cut -f1)
        echo "  $dir_name  ($size_hr)"
        ((found++)) || true
    fi
done < <(find "$SEARCH_DIR" -maxdepth 1 -type d -not -path "$SEARCH_DIR")

echo ""
if [[ "$found" -eq 0 ]]; then
    echo "All folders use the correct '{tmdb-}' format. No issues found."
else
    echo "Found $found folder(s) with incorrect TMDB naming (missing braces)."
fi

exit 0
