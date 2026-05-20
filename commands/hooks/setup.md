---
description: Configure Claude Code hooks - auto-lint, prod guards, audit logging, Slack alerts
---

# Hooks Setup - Claude Code Lifecycle Automation

Set up Claude Code hooks that fire at specific lifecycle points: before tool calls, after tool calls, on notifications, and when Claude's turn ends. Use hooks to enforce guardrails, auto-format, audit, and alert.

## Requirements

**User must provide:**
- Which hooks to enable (see options below)
- Paths to write hook scripts
- Any environment-specific values (Slack webhook, audit log path, prod patterns)

## Hook Types

| Hook | Fires | Use For |
|------|-------|---------|
| `PreToolUse` | Before each tool call | Block dangerous commands, validate inputs |
| `PostToolUse` | After each tool call | Audit logging, downstream triggers |
| `Notification` | When Claude needs attention | Slack/PagerDuty alerts |
| `Stop` | End of each Claude turn | Auto-lint, auto-format, run tests |

## Exit Codes for PreToolUse

- `0` — allow the action
- `1` — non-blocking error (log and continue)
- `2` — **block the action** and surface stderr message to Claude

## Hook 1: Block Production Targets (PreToolUse)

Creates a guard that intercepts all Bash tool calls and blocks any command targeting production resources.

**Script: `~/.claude/hooks/block-prod.sh`**

```bash
#!/bin/bash
# Blocks Claude from touching prod resources. exit 2 = block + message to Claude.

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

[[ -z "$CMD" ]] && exit 0

DANGER_PATTERNS=(
  "kubectl.*--context=prod"
  "terraform.*-var-file=prod"
  "aws.*--profile=production"
  "helm.*prod"
  "kubectl.*-n production"
)

for pattern in "${DANGER_PATTERNS[@]}"; do
  if echo "$CMD" | grep -qE "$pattern"; then
    echo "BLOCKED: prod target detected in command. Run this manually with explicit approval." >&2
    exit 2
  fi
done
exit 0
```

## Hook 2: Auto-Lint and Format (Stop)

Runs after every Claude turn. Lints and formats every file Claude touched so output is always clean.

**Script: `~/.claude/hooks/auto-lint.sh`**

```bash
#!/bin/bash
# Runs after every Claude turn. Lints + formats changed files.

CHANGED=$(git diff --name-only HEAD 2>/dev/null)
[[ -z "$CHANGED" ]] && exit 0

for f in $CHANGED; do
  case "$f" in
    *.py)        ruff check --fix "$f" && black "$f" ;;
    *.tf)        terraform fmt "$f" ;;
    *.go)        gofmt -w "$f" ;;
    *.yaml|*.yml) yamllint "$f" 2>/dev/null || true ;;
    *.ts|*.js)   npx eslint --fix "$f" 2>/dev/null || true ;;
  esac
done

# Notify if formatting changed anything
if ! git diff --quiet; then
  CHANGED_COUNT=$(git diff --name-only | wc -l | tr -d ' ')
  echo "Auto-formatted $CHANGED_COUNT file(s)"
fi
```

## Hook 3: Audit Log (PostToolUse)

Logs every Bash command Claude runs to a local audit file for compliance or debugging.

**Script: `~/.claude/hooks/audit-bash.sh`**

```bash
#!/bin/bash
# Appends every Bash tool call to an audit log.

AUDIT_LOG="${CLAUDE_AUDIT_LOG:-$HOME/.claude/audit.log}"
INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[[ -z "$CMD" ]] && exit 0

echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) [bash] $(echo "$CMD" | head -c 200)" >> "$AUDIT_LOG"
exit 0
```

## Hook 4: Slack Notifications (Notification)

Sends a Slack message whenever Claude needs attention (long-running task, needs input, etc.).

**Script: `~/.claude/hooks/slack-notify.sh`**

```bash
#!/bin/bash
# Posts Claude notifications to Slack.

INPUT=$(cat)
MSG=$(echo "$INPUT" | jq -r '.message // "Claude needs attention"')

[[ -z "$SLACK_WEBHOOK" ]] && exit 0

curl -s -X POST "$SLACK_WEBHOOK" \
  -H 'Content-type: application/json' \
  -d "{\"text\": \":robot_face: Claude Code: $MSG\"}" \
  > /dev/null
exit 0
```

## Wiring Hooks in `.claude/settings.json`

Create or update `.claude/settings.json` in your project root:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{
          "type": "command",
          "command": "~/.claude/hooks/block-prod.sh"
        }]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{
          "type": "command",
          "command": "~/.claude/hooks/audit-bash.sh"
        }]
      }
    ],
    "Notification": [{
      "hooks": [{
        "type": "command",
        "command": "~/.claude/hooks/slack-notify.sh"
      }]
    }],
    "Stop": [{
      "hooks": [{
        "type": "command",
        "command": "~/.claude/hooks/auto-lint.sh"
      }]
    }]
  }
}
```

## Setup Steps

1. Create hook directory: `mkdir -p ~/.claude/hooks`
2. Write each hook script from the templates above
3. Make executable: `chmod +x ~/.claude/hooks/*.sh`
4. Create `.claude/settings.json` with the wiring above
5. Set env vars: `export SLACK_WEBHOOK=...` (add to shell profile)
6. Test PreToolUse guard: run a command with `--context=prod` and confirm it blocks

## Global vs Project Hooks

- **Project hooks** (`.claude/settings.json`): committed to repo, shared with team
- **Global hooks** (`~/.claude/settings.json`): apply to all Claude Code sessions on this machine

Project hooks override global hooks for the same event type.

## Best Practices

- Always use `exit 2` (not `exit 1`) when you want PreToolUse to visibly block Claude
- Keep hook scripts fast — they run on every tool call
- Log prod-block events to the audit log for compliance
- Scope the Bash `matcher` tightly — you can also match `Write`, `Edit`, `Read` tool names
- Test hooks with `echo '{"tool_input":{"command":"kubectl --context=prod get pods"}}' | ~/.claude/hooks/block-prod.sh`
