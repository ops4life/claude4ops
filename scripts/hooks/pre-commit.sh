#!/bin/bash
# Pre-commit hook: runs checks on staged files before allowing commit.
# Install: bash scripts/dev-setup.sh (or copy to .git/hooks/pre-commit)

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
STAGED=$(git diff --cached --name-only --diff-filter=ACM)

[[ -z "$STAGED" ]] && exit 0

FAILED=0

# --- shellcheck on staged shell scripts ---
SH_FILES=$(echo "$STAGED" | grep '\.sh$' || true)
if [[ -n "$SH_FILES" ]]; then
  if ! command -v shellcheck &>/dev/null; then
    echo "pre-commit: shellcheck not found — run scripts/dev-setup.sh" >&2
    exit 1
  fi
  echo "pre-commit: shellcheck..."
  while IFS= read -r f; do
    if ! shellcheck "$REPO_ROOT/$f"; then
      FAILED=1
    fi
  done <<< "$SH_FILES"
fi

# --- validate command frontmatter if any commands/**/*.md staged ---
CMD_FILES=$(echo "$STAGED" | grep '^commands/.*\.md$' || true)
if [[ -n "$CMD_FILES" ]]; then
  echo "pre-commit: validate command frontmatter..."
  if ! bash "$REPO_ROOT/scripts/test/validate-commands.sh"; then
    FAILED=1
  fi
fi

# --- JS tests if update-plugin-version.js touched ---
JS_CHANGED=$(echo "$STAGED" | grep 'update-plugin-version\.js$' || true)
if [[ -n "$JS_CHANGED" ]]; then
  if ! command -v node &>/dev/null; then
    echo "pre-commit: node not found — run scripts/dev-setup.sh" >&2
    exit 1
  fi
  echo "pre-commit: JS tests..."
  if ! node "$REPO_ROOT/scripts/test/test-update-plugin-version.js"; then
    FAILED=1
  fi
fi

if [[ $FAILED -ne 0 ]]; then
  echo "pre-commit: checks failed — commit aborted" >&2
  exit 1
fi

exit 0
