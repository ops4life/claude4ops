#!/usr/bin/env pwsh
$raw = [Console]::In.ReadToEnd()
try { $data = $raw | ConvertFrom-Json } catch { Write-Host -NoNewline ""; exit 0 }

$model = $data.model.display_name
$five  = $data.rate_limits.five_hour.used_percentage
$week  = $data.rate_limits.seven_day.used_percentage

function Write-ColorBar($pct) {
    $pctInt = [Math]::Round([double]$pct)
    $filled = [Math]::Min([Math]::Round([double]$pct / 10), 10)
    $empty  = 10 - $filled
    $color  = if ($pctInt -ge 80) { "Red" }
              elseif ($pctInt -ge 60) { "Yellow" }
              else { "Green" }
    Write-Host -NoNewline "["
    if ($filled -gt 0) { Write-Host -NoNewline ("#" * $filled) -ForegroundColor $color }
    Write-Host -NoNewline ("-" * $empty + "]")
}

$rawCwd = (Get-Location).Path -replace [regex]::Escape($HOME), '~'
$segments = $rawCwd -split '[/\\]'
$cwd = if ($segments.Count -le 2) { $rawCwd } else { $segments[-2..-1] -join '/' }
$branch = git rev-parse --abbrev-ref HEAD 2>$null
$context = if ($branch) { "$cwd ($branch)" } else { $cwd }

Write-Host -NoNewline "$context | $model"

if ($five) {
    $fivePct   = [Math]::Round([double]$five)
    $fiveResets = $data.rate_limits.five_hour.resets_at
    $resetStr  = if ($fiveResets) {
        $t = [DateTimeOffset]::FromUnixTimeSeconds([long]$fiveResets).ToLocalTime().ToString("HH:mm")
        " (resets $t)"
    } else { "" }
    Write-Host -NoNewline " | 5h:"
    Write-ColorBar $five
    Write-Host -NoNewline " ${fivePct}%${resetStr}"
}

if ($week) {
    $weekPct   = [Math]::Round([double]$week)
    $weekResets = $data.rate_limits.seven_day.resets_at
    $resetStr  = if ($weekResets) {
        $d = [DateTimeOffset]::FromUnixTimeSeconds([long]$weekResets).ToLocalTime().ToString("MMM dd HH:mm")
        " (resets $d)"
    } else { "" }
    Write-Host -NoNewline "  7d:"
    Write-ColorBar $week
    Write-Host -NoNewline " ${weekPct}%${resetStr}"
}
