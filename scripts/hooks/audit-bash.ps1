#!/usr/bin/env pwsh
# PostToolUse hook: append every Bash command Claude runs to an audit log.

$auditLog = if ($env:CLAUDE_AUDIT_LOG) { $env:CLAUDE_AUDIT_LOG } else { "$HOME\.claude\audit.log" }
$raw = [Console]::In.ReadToEnd()
try { $data = $raw | ConvertFrom-Json } catch { exit 0 }
$cmd = $data.tool_input.command
if (-not $cmd) { exit 0 }

$logDir = [System.IO.Path]::GetDirectoryName($auditLog)
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Force -Path $logDir | Out-Null }

$ts = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$snippet = if ($cmd.Length -gt 300) { $cmd.Substring(0, 300) } else { $cmd }
Add-Content -Path $auditLog -Value "$ts [bash] $snippet"
exit 0
