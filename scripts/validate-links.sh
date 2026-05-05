#!/bin/bash
# validate-links.sh — Validate all [[wikilinks]] in the knowledge base
# Usage: scripts/validate-links.sh [path]

set -euo pipefail

BASE_DIR="${1:-.}"
BROKEN=0
WARNINGS=0

echo "=== Validating WikiLinks ==="

# Extract all [[links]] and validate targets exist
while IFS= read -r -d '' file; do
  relative_path=$(realpath --relative-to="$BASE_DIR" "$file")
  
  # Find [[wikilinks]] (match [[Something]] or [[Something|Display]]
  while IFS= read -r link; do
    # Extract the target (before | or ]])
    target=$(echo "$link" | sed -n 's/.*\[\[\([^]|]*\)\(|[^]]*\)\?\]\].*/\1/p')
    
    if [ -z "$target" ]; then
      continue
    fi

    # Try to find the target file
    found=$(find "$BASE_DIR" -name "${target}.md" -print -quit 2>/dev/null)
    
    if [ -z "$found" ]; then
      # Also try matching anchor: file#heading
      if echo "$target" | grep -q '#'; then
        file_part=$(echo "$target" | cut -d# -f1)
        heading_part=$(echo "$target" | cut -d# -f2)
        found=$(find "$BASE_DIR" -name "${file_part}.md" -print -quit 2>/dev/null)
        if [ -n "$found" ]; then
          # File exists, heading might not — soft warning
          WARNINGS=$((WARNINGS + 1))
          echo "  ⚠  HEADING CHECK: $relative_path → [[$target]]"
          continue
        fi
      fi

      BROKEN=$((BROKEN + 1))
      echo "  ✗ BROKEN: $relative_path → [[$target]]"
    fi
  done < <(grep -oP '\[\[\K[^]]+\]' "$file" | sed 's/\]$//' | sed 's/|.*$//') || true

done < <(find "$BASE_DIR" -name "*.md" -print0)

echo ""
echo "=== Summary ==="
echo "  Broken links: $BROKEN"
echo "  Heading warnings: $WARNINGS"

if [ "$BROKEN" -gt 0 ]; then
  echo "  STATUS: ISSUES FOUND"
  exit 1
else
  echo "  STATUS: ALL LINKS VALID ✓"
fi
