#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEST="$HOME/.claude"

echo "Installing claude-dotfiles..."

# Ensure jq is available (required by statusline-command.sh)
if ! command -v jq >/dev/null 2>&1; then
  echo "jq not found, installing..."
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get install -y jq
  elif command -v brew >/dev/null 2>&1; then
    brew install jq
  else
    echo "ERROR: Cannot install jq automatically. Please install it manually and re-run." >&2
    exit 1
  fi
fi

# Ensure destination exists
mkdir -p "$DEST"

# Copy config files (never overwrite credentials or local settings)
cp "$SCRIPT_DIR/settings.json" "$DEST/settings.json"
cp "$SCRIPT_DIR/statusline-command.sh" "$DEST/statusline-command.sh"
chmod +x "$DEST/statusline-command.sh"

echo "Done. Restart Claude Code to apply changes."
