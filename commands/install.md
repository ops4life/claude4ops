---
description: Install claudekit hooks, skills, rules, and settings — user or project scope
---

# claudekit Install

Interactive agentic install. Follow each step in order. Run bash commands exactly as shown.

---

## Step 1 — Prerequisites

```bash
command -v jq >/dev/null 2>&1 || echo "MISSING_JQ"
```

If output is `MISSING_JQ`, stop and tell the user:
> `jq` is required. Install it with `apt-get install jq` or `brew install jq`, then re-run `/claudekit:install`.

---

## Step 2 — Scope

Ask the user:

> **Where should claudekit be installed?**
> - `u` — **User** → `~/.claude/` (applies to all projects on this machine)
> - `p` — **Project** → `.claude/` in the current directory (repo-local, committable to git)

Store the answer. All paths below use `$BASE`:
- User → `BASE="$HOME/.claude"`
- Project → `BASE=".claude"`

```bash
mkdir -p "$BASE"
```

---

## Step 3 — Component Selection

Present the following checklist and ask the user to enter numbers and/or `a`:

```
Which components do you want to install? (select all that apply)

  1. Settings  — settings.json merge + status line script
  2. Hooks     — lifecycle hooks (block-prod, auto-lint, audit, Slack)
  3. MCP       — AWS, Kubernetes, GitHub real API access
  4. Skills    — docling (PDF/DOCX/image → Markdown)
  5. Rules        — git workflow rules
  6. Optimization — RTK (token-efficient shell proxy) + Caveman mode plugin
  a. All

Enter numbers and/or 'a', separated by spaces (e.g. 1 3 5 or a):
```

- Input includes `a` → select all 6 components; Optimization sub-selection still shown (only 2 tools, quick)
- Input is numbers → select only those components
- Invalid input → re-prompt

Record selections, then install all at once in Step 4.

---

## Step 4 — Install

### Settings

```bash
mkdir -p "$BASE"
```

**User scope only** — write the statusline script:

```bash
cat > "$HOME/.claude/statusline-command.sh" << 'STATUSLINE'
#!/bin/sh
input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name')
five=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

make_bar() {
  pct="$1"
  filled=$(awk "BEGIN { x = int($pct / 10 + 0.5); if (x > 10) x = 10; print x }")
  empty=$((10 - filled))
  bar=""
  i=0
  while [ "$i" -lt "$filled" ]; do bar="${bar}▓"; i=$((i + 1)); done
  while [ "$i" -lt 10 ]; do bar="${bar}░"; i=$((i + 1)); done
  printf "%s" "$bar"
}

five_resets=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
if [ -n "$five" ]; then
  five_pct=$(printf "%.0f" "$five")
  if [ -n "$five_resets" ]; then
    reset_time=$(TZ=Asia/Bangkok date -d "@${five_resets}" +%H:%M 2>/dev/null || TZ=Asia/Bangkok date -r "$five_resets" +%H:%M 2>/dev/null)
    five_display="5h:$(make_bar "$five") ${five_pct}% (resets ${reset_time})"
  else
    five_display="5h:$(make_bar "$five") ${five_pct}%"
  fi
else
  five_display=""
fi

if [ -n "$week" ]; then
  week_pct=$(printf "%.0f" "$week")
  week_display="7d:$(make_bar "$week") ${week_pct}%"
else
  week_display=""
fi

parts="$model"
[ -n "$five_display" ] && parts="$parts | $five_display"
[ -n "$week_display" ] && parts="$parts  $week_display"

printf "%s" "$parts"
STATUSLINE
chmod +x "$HOME/.claude/statusline-command.sh"
```

Skip the statusline block for project scope.

**Merge base settings** into `$BASE/settings.json`:

```bash
PATCH=$(cat << 'JSON'
{
  "statusLine": {"type": "command", "command": "bash ~/.claude/statusline-command.sh"},
  "permissions": {
    "defaultMode": "acceptEdits",
    "allow": [
      "Read", "Glob", "Grep",
      "Bash(git:*)", "Bash(docker:*)", "Bash(docker compose:*)",
      "Bash(curl:*)", "Bash(ls:*)", "Bash(cat:*)", "Bash(jq:*)"
    ]
  }
}
JSON
)
if [ -f "$BASE/settings.json" ]; then
  jq -s '.[0] * .[1]' "$BASE/settings.json" <(echo "$PATCH") > /tmp/ck_settings.json \
    && mv /tmp/ck_settings.json "$BASE/settings.json"
else
  echo "$PATCH" | jq '.' > "$BASE/settings.json"
fi
```

For project scope, omit `statusLine` from the patch (it references `~/.claude/` which is user-specific).

---

### Hooks

```bash
mkdir -p "$BASE/hooks"
```

If Hooks was selected via `a` at Step 3, skip this sub-selection and install all 4 hooks. Otherwise present:

```
Which hooks? (select all that apply)
  1. block-prod   — PreToolUse: blocks prod-targeting commands
  2. auto-lint    — Stop: formats files Claude touched after each turn
  3. audit-bash   — PostToolUse: logs all Bash commands
  4. slack-notify — Notification: posts Claude alerts to Slack
  a. All

Enter numbers and/or 'a':
```

For each selected hook, write the script and append to a hooks config.

#### block-prod (PreToolUse — blocks prod-targeting commands)

```bash
cat > "$BASE/hooks/block-prod.sh" << 'HOOK'
#!/bin/bash
INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[[ -z "$CMD" ]] && exit 0

DANGER_PATTERNS=(
  "kubectl.*--context=prod"
  "kubectl.*-n production"
  "kubectl.*--namespace=production"
  "terraform.*-var-file=prod"
  "terraform.*workspace.*prod"
  "aws.*--profile=production"
  "aws.*--profile=prod"
  "helm.*prod"
  "gcloud.*--project=.*-prod"
)

for pattern in "${DANGER_PATTERNS[@]}"; do
  if echo "$CMD" | grep -qE "$pattern"; then
    echo "BLOCKED: production target detected. Run this manually with explicit approval." >&2
    exit 2
  fi
done
exit 0
HOOK
chmod +x "$BASE/hooks/block-prod.sh"
```

Settings entry for block-prod:
```json
"PreToolUse": [{"matcher": "Bash", "hooks": [{"type": "command", "command": "$BASE/hooks/block-prod.sh"}]}]
```

#### auto-lint (Stop — formats files Claude touched after each turn)

```bash
cat > "$BASE/hooks/auto-lint.sh" << 'HOOK'
#!/bin/bash
CHANGED=$(git diff --name-only HEAD 2>/dev/null)
[[ -z "$CHANGED" ]] && exit 0

FORMATTED=0
for f in $CHANGED; do
  [[ -f "$f" ]] || continue
  case "$f" in
    *.py)
      command -v ruff >/dev/null && ruff check --fix "$f" 2>/dev/null
      command -v black >/dev/null && black -q "$f" 2>/dev/null
      FORMATTED=$((FORMATTED + 1)) ;;
    *.tf)
      command -v terraform >/dev/null && terraform fmt "$f" 2>/dev/null
      FORMATTED=$((FORMATTED + 1)) ;;
    *.go)
      command -v gofmt >/dev/null && gofmt -w "$f" 2>/dev/null
      FORMATTED=$((FORMATTED + 1)) ;;
    *.ts|*.js|*.tsx|*.jsx)
      command -v npx >/dev/null && npx --yes eslint --fix "$f" 2>/dev/null
      FORMATTED=$((FORMATTED + 1)) ;;
    *.yaml|*.yml)
      command -v yamllint >/dev/null && yamllint -d relaxed "$f" 2>/dev/null || true ;;
  esac
done

if ! git diff --quiet 2>/dev/null && [[ $FORMATTED -gt 0 ]]; then
  COUNT=$(git diff --name-only | wc -l | tr -d ' ')
  echo "auto-lint: formatted ${COUNT} file(s)"
fi
exit 0
HOOK
chmod +x "$BASE/hooks/auto-lint.sh"
```

Settings entry for auto-lint:
```json
"Stop": [{"hooks": [{"type": "command", "command": "$BASE/hooks/auto-lint.sh"}]}]
```

#### audit-bash (PostToolUse — logs all Bash commands)

```bash
cat > "$BASE/hooks/audit-bash.sh" << 'HOOK'
#!/bin/bash
AUDIT_LOG="${CLAUDE_AUDIT_LOG:-${HOME}/.claude/audit.log}"
INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[[ -z "$CMD" ]] && exit 0

mkdir -p "$(dirname "$AUDIT_LOG")"
printf '%s [bash] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$(echo "$CMD" | head -c 300)" >> "$AUDIT_LOG"
exit 0
HOOK
chmod +x "$BASE/hooks/audit-bash.sh"
```

Settings entry for audit-bash:
```json
"PostToolUse": [{"matcher": "Bash", "hooks": [{"type": "command", "command": "$BASE/hooks/audit-bash.sh"}]}]
```

#### slack-notify (Notification — posts Claude alerts to Slack)

Ask the user for their `SLACK_WEBHOOK` URL (or env var name). Warn if not set — this applies even when all components were selected via `a`.

```bash
cat > "$BASE/hooks/slack-notify.sh" << 'HOOK'
#!/bin/bash
[[ -z "${SLACK_WEBHOOK:-}" ]] && exit 0

INPUT=$(cat)
MSG=$(echo "$INPUT" | jq -r '.message // "Claude Code needs attention"')

curl -s -X POST "$SLACK_WEBHOOK" \
  -H 'Content-type: application/json' \
  -d "{\"text\": \":robot_face: *Claude Code*: ${MSG}\"}" \
  > /dev/null
exit 0
HOOK
chmod +x "$BASE/hooks/slack-notify.sh"
```

Settings entry for slack-notify:
```json
"Notification": [{"hooks": [{"type": "command", "command": "$BASE/hooks/slack-notify.sh"}]}]
```

**After writing all selected hook scripts**, merge hooks config into `$BASE/settings.json`. Build the `hooks` JSON object from selected hooks, then:

```bash
jq -s '.[0] * .[1]' "$BASE/settings.json" <(echo "$HOOKS_PATCH") > /tmp/ck_settings.json \
  && mv /tmp/ck_settings.json "$BASE/settings.json"
```

Replace `$BASE/hooks/` paths in the JSON with the actual resolved path (e.g. `~/.claude/hooks/` for user scope).

---

### MCP Servers

If MCP was selected via `a` at Step 3, skip this sub-selection and install all 3 servers using defaults:

| Parameter        | Default            |
|------------------|--------------------|
| AWS profile      | `dev`              |
| AWS region       | `us-east-1`        |
| Kubeconfig path  | `~/.kube/config`   |
| GitHub token var | `GITHUB_TOKEN`     |

Otherwise present:

```
Which MCP servers? (select all that apply)
  1. AWS
  2. Kubernetes
  3. GitHub
  a. All

Enter numbers and/or 'a':
```

#### AWS

Ask:
- AWS profile name (default: `dev`)
- AWS region (default: `us-east-1`)

```bash
MCP_AWS=$(jq -n --arg p "$PROFILE" --arg r "$REGION" '{
  mcpServers: { aws: {
    command: "uvx",
    args: ["awslabs.aws-mcp-server"],
    env: { AWS_PROFILE: $p, AWS_REGION: $r }
  }}
}')
```

Warn if `uvx` is not installed: `pip install uv`.

#### Kubernetes

Ask:
- Kubeconfig path (default: `~/.kube/config`)

```bash
MCP_K8S=$(jq -n --arg k "$KUBECONFIG" '{
  mcpServers: { kubernetes: {
    command: "npx",
    args: ["mcp-server-kubernetes"],
    env: { KUBECONFIG: $k }
  }}
}')
```

#### GitHub

Ask:
- Token env var name (default: `GITHUB_TOKEN`)

```bash
MCP_GH=$(jq -n --arg t "\${GITHUB_TOKEN}" '{
  mcpServers: { github: {
    command: "npx",
    args: ["@modelcontextprotocol/server-github"],
    env: { GITHUB_PERSONAL_ACCESS_TOKEN: $t }
  }}
}')
```

Merge each selected MCP config into `$BASE/settings.json` using `jq -s '.[0] * .[1]'`.

---

### Skills

```bash
mkdir -p "$BASE/skills/docling"
```

Write the docling skill. Read the content from the installed plugin's `skills/docling/SKILL.md` if accessible, otherwise write the standard content:

```bash
PLUGIN_SKILL=$(find "$HOME/.claude" -path "*/claudekit*/skills/docling/SKILL.md" 2>/dev/null | head -1)
if [ -n "$PLUGIN_SKILL" ]; then
  cp "$PLUGIN_SKILL" "$BASE/skills/docling/SKILL.md"
else
  # Fallback: write minimal skill stub — reinstall plugin first for full content
  echo "Skill source not found. Ensure the claudekit plugin is installed before running /claudekit:install."
fi
```

---

### Rules

```bash
mkdir -p "$BASE/rules"
```

Write `git.md`:

```bash
cat > "$BASE/rules/git.md" << 'RULE'
# Git

## Pushing

Always stage and commit first, then fetch+rebase, then push:

```bash
git add <files> && git commit -m "..." && git fetch origin && git rebase origin/main && git push
```

`git rebase` fails with unstaged changes. Never rebase before committing.

If SSH push fails (for example `Permission denied (publickey)`), switch `origin`
to HTTPS and retry:

```bash
git remote set-url origin https://github.com/<owner>/<repo>.git
git fetch origin
git rebase origin/main
git push origin main
```

## After merging a PR

Always return to main and pull latest:

```bash
git checkout main && git pull origin main
```

## Commit messages

No `Co-Authored-By` or any AI attribution lines in commit messages.
RULE
```

---

### Optimization

If RTK was selected (1 or a), install RTK. If Caveman was selected (2 or a), install Caveman. Install only the selected tools.

Present sub-selection:

```
Which optimization tools? (select all that apply)
  1. RTK     — token-efficient shell command proxy (60-90% token savings)
  2. Caveman — ultra-compressed communication mode (~75% token savings)
  a. All

Enter numbers and/or 'a':
```

#### RTK

```bash
curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
```

If curl or install script fails, print:
> `RTK install failed — skipping. Install manually: https://github.com/rtk-ai/rtk`
Then continue.

On success, patch PATH for bash and zsh:

```bash
for rc in ~/.bashrc ~/.zshrc; do
  [ -f "$rc" ] || continue
  grep -q '\.local/bin' "$rc" 2>/dev/null || \
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$rc"
done
```

Wire Claude Code hook (use full path — shell not yet reloaded):

```bash
~/.local/bin/rtk init -g --auto-patch
```

If `rtk init` fails, print:
> `RTK hook setup failed — run ~/.local/bin/rtk init -g --auto-patch manually after reloading your shell`
Then continue.

#### Caveman

```bash
claude plugin marketplace add JuliusBrussee/caveman
claude plugin install caveman@caveman
```

If either command fails, print:
> `Caveman install failed — skipping. Install manually: claude plugin marketplace add JuliusBrussee/caveman && claude plugin install caveman@caveman`
Then continue.

---

## Step 5 — Summary

After all components are installed, print a summary:

```
claudekit install complete.

Scope: [user|project] → [path]

Installed:
  ✓ Settings  → $BASE/settings.json
  ✓ Hooks     → block-prod, auto-lint, audit, slack  ($BASE/hooks/)
  ✓ MCP       → aws, kubernetes, github
  ✓ Skills    → docling  ($BASE/skills/docling/)
  ✓ Rules     → git.md   ($BASE/rules/)

Restart Claude Code to apply changes.
```

Only list components that were actually installed.
