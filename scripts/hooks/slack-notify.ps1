#!/usr/bin/env pwsh
# Notification hook: post Claude alerts to Slack.
# Requires SLACK_WEBHOOK env var.

if (-not $env:SLACK_WEBHOOK) { exit 0 }

$raw = [Console]::In.ReadToEnd()
try { $data = $raw | ConvertFrom-Json } catch { exit 0 }
$msg = if ($data.message) { $data.message } else { "Claude Code needs attention" }

$body = @{ text = ":robot_face: *Claude Code*: $msg" } | ConvertTo-Json -Compress
Invoke-RestMethod -Uri $env:SLACK_WEBHOOK -Method Post -ContentType 'application/json' -Body $body -ErrorAction SilentlyContinue | Out-Null
exit 0
