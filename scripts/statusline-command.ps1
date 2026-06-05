#!/usr/bin/env pwsh
$raw = [Console]::In.ReadToEnd()
try { $data = $raw | ConvertFrom-Json } catch { Write-Host -NoNewline ""; exit 0 }

$model = $data.model.display_name
$five  = $data.rate_limits.five_hour.used_percentage
$week  = $data.rate_limits.seven_day.used_percentage

function New-Bar($pct) {
    $esc = [char]27
    $pctInt = [Math]::Round([double]$pct)
    $filled = [Math]::Min([Math]::Round([double]$pct / 10), 10)
    $color = if ($pctInt -ge 80) { "${esc}[38;5;196m" }
             elseif ($pctInt -ge 60) { "${esc}[38;5;214m" }
             else { "${esc}[38;5;82m" }
    return "${color}$('▓' * $filled)${esc}[0m$('░' * (10 - $filled))"
}

$rawCwd = (Get-Location).Path -replace [regex]::Escape($HOME), '~'
$segments = $rawCwd -split '[/\\]'
$cwd = if ($segments.Count -le 2) { $rawCwd } else { $segments[-2..-1] -join '/' }
$branch = git rev-parse --abbrev-ref HEAD 2>$null
$context = if ($branch) { "$cwd ($branch)" } else { $cwd }
$parts = "$context | $model"

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
    $weekDisplay = "7d:$(New-Bar $week) ${weekPct}%"
    $weekResets = $data.rate_limits.seven_day.resets_at
    if ($weekResets) {
        $resetDate = [DateTimeOffset]::FromUnixTimeSeconds([long]$weekResets).ToLocalTime().ToString("MMM dd HH:mm")
        $weekDisplay += " (resets $resetDate)"
    }
    $parts += "  $weekDisplay"
}

Write-Host -NoNewline $parts
