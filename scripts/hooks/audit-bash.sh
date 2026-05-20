#!/bin/bash
# PostToolUse hook: append every Bash command Claude runs to an audit log.

AUDIT_LOG="${CLAUDE_AUDIT_LOG:-${HOME}/.claude/audit.log}"
INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[[ -z "$CMD" ]] && exit 0

mkdir -p "$(dirname "$AUDIT_LOG")"
printf '%s [bash] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$(echo "$CMD" | head -c 300)" >> "$AUDIT_LOG"

exit 0
