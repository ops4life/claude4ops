#!/usr/bin/env pwsh
# Stop hook: lint and format every file Claude touched after each turn.

$changed = git diff --name-only HEAD 2>$null
if (-not $changed) { exit 0 }

$formatted = 0
foreach ($f in $changed) {
    if (-not (Test-Path $f -PathType Leaf)) { continue }
    $ext = [System.IO.Path]::GetExtension($f)
    switch ($ext) {
        '.py' {
            if (Get-Command ruff -ErrorAction SilentlyContinue) { ruff check --fix $f 2>$null }
            if (Get-Command black -ErrorAction SilentlyContinue) { black -q $f 2>$null }
            $formatted++
        }
        '.tf' {
            if (Get-Command terraform -ErrorAction SilentlyContinue) { terraform fmt $f 2>$null }
            $formatted++
        }
        '.go' {
            if (Get-Command gofmt -ErrorAction SilentlyContinue) { gofmt -w $f 2>$null }
            $formatted++
        }
        { $_ -in '.ts', '.js', '.tsx', '.jsx' } {
            if (Get-Command npx -ErrorAction SilentlyContinue) { npx --yes eslint --fix $f 2>$null }
            $formatted++
        }
        { $_ -in '.yaml', '.yml' } {
            if (Get-Command yamllint -ErrorAction SilentlyContinue) { yamllint -d relaxed $f 2>$null }
        }
    }
}

if ($formatted -gt 0) {
    $dirty = git diff --name-only 2>$null
    if ($dirty) {
        $count = ($dirty | Measure-Object -Line).Lines
        Write-Host "auto-lint: formatted $count file(s)"
    }
}
exit 0
