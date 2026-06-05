#!/bin/bash
# Dev setup: installs required tools and wires the pre-commit hook.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok()   { echo -e "${GREEN}  ok${NC}  $*"; }
warn() { echo -e "${YELLOW}  --${NC}  $*"; }
fail() { echo -e "${RED}  !!${NC}  $*"; }

detect_os() {
  case "$(uname -s 2>/dev/null)" in
    Darwin*) echo "macos" ;;
    Linux*)
      if grep -qi microsoft /proc/version 2>/dev/null; then
        echo "wsl"
      elif [[ -f /etc/debian_version ]]; then
        echo "debian"
      elif [[ -f /etc/redhat-release ]]; then
        echo "redhat"
      else
        echo "linux"
      fi ;;
    MINGW*|MSYS*|CYGWIN*) echo "gitbash" ;;
    *) echo "unknown" ;;
  esac
}

install_pkg() {
  local tool="$1"
  local os
  os=$(detect_os)
  case "$os" in
    macos)
      if command -v brew &>/dev/null; then
        brew install "$tool"
      else
        fail "brew not found — install Homebrew first: https://brew.sh"
        return 1
      fi
      ;;
    debian)
      sudo apt-get update -qq && sudo apt-get install -y "$tool"
      ;;
    redhat)
      sudo dnf install -y "$tool" 2>/dev/null || sudo yum install -y "$tool"
      ;;
    *)
      fail "unknown OS — install $tool manually"
      return 1
      ;;
  esac
}

echo ""
echo "claude4ops dev setup"
echo "==================="
echo ""

# --- Check / install tools ---
MISSING=0

check_tool() {
  local cmd="$1"
  local pkg="${2:-$1}"
  local install="${3:-true}"

  if command -v "$cmd" &>/dev/null; then
    ok "$cmd $(command -v "$cmd")"
  elif [[ "$install" == "true" ]]; then
    warn "$cmd not found — installing..."
    if install_pkg "$pkg"; then
      ok "$cmd installed"
    else
      fail "$cmd install failed"
      MISSING=$((MISSING + 1))
    fi
  else
    fail "$cmd not found — install manually"
    MISSING=$((MISSING + 1))
  fi
}

check_tool shellcheck
check_tool node nodejs
check_tool jq
check_tool git git false

echo ""

# --- Install pre-commit hook ---
HOOK_SRC="$REPO_ROOT/scripts/hooks/pre-commit.sh"
HOOK_DST="$REPO_ROOT/.git/hooks/pre-commit"

if [[ ! -d "$REPO_ROOT/.git" ]]; then
  warn ".git not found — skipping hook install (not a git repo?)"
else
  if [[ -f "$HOOK_DST" ]] && ! grep -q "pre-commit.sh" "$HOOK_DST" 2>/dev/null; then
    warn "pre-commit hook already exists (not from claude4ops) — skipping"
  else
    cp "$HOOK_SRC" "$HOOK_DST"
    chmod +x "$HOOK_DST"
    ok "pre-commit hook installed at .git/hooks/pre-commit"
  fi
fi

echo ""

if [[ $MISSING -gt 0 ]]; then
  fail "$MISSING required tool(s) missing — fix above errors and re-run"
  exit 1
else
  ok "all tools ready"
fi
