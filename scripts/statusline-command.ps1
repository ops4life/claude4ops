#!/usr/bin/env pwsh
$raw = [Console]::In.ReadToEnd()
try { $data = $raw | ConvertFrom-Json } catch { Write-Host -NoNewline ""; exit 0 }

$model = $data.model.display_name
$five  = $data.rate_limits.five_hour.used_percentage
$week  = $data.rate_limits.seven_day.used_percentage

function New-Bar($pct) {
    $filled = [Math]::Min([Math]::Round([double]$pct / 10), 10)
    return ('▓' * $filled) + ('░' * (10 - $filled))
}

$parts = $model

if ($five) {
    $fivePct = [Math]::Round([double]$five)
    $bar = New-Bar $five
    $fiveDisplay = "5h:$bar ${fivePct}%"
    $fiveResets = $data.rate_limits.five_hour.resets_at
    if ($fiveResets) {
        $resetTime = [DateTimeOffset]::FromUnixTimeSeconds([long]$fiveResets).ToLocalTime().ToString("HH:mm")
        $fiveDisplay += " (resets $resetTime)"
    }
    $parts += " | $fiveDisplay"
}

if ($week) {
    $weekPct = [Math]::Round([double]$week)
    $parts += "  7d:$(New-Bar $week) ${weekPct}%"
}

Write-Host -NoNewline $parts
