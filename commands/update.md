---
description: Resync claude4ops scripts from plugin source to ~/.claude/ — run after plugin updates
---

# claude4ops Update

Resyncs all installed scripts from the plugin source cache to their destinations. Run this after a `claude plugin update` to pick up new versions.

---

## Step 1 — Find Plugin Source

```bash
PLUGIN_SRC=$(find "$HOME/.claude" -path "*/claude4ops*/scripts" -type d 2>/dev/null | head -1)
if [ -z "$PLUGIN_SRC" ]; then
  echo "ERROR: claude4ops plugin source not found."
  echo "Reinstall: claude plugin install claude4ops"
  exit 1
fi
echo "Plugin source: $PLUGIN_SRC"
```

PowerShell (Windows):
```powershell
$PLUGIN_SRC = Get-ChildItem -Path "$HOME\.claude" -Recurse -Directory -Filter "scripts" -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -like "*claude4ops*" } | Select-Object -First 1 -ExpandProperty FullName
if (-not $PLUGIN_SRC) {
    Write-Error "ERROR: claude4ops plugin source not found. Reinstall: claude plugin install claude4ops"
    exit 1
}
Write-Host "Plugin source: $PLUGIN_SRC"
```

---

## Step 2 — Detect Platform

```bash
PLATFORM=$(uname -s 2>/dev/null)
```

PowerShell: `$PLATFORM = "windows"`

---

## Step 3 — Resync Scripts

Track what was updated. Initialize: `UPDATED=""` (bash) / `$Updated = @()` (PowerShell).

### Statusline script

**Linux/macOS/WSL/Git Bash:**

```bash
if [ -f "$HOME/.claude/statusline-command.sh" ]; then
  cp "$PLUGIN_SRC/statusline-command.sh" "$HOME/.claude/statusline-command.sh"
  chmod +x "$HOME/.claude/statusline-command.sh"
  UPDATED="$UPDATED statusline-command.sh"
fi
```

**Windows (PowerShell):**

```powershell
if (Test-Path "$HOME\.claude\statusline-command.ps1") {
    Copy-Item "$PLUGIN_SRC\statusline-command.ps1" "$HOME\.claude\statusline-command.ps1" -Force
    $Updated += "statusline-command.ps1"
}
```

### Hook scripts

For each hook that exists in `~/.claude/hooks/`, copy the updated version from plugin source.

**Linux/macOS/WSL/Git Bash:**

```bash
for hook in block-prod.sh auto-lint.sh audit-bash.sh slack-notify.sh; do
  DEST="$HOME/.claude/hooks/$hook"
  SRC="$PLUGIN_SRC/hooks/$hook"
  if [ -f "$DEST" ] && [ -f "$SRC" ]; then
    cp "$SRC" "$DEST"
    chmod +x "$DEST"
    UPDATED="$UPDATED $hook"
  fi
done
```

**Windows (PowerShell):**

```powershell
foreach ($hook in @("block-prod.ps1","auto-lint.ps1","audit-bash.ps1","slack-notify.ps1")) {
    $dest = "$HOME\.claude\hooks\$hook"
    $src  = "$PLUGIN_SRC\hooks\$hook"
    if ((Test-Path $dest) -and (Test-Path $src)) {
        Copy-Item $src $dest -Force
        $Updated += $hook
    }
}
```

### Skills

```bash
SKILL_SRC=$(find "$HOME/.claude" -path "*/claude4ops*/skills/docling/SKILL.md" 2>/dev/null | head -1)
if [ -n "$SKILL_SRC" ] && [ -f "$HOME/.claude/skills/docling/SKILL.md" ]; then
  cp "$SKILL_SRC" "$HOME/.claude/skills/docling/SKILL.md"
  UPDATED="$UPDATED skills/docling/SKILL.md"
fi
```

PowerShell:
```powershell
$skillSrc = Get-ChildItem -Path "$HOME\.claude" -Recurse -Filter "SKILL.md" -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -like "*claude4ops*docling*" } | Select-Object -First 1 -ExpandProperty FullName
if ($skillSrc -and (Test-Path "$HOME\.claude\skills\docling\SKILL.md")) {
    Copy-Item $skillSrc "$HOME\.claude\skills\docling\SKILL.md" -Force
    $Updated += "skills/docling/SKILL.md"
}
```

### Rules

```bash
RULES_SRC=$(find "$HOME/.claude" -path "*/claude4ops*/rules/git.md" 2>/dev/null | head -1)
if [ -n "$RULES_SRC" ] && [ -f "$HOME/.claude/rules/git.md" ]; then
  cp "$RULES_SRC" "$HOME/.claude/rules/git.md"
  UPDATED="$UPDATED rules/git.md"
fi
```

PowerShell:
```powershell
$rulesSrc = Get-ChildItem -Path "$HOME\.claude" -Recurse -Filter "git.md" -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -like "*claude4ops*/rules*" } | Select-Object -First 1 -ExpandProperty FullName
if ($rulesSrc -and (Test-Path "$HOME\.claude\rules\git.md")) {
    Copy-Item $rulesSrc "$HOME\.claude\rules\git.md" -Force
    $Updated += "rules/git.md"
}
```

---

## Step 4 — Summary

If nothing was updated, print:

```
Nothing to update — no previously installed claude4ops scripts found in ~/.claude/.
Run /claude4ops:install to install for the first time.
```

Otherwise print:

```
claude4ops update complete.

Updated:
  ✓ <file1>
  ✓ <file2>
  ...

Restart Claude Code to apply changes.
```
