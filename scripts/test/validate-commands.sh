#!/bin/bash
# Validates all commands/**/*.md have YAML frontmatter with a description field.

set -euo pipefail

COMMANDS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/commands"
FAILURES=0

while IFS= read -r -d '' file; do
  # Must start with ---
  if ! head -1 "$file" | grep -q '^---$'; then
    echo "FAIL (no frontmatter): $file"
    FAILURES=$((FAILURES + 1))
    continue
  fi

  # Must contain description:
  if ! awk '/^---$/{found++; if(found==2) exit} found==1{print}' "$file" | grep -q '^description:'; then
    echo "FAIL (missing description): $file"
    FAILURES=$((FAILURES + 1))
  fi
done < <(find "$COMMANDS_DIR" -name "*.md" -print0)

if [[ $FAILURES -eq 0 ]]; then
  echo "OK: all command files have valid frontmatter"
  exit 0
else
  echo "FAIL: $FAILURES file(s) failed validation"
  exit 1
fi
