#!/bin/sh
# PreToolUse hook: block any Bash command targeting production resources.
# exit 2 = hard block with message surfaced to Claude.

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

[ -z "$CMD" ] && exit 0

DANGER_PATTERNS="kubectl.*--context=prod
kubectl.*-n production
kubectl.*--namespace=production
terraform.*-var-file=prod
terraform.*workspace.*prod
aws.*--profile=production
aws.*--profile=prod
helm.*prod
gcloud.*--project=.*-prod"

while IFS= read -r pattern; do
  [ -z "$pattern" ] && continue
  if echo "$CMD" | grep -qE "$pattern"; then
    echo "BLOCKED: production target detected. Run this manually with explicit approval." >&2
    exit 2
  fi
done <<EOF
$DANGER_PATTERNS
EOF

exit 0
