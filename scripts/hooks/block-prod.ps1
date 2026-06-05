#!/usr/bin/env pwsh
# PreToolUse hook: block any Bash command targeting production resources.
# exit 2 = hard block with message surfaced to Claude.

$raw = [Console]::In.ReadToEnd()
try { $data = $raw | ConvertFrom-Json } catch { exit 0 }
$cmd = $data.tool_input.command
if (-not $cmd) { exit 0 }

$patterns = @(
    'kubectl.*--context=prod',
    'kubectl.*-n production',
    'kubectl.*--namespace=production',
    'terraform.*-var-file=prod',
    'terraform.*workspace.*prod',
    'aws.*--profile=production',
    'aws.*--profile=prod',
    'helm.*prod',
    'gcloud.*--project=.*-prod'
)

foreach ($p in $patterns) {
    if ($cmd -match $p) {
        [Console]::Error.WriteLine("BLOCKED: production target detected. Run this manually with explicit approval.")
        exit 2
    }
}
exit 0
