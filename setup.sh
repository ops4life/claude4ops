#!/bin/bash
# claudekit setup — installs Claude Code config, hooks, and MCP servers
# Usage: ./setup.sh [--all] [--settings] [--hooks] [--mcp] [--plugin]
#        ./setup.sh           (interactive menu)

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="${HOME}/.claude"
HOOKS_DIR="${CLAUDE_DIR}/hooks"
SETTINGS_FILE="${CLAUDE_DIR}/settings.json"

# ── colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { printf "${CYAN}▸ %s${RESET}\n" "$*"; }
ok()      { printf "${GREEN}✓ %s${RESET}\n" "$*"; }
warn()    { printf "${YELLOW}⚠ %s${RESET}\n" "$*"; }
err()     { printf "${RED}✗ %s${RESET}\n" "$*" >&2; }
header()  { printf "\n${BOLD}%s${RESET}\n" "$*"; }

# ── prereqs ───────────────────────────────────────────────────────────────────
check_prereqs() {
  local missing=()
  command -v jq >/dev/null || missing+=(jq)
  if [[ ${#missing[@]} -gt 0 ]]; then
    warn "Missing: ${missing[*]}"
    if command -v apt-get >/dev/null; then
      info "Installing via apt-get..."
      sudo apt-get install -y "${missing[@]}" -q
    elif command -v brew >/dev/null; then
      info "Installing via brew..."
      brew install "${missing[@]}"
    else
      err "Cannot auto-install ${missing[*]}. Install manually and re-run."
      exit 1
    fi
  fi
}

# ── settings.json merge ───────────────────────────────────────────────────────
# Merges $2 (JSON string or file path) into $1 file using deep merge.
# Existing keys not in $2 are preserved.
merge_settings() {
  local target="$1"
  local patch="$2"  # JSON string

  mkdir -p "$(dirname "$target")"

  if [[ -f "$target" ]]; then
    local merged
    merged=$(jq -s '.[0] * .[1]' "$target" <(echo "$patch"))
    echo "$merged" > "$target"
  else
    echo "$patch" | jq '.' > "$target"
  fi
}

# ── component: settings ───────────────────────────────────────────────────────
install_settings() {
  header "Base Settings + Status Line"

  mkdir -p "$CLAUDE_DIR"

  # Copy statusline script
  cp "$REPO_DIR/scripts/statusline-command.sh" "$CLAUDE_DIR/statusline-command.sh"
  chmod +x "$CLAUDE_DIR/statusline-command.sh"
  ok "statusline-command.sh → ${CLAUDE_DIR}/"

  # Merge base settings
  local base
  base=$(cat "$REPO_DIR/settings.json")
  merge_settings "$SETTINGS_FILE" "$base"
  ok "settings merged → ${SETTINGS_FILE}"
}

# ── component: hooks ──────────────────────────────────────────────────────────
install_hooks() {
  header "Claude Code Hooks"

  mkdir -p "$HOOKS_DIR"

  local hooks_config='{"hooks":{}}'
  local installed=()

  # block-prod (PreToolUse)
  if ask "  Install block-prod hook? (blocks kubectl/terraform/aws commands targeting prod)"; then
    cp "$REPO_DIR/scripts/hooks/block-prod.sh" "$HOOKS_DIR/block-prod.sh"
    chmod +x "$HOOKS_DIR/block-prod.sh"
    hooks_config=$(echo "$hooks_config" | jq '.hooks.PreToolUse = [{
      "matcher": "Bash",
      "hooks": [{"type": "command", "command": "~/.claude/hooks/block-prod.sh"}]
    }]')
    installed+=(block-prod)
    ok "block-prod.sh installed"
  fi

  # auto-lint (Stop)
  if ask "  Install auto-lint hook? (lint/format changed files after each Claude turn)"; then
    cp "$REPO_DIR/scripts/hooks/auto-lint.sh" "$HOOKS_DIR/auto-lint.sh"
    chmod +x "$HOOKS_DIR/auto-lint.sh"
    hooks_config=$(echo "$hooks_config" | jq '.hooks.Stop = [{
      "hooks": [{"type": "command", "command": "~/.claude/hooks/auto-lint.sh"}]
    }]')
    installed+=(auto-lint)
    ok "auto-lint.sh installed"
  fi

  # audit-bash (PostToolUse)
  if ask "  Install audit hook? (log all Bash commands to ~/.claude/audit.log)"; then
    cp "$REPO_DIR/scripts/hooks/audit-bash.sh" "$HOOKS_DIR/audit-bash.sh"
    chmod +x "$HOOKS_DIR/audit-bash.sh"
    hooks_config=$(echo "$hooks_config" | jq '.hooks.PostToolUse = [{
      "matcher": "Bash",
      "hooks": [{"type": "command", "command": "~/.claude/hooks/audit-bash.sh"}]
    }]')
    installed+=(audit)
    ok "audit-bash.sh installed"
  fi

  # slack-notify (Notification)
  if ask "  Install Slack notification hook? (requires SLACK_WEBHOOK env var)"; then
    cp "$REPO_DIR/scripts/hooks/slack-notify.sh" "$HOOKS_DIR/slack-notify.sh"
    chmod +x "$HOOKS_DIR/slack-notify.sh"
    hooks_config=$(echo "$hooks_config" | jq '.hooks.Notification = [{
      "hooks": [{"type": "command", "command": "~/.claude/hooks/slack-notify.sh"}]
    }]')
    installed+=(slack)
    ok "slack-notify.sh installed"

    if [[ -z "${SLACK_WEBHOOK:-}" ]]; then
      warn "SLACK_WEBHOOK not set. Add to your shell profile: export SLACK_WEBHOOK=https://hooks.slack.com/..."
    fi
  fi

  if [[ ${#installed[@]} -gt 0 ]]; then
    merge_settings "$SETTINGS_FILE" "$hooks_config"
    ok "hooks wired in ${SETTINGS_FILE}"
  else
    warn "No hooks selected"
  fi
}

# ── component: MCP servers ────────────────────────────────────────────────────
install_mcp() {
  header "MCP Servers (real API access for AWS, Kubernetes, GitHub)"

  local mcp_config='{"mcpServers":{}}'
  local installed=()

  if ask "  Add AWS MCP server?"; then
    local profile region
    if [[ $AUTO_YES -eq 0 ]]; then
      printf "    AWS profile name [dev]: "; read -r profile
      printf "    AWS region [us-east-1]: "; read -r region
    fi
    profile="${profile:-dev}"
    region="${region:-us-east-1}"

    mcp_config=$(echo "$mcp_config" | jq --arg p "$profile" --arg r "$region" \
      '.mcpServers.aws = {
        "command": "uvx",
        "args": ["awslabs.aws-mcp-server"],
        "env": {"AWS_PROFILE": $p, "AWS_REGION": $r}
      }')
    installed+=(aws)
    ok "AWS MCP configured (profile: ${profile}, region: ${region})"

    if ! command -v uvx >/dev/null 2>&1; then
      warn "uvx not found. Install with: pip install uv"
    fi
  fi

  if ask "  Add Kubernetes MCP server?"; then
    local kubeconfig
    if [[ $AUTO_YES -eq 0 ]]; then
      printf "    Kubeconfig path [~/.kube/config]: "; read -r kubeconfig
    fi
    kubeconfig="${kubeconfig:-~/.kube/config}"

    mcp_config=$(echo "$mcp_config" | jq --arg k "$kubeconfig" \
      '.mcpServers.kubernetes = {
        "command": "npx",
        "args": ["mcp-server-kubernetes"],
        "env": {"KUBECONFIG": $k}
      }')
    installed+=(kubernetes)
    ok "Kubernetes MCP configured (kubeconfig: ${kubeconfig})"
  fi

  if ask "  Add GitHub MCP server?"; then
    local token_var
    if [[ $AUTO_YES -eq 0 ]]; then
      printf "    Token env var name [GITHUB_TOKEN]: "; read -r token_var
    fi
    token_var="${token_var:-GITHUB_TOKEN}"

    mcp_config=$(echo "$mcp_config" | jq --arg t "\${${token_var}}" \
      '.mcpServers.github = {
        "command": "npx",
        "args": ["@modelcontextprotocol/server-github"],
        "env": {"GITHUB_PERSONAL_ACCESS_TOKEN": $t}
      }')
    installed+=(github)
    ok "GitHub MCP configured (token: \$${token_var})"

    if [[ -z "${!token_var:-}" ]] 2>/dev/null; then
      warn "${token_var} not set in current shell"
    fi
  fi

  if [[ ${#installed[@]} -gt 0 ]]; then
    merge_settings "$SETTINGS_FILE" "$mcp_config"
    ok "MCP servers written to ${SETTINGS_FILE}"
  else
    warn "No MCP servers selected"
  fi
}

# ── component: plugin ─────────────────────────────────────────────────────────
install_plugin() {
  header "claudekit Plugin"

  local plugin_config='{
    "enabledPlugins": {"claudekit@ops4life": true},
    "extraKnownMarketplaces": {
      "ops4life": {
        "source": {"source": "github", "repo": "ops4life/claudekit"}
      }
    }
  }'
  merge_settings "$SETTINGS_FILE" "$plugin_config"
  ok "claudekit plugin registered in ${SETTINGS_FILE}"
  info "Restart Claude Code then run: /plugin install claudekit"
}

# ── prompt helper ─────────────────────────────────────────────────────────────
# In non-interactive (--all) mode, $AUTO_YES is set; all asks return 0.
AUTO_YES=0
ask() {
  local prompt="$1"
  if [[ $AUTO_YES -eq 1 ]]; then
    printf "${CYAN}▸ %s${RESET} ${GREEN}[auto: yes]${RESET}\n" "$prompt"
    return 0
  fi
  printf "${CYAN}▸ %s${RESET} [y/N] " "$prompt"
  local ans
  read -r ans
  [[ "${ans,,}" == "y" || "${ans,,}" == "yes" ]]
}

# ── interactive menu ──────────────────────────────────────────────────────────
interactive_menu() {
  printf "\n${BOLD}claudekit setup${RESET}\n"
  printf "Installs Claude Code config into %s\n\n" "$CLAUDE_DIR"

  local do_settings=0 do_hooks=0 do_mcp=0 do_plugin=0

  printf "Select components to install:\n\n"
  ask "1. Base settings + status line (settings.json, statusline-command.sh)" && do_settings=1
  ask "2. Claude Code hooks (block-prod, auto-lint, audit, Slack)"            && do_hooks=1
  ask "3. MCP servers (AWS, Kubernetes, GitHub)"                               && do_mcp=1
  ask "4. claudekit plugin registration"                                        && do_plugin=1

  [[ $do_settings -eq 1 ]] && install_settings
  [[ $do_hooks    -eq 1 ]] && install_hooks
  [[ $do_mcp      -eq 1 ]] && install_mcp
  [[ $do_plugin   -eq 1 ]] && install_plugin
}

# ── main ──────────────────────────────────────────────────────────────────────
main() {
  check_prereqs

  if [[ $# -eq 0 ]]; then
    interactive_menu
  else
    local do_settings=0 do_hooks=0 do_mcp=0 do_plugin=0

    for arg in "$@"; do
      case "$arg" in
        --all)      AUTO_YES=1; do_settings=1; do_hooks=1; do_mcp=1; do_plugin=1 ;;
        --settings) do_settings=1 ;;
        --hooks)    do_hooks=1 ;;
        --mcp)      do_mcp=1 ;;
        --plugin)   do_plugin=1 ;;
        --help|-h)
          printf "Usage: %s [--all] [--settings] [--hooks] [--mcp] [--plugin]\n" "$0"
          printf "       %s          (interactive menu)\n" "$0"
          exit 0
          ;;
        *)
          err "Unknown option: $arg"
          exit 1
          ;;
      esac
    done

    [[ $do_settings -eq 1 ]] && install_settings
    [[ $do_hooks    -eq 1 ]] && install_hooks
    [[ $do_mcp      -eq 1 ]] && install_mcp
    [[ $do_plugin   -eq 1 ]] && install_plugin
  fi

  printf "\n${GREEN}${BOLD}Setup complete.${RESET} Restart Claude Code to apply changes.\n\n"
}

main "$@"
