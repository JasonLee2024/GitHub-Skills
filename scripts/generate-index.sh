#!/bin/bash
# generate-index.sh — Auto-generate _index.md for each chapter
# Usage: scripts/generate-index.sh [path]

set -euo pipefail

BASE_DIR="${1:-.}"

echo "=== Generating Index Files ==="

# Find all directories with .md files but no _index.md
find "$BASE_DIR" -type d | while read -r dir; do
  md_files=$(find "$dir" -maxdepth 1 -name "*.md" ! -name "_index.md" ! -name "README.md" | sort)
  index_file="$dir/_index.md"

  if [ -n "$md_files" ] && [ ! -f "$index_file" ]; then
    dirname=$(basename "$dir")
    echo "Missing _index.md in: $dir"
    cat > "$index_file" << EOF
# $dirname

## Pages

EOF
    echo "$md_files" | while read -r f; do
      basename=$(basename "$f" .md)
      echo "- [[$basename]]"
    done >> "$index_file"
    echo "  → Created _index.md"
  fi
done

echo "=== Done ==="
