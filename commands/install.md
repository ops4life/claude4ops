---
description: Install claude4ops hooks, skills, rules, and settings — user or project scope
---

# claude4ops Install

Interactive agentic install. Follow each step in order. Run bash commands exactly as shown.

---

## Step 1 — Prerequisites

**Detect platform:**

Try the bash detection first. If the Bash tool is unavailable or `uname` returns nothing, fall back to PowerShell detection.

Bash:
```bash
_detect_platform() {
  case "$(uname -s 2>/dev/null)" in
    Linux*)
      if grep -qi microsoft /proc/version 2>/dev/null; then echo "wsl"
      else echo "linux"; fi ;;
    Darwin*) echo "macos" ;;
    MINGW*|MSYS*|CYGWIN*) echo "gitbash" ;;
    *) echo "unknown" ;;
  esac
}
PLATFORM=$(_detect_platform)
echo "Platform: $PLATFORM"
```

PowerShell (use if bash is unavailable):
```powershell
$PLATFORM = if ($IsWindows -or $env:OS -eq "Windows_NT") { "windows" }
            elseif ($IsMacOS) { "macos" }
            else { "linux" }
Write-Host "Platform: $PLATFORM"
```

Store `$PLATFORM` for use in later steps. Valid values: `linux`, `macos`, `wsl`, `gitbash`, `windows`.

**Check jq:**

Bash:
```bash
command -v jq >/dev/null 2>&1 || echo "MISSING_JQ"
```

PowerShell (Windows):
```powershell
if (-not (Get-Command jq -ErrorAction SilentlyContinue)) { Write-Host "MISSING_JQ" }
```

If `MISSING_JQ`, stop and tell the user:
> `jq` is required. Install it, then re-run `/claude4ops:install`.
> - **Linux/WSL**: `apt-get install jq` or `yum install jq`
> - **macOS**: `brew install jq`
> - **Windows**: `winget install stedolan.jq` or `choco install jq`
>
> On Windows, jq is only required for the hooks config merge. If unavailable, the install will use PowerShell's built-in JSON support instead.

---

## Step 2 — Scope

Use `AskUserQuestion` with **exactly** these parameters (header must be ≤12 chars):

- header: `"Scope"`
- question: `"Where should claude4ops be installed?"`
- options:
  - label: `"User"`, description: `"~/.claude/ — applies to all projects on this machine"`
  - label: `"Project"`, description: `".claude/ in current directory — repo-local, committable to git"`

Store the answer. All paths below use `$BASE`:
- User → `BASE="$HOME/.claude"` (bash) / `$BASE = "$HOME\.claude"` (PowerShell)
- Project → `BASE=".claude"` (bash) / `$BASE = ".claude"` (PowerShell)

Bash:
```bash
mkdir -p "$BASE"
```

PowerShell (Windows):
```powershell
New-Item -ItemType Directory -Force -Path $BASE | Out-Null
```

---

## Step 3 — Component Selection

Use two `AskUserQuestion` calls (max 4 options each).

**First call** — header ≤12 chars:

- header: `"Components"`
- question: `"Which components do you want to install?"`
- multiSelect: `true`
- options:
  - label: `"All"`, description: `"Settings, Hooks, MCP, Skills, Rules, Optimization, Plugins — installs everything"`
  - label: `"Settings"`, description: `"settings.json merge + status line script"`
  - label: `"Hooks"`, description: `"lifecycle hooks (block-prod, auto-lint, audit, Slack)"`
  - label: `"MCP"`, description: `"AWS, Kubernetes, GitHub real API access"`

If user selected `"All"`, skip second call and mark all 7 selected.

**Second call** (only if `"All"` was NOT selected):

- header: `"More"`
- question: `"Which additional components do you want to install?"`
- multiSelect: `true`
- options:
  - label: `"Skills"`, description: `"docling — PDF/DOCX/image → Markdown"`
  - label: `"Rules"`, description: `"git workflow rules"`
  - label: `"Optimization"`, description: `"RTK token proxy + Caveman mode plugin"`
  - label: `"Plugins"`, description: `"context7, playwright, superpowers, frontend-design"`

Merge both answers. Record final selections, then install all at once in Step 4.

---

## Step 4 — Install

### Settings

```bash
mkdir -p "$BASE"
```

**User scope only** — write the statusline script.

The statusline displays:
- Current working directory (last 2 path segments) + git branch
- Model name
- 5-hour rate limit: color-coded bar (green/amber/red), usage %, reset time
- 7-day rate limit: color-coded bar, usage %, reset date+time

Example output:
```
opt/claude4ops (main) | claude-sonnet-4-6 | 5h:▓▓▓▓░░░░░░ 42% (resets 15:53)  7d:▓▓░░░░░░░░ 15% (resets Jun 11 07:00)
```

On **Windows (PowerShell)**, write `statusline-command.ps1` instead and set the command to `pwsh -NoProfile -File "$HOME\.claude\statusline-command.ps1"`. Copy from plugin source — fail clearly if not found:

```powershell
$pluginScript = Get-ChildItem -Path "$HOME\.claude" -Recurse -Filter "statusline-command.ps1" -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -like "*claude4ops*" } | Select-Object -First 1 -ExpandProperty FullName
if (-not $pluginScript) {
    Write-Error "ERROR: claude4ops plugin source not found. Reinstall: claude plugin install claude4ops"
    exit 1
}
Copy-Item $pluginScript "$HOME\.claude\statusline-command.ps1" -Force
```

Then skip to the settings merge step below.

On **Linux/macOS/WSL/Git Bash**, copy from plugin source — fail clearly if not found:

```bash
PLUGIN_SH=$(find "$HOME/.claude" -path "*/claude4ops*/scripts/statusline-command.sh" 2>/dev/null | head -1)
if [ -z "$PLUGIN_SH" ]; then
  echo "ERROR: claude4ops plugin source not found. Reinstall: claude plugin install claude4ops"
  exit 1
fi
cp "$PLUGIN_SH" "$HOME/.claude/statusline-command.sh"
chmod +x "$HOME/.claude/statusline-command.sh"
```

Skip the statusline block for project scope.

**Merge base settings** into `$BASE/settings.json`:

On Windows, use `"pwsh -NoProfile -File $HOME\\.claude\\statusline-command.ps1"` as the statusLine command instead.

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
Bash:
```bash
if [ -f "$BASE/settings.json" ]; then
  TMP=$(mktemp)
  jq -s '.[0] * .[1]' "$BASE/settings.json" <(echo "$PATCH") > "$TMP" \
    && mv "$TMP" "$BASE/settings.json"
else
  echo "$PATCH" | jq '.' > "$BASE/settings.json"
fi
```

PowerShell (Windows):
```powershell
function Merge-Json {
    param($Base, $Patch)
    foreach ($key in $Patch.PSObject.Properties.Name) {
        $bv = $Base.$key; $pv = $Patch.$key
        if ($bv -and $bv.GetType().Name -eq 'PSCustomObject' -and $pv.GetType().Name -eq 'PSCustomObject') {
            $Base.$key = Merge-Json $bv $pv
        } else {
            $Base | Add-Member -Force -NotePropertyName $key -NotePropertyValue $pv
        }
    }
    return $Base
}

$settingsFile = "$BASE\settings.json"
$patchObj = $PATCH | ConvertFrom-Json
if (Test-Path $settingsFile) {
    $existing = Get-Content $settingsFile -Raw | ConvertFrom-Json
    $merged = Merge-Json $existing $patchObj
    $merged | ConvertTo-Json -Depth 10 | Set-Content $settingsFile
} else {
    $patchObj | ConvertTo-Json -Depth 10 | Set-Content $settingsFile
}
```
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
PLUGIN_HOOK=$(find "$HOME/.claude" -path "*/claude4ops*/scripts/hooks/block-prod.sh" 2>/dev/null | head -1)
if [ -z "$PLUGIN_HOOK" ]; then
  echo "ERROR: claude4ops plugin source not found. Reinstall: claude plugin install claude4ops"
  exit 1
fi
cp "$PLUGIN_HOOK" "$BASE/hooks/block-prod.sh"
chmod +x "$BASE/hooks/block-prod.sh"
```

Settings entry for block-prod:
```json
"PreToolUse": [{"matcher": "Bash", "hooks": [{"type": "command", "command": "$BASE/hooks/block-prod.sh"}]}]
```

#### auto-lint (Stop — formats files Claude touched after each turn)

```bash
PLUGIN_HOOK=$(find "$HOME/.claude" -path "*/claude4ops*/scripts/hooks/auto-lint.sh" 2>/dev/null | head -1)
if [ -z "$PLUGIN_HOOK" ]; then
  echo "ERROR: claude4ops plugin source not found. Reinstall: claude plugin install claude4ops"
  exit 1
fi
cp "$PLUGIN_HOOK" "$BASE/hooks/auto-lint.sh"
chmod +x "$BASE/hooks/auto-lint.sh"
```

Settings entry for auto-lint:
```json
"Stop": [{"hooks": [{"type": "command", "command": "$BASE/hooks/auto-lint.sh"}]}]
```

#### audit-bash (PostToolUse — logs all Bash commands)

```bash
PLUGIN_HOOK=$(find "$HOME/.claude" -path "*/claude4ops*/scripts/hooks/audit-bash.sh" 2>/dev/null | head -1)
if [ -z "$PLUGIN_HOOK" ]; then
  echo "ERROR: claude4ops plugin source not found. Reinstall: claude plugin install claude4ops"
  exit 1
fi
cp "$PLUGIN_HOOK" "$BASE/hooks/audit-bash.sh"
chmod +x "$BASE/hooks/audit-bash.sh"
```

Settings entry for audit-bash:
```json
"PostToolUse": [{"matcher": "Bash", "hooks": [{"type": "command", "command": "$BASE/hooks/audit-bash.sh"}]}]
```

#### slack-notify (Notification — posts Claude alerts to Slack)

Ask the user for their `SLACK_WEBHOOK` URL (or env var name). Warn if not set — this applies even when all components were selected via `a`.

```bash
PLUGIN_HOOK=$(find "$HOME/.claude" -path "*/claude4ops*/scripts/hooks/slack-notify.sh" 2>/dev/null | head -1)
if [ -z "$PLUGIN_HOOK" ]; then
  echo "ERROR: claude4ops plugin source not found. Reinstall: claude plugin install claude4ops"
  exit 1
fi
cp "$PLUGIN_HOOK" "$BASE/hooks/slack-notify.sh"
chmod +x "$BASE/hooks/slack-notify.sh"
```

Settings entry for slack-notify:
```json
"Notification": [{"hooks": [{"type": "command", "command": "$BASE/hooks/slack-notify.sh"}]}]
```

**Windows (PowerShell)**: Instead of writing `.sh` hook scripts, copy the `.ps1` equivalents from the plugin's `scripts/hooks/` directory (e.g. `block-prod.ps1`, `auto-lint.ps1`, `audit-bash.ps1`, `slack-notify.ps1`) to `$BASE\hooks\`. Use these settings entries instead:

```json
"PreToolUse": [{"matcher": "Bash", "hooks": [{"type": "command", "command": "pwsh -NoProfile -File \"$BASE\\hooks\\block-prod.ps1\""}]}]
"Stop":       [{"hooks": [{"type": "command", "command": "pwsh -NoProfile -File \"$BASE\\hooks\\auto-lint.ps1\""}]}]
"PostToolUse":[{"matcher": "Bash", "hooks": [{"type": "command", "command": "pwsh -NoProfile -File \"$BASE\\hooks\\audit-bash.ps1\""}]}]
"Notification":[{"hooks": [{"type": "command", "command": "pwsh -NoProfile -File \"$BASE\\hooks\\slack-notify.ps1\""}]}]
```

**After writing all selected hook scripts**, merge hooks config into `$BASE/settings.json`. Build the `hooks` JSON object from selected hooks, then:

Bash:
```bash
TMP=$(mktemp)
jq -s '.[0] * .[1]' "$BASE/settings.json" <(echo "$HOOKS_PATCH") > "$TMP" \
  && mv "$TMP" "$BASE/settings.json"
```

PowerShell (Windows):
```powershell
$hooksObj = $HOOKS_PATCH | ConvertFrom-Json
$existing = Get-Content "$BASE\settings.json" -Raw | ConvertFrom-Json
$existing | Add-Member -Force -NotePropertyName 'hooks' -NotePropertyValue $hooksObj.hooks
$existing | ConvertTo-Json -Depth 10 | Set-Content "$BASE\settings.json"
```

Replace `$BASE/hooks/` (bash) or `$BASE\hooks\` (PowerShell) paths with the actual resolved path.

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
mkdir -p "$BASE/skills/convert"
```

Write the docling skill. Copy from plugin source — fail clearly if not found:

```bash
PLUGIN_SKILL=$(find "$HOME/.claude" -path "*/claude4ops*/skills/docling/SKILL.md" 2>/dev/null | head -1)
if [ -z "$PLUGIN_SKILL" ]; then
  echo "ERROR: claude4ops plugin source not found. Reinstall: claude plugin install claude4ops"
  exit 1
fi
cp "$PLUGIN_SKILL" "$BASE/skills/docling/SKILL.md"
```

Write the convert skill. Copy from plugin source — fail clearly if not found:

```bash
PLUGIN_CONVERT=$(find "$HOME/.claude" -path "*/claude4ops*/skills/convert/SKILL.md" 2>/dev/null | head -1)
if [ -z "$PLUGIN_CONVERT" ]; then
  echo "ERROR: claude4ops plugin source not found. Reinstall: claude plugin install claude4ops"
  exit 1
fi
cp "$PLUGIN_CONVERT" "$BASE/skills/convert/SKILL.md"
```

---

### Rules

```bash
mkdir -p "$BASE/rules"
```

Write `git.md`. Copy from plugin source — fail clearly if not found:

```bash
PLUGIN_RULE=$(find "$HOME/.claude" -path "*/claude4ops*/rules/git.md" 2>/dev/null | head -1)
if [ -z "$PLUGIN_RULE" ]; then
  echo "ERROR: claude4ops plugin source not found. Reinstall: claude plugin install claude4ops"
  exit 1
fi
cp "$PLUGIN_RULE" "$BASE/rules/git.md"
```

---

### Optimization

This section runs only if the user selected component 6 (Optimization) in Step 3.

Present sub-selection:

```
Which optimization tools? (select all that apply)
  1. RTK     — token-efficient shell command proxy (60-90% token savings)
  2. Caveman — ultra-compressed communication mode (~75% token savings)
  a. All

Enter numbers and/or 'a':
```

- Input includes `a` → install both tools
- Input is numbers → install only those tools
- Invalid input → re-prompt

#### RTK

**Windows (PowerShell)**: RTK's install script requires a POSIX shell, but the Windows binary works in CLAUDE.md injection mode — filters apply, auto-rewrite hook is unavailable. Install natively:

```powershell
# 1. Download Windows binary
$rtk_url = "https://github.com/rtk-ai/rtk/releases/latest/download/rtk-x86_64-pc-windows-msvc.zip"
$zip = "$env:TEMP\rtk.zip"
Invoke-WebRequest -Uri $rtk_url -OutFile $zip

# 2. Extract to PATH location
$bin = "$env:USERPROFILE\.local\bin"
New-Item -ItemType Directory -Force -Path $bin | Out-Null
Expand-Archive -Path $zip -DestinationPath $bin -Force
Remove-Item $zip

# 3. Add to PATH if not already present
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($currentPath -notlike "*$bin*") {
    [Environment]::SetEnvironmentVariable("PATH", "$bin;$currentPath", "User")
    $env:PATH = "$bin;$env:PATH"
}

# 4. Initialize (CLAUDE.md injection mode — no hook, but filters work)
& "$bin\rtk.exe" init -g
```

If download or init fails, print:
> `RTK install failed on Windows — skipping. For full hook support use WSL2, or install manually: https://github.com/rtk-ai/rtk#windows`
Then continue to Caveman.

On success, inform the user:
> `RTK installed (Windows mode): filters active, auto-rewrite hook not available. Use rtk <cmd> explicitly, or switch to WSL2 for full support.`

**Linux/macOS/WSL/Git Bash**:

```bash
curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
```

If curl or install script fails, print:
> `RTK install failed — skipping. Install manually: https://github.com/rtk-ai/rtk`
Then continue.

On success, patch PATH for bash and zsh:

```bash
for rc in ~/.bashrc ~/.zshrc ~/.bash_profile; do
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

### Plugins

This section runs only if the user selected "Plugins" in Step 3 (or selected "All").

If "All" was selected in Step 3, install all 4 plugins with no sub-question.

Otherwise present `AskUserQuestion`:

- header: `"Plugins"`
- question: `"Which plugins do you want to install?"`
- multiSelect: `true`
- options:
  - label: `"All"`, description: `"Install all 4 plugins"`
  - label: `"context7"`, description: `"Up-to-date library docs via Model Context Protocol"`
  - label: `"playwright"`, description: `"Browser automation and testing"`
  - label: `"superpowers"`, description: `"Agentic workflow skills (brainstorming, TDD, debugging)"`
  - label: `"frontend-design"`, description: `"UI/UX design guidance and component patterns"`

If "All" selected in sub-question: install all 4.

First ensure the `claude-plugins-official` marketplace is registered (idempotent, non-fatal):

```bash
claude plugin marketplace add anthropics/claude-plugins-official 2>/dev/null || true
```

Then install each selected plugin:

```bash
claude plugin install context7@claude-plugins-official
claude plugin install playwright@claude-plugins-official
claude plugin install superpowers@claude-plugins-official
claude plugin install frontend-design@claude-plugins-official
```

On failure for any individual plugin, print warning and continue:
> `<name> install failed — skipping. Install manually: claude plugin install <name>@claude-plugins-official`

---

## Step 5 — Summary

After all components are installed, print a summary:

```
claude4ops install complete.

Scope: [user|project] → [path]

Installed:
  ✓ Settings  → $BASE/settings.json
  ✓ Hooks     → block-prod, auto-lint, audit, slack  ($BASE/hooks/)
  ✓ MCP       → aws, kubernetes, github
  ✓ Skills    → docling  ($BASE/skills/docling/)
  ✓ Skills    → convert  ($BASE/skills/convert/)
  ✓ Rules        → git.md   ($BASE/rules/)
  ✓ Optimization → RTK (~/.local/bin/rtk), Caveman plugin
  ✓ Plugins      → context7, playwright, superpowers, frontend-design

Restart Claude Code to apply changes.
If RTK was installed, also reload your shell: source ~/.bashrc (or ~/.zshrc)
On Windows: hooks use .ps1 scripts invoked via pwsh. Ensure PowerShell execution policy allows scripts: Set-ExecutionPolicy -Scope CurrentUser RemoteSigned

To pick up future plugin updates without reinstalling: /claude4ops:update
```

Only list components that were actually installed. For Optimization, only list tools that succeeded. For Plugins, only list plugins that succeeded; if partial, append `(<failed> failed — install manually: claude plugin install <name>@claude-plugins-official)`.
