#!/bin/bash
# Stop hook: lint and format every file Claude touched after each turn.

CHANGED=$(git diff --name-only HEAD 2>/dev/null)
[[ -z "$CHANGED" ]] && exit 0

FORMATTED=0
for f in $CHANGED; do
  [[ -f "$f" ]] || continue
  case "$f" in
    *.py)
      command -v ruff >/dev/null && ruff check --fix "$f" 2>/dev/null
      command -v black >/dev/null && black -q "$f" 2>/dev/null
      FORMATTED=$((FORMATTED + 1))
      ;;
    *.tf)
      command -v terraform >/dev/null && terraform fmt "$f" 2>/dev/null
      FORMATTED=$((FORMATTED + 1))
      ;;
    *.go)
      command -v gofmt >/dev/null && gofmt -w "$f" 2>/dev/null
      FORMATTED=$((FORMATTED + 1))
      ;;
    *.ts|*.js|*.tsx|*.jsx)
      command -v npx >/dev/null && npx --yes eslint --fix "$f" 2>/dev/null
      FORMATTED=$((FORMATTED + 1))
      ;;
    *.yaml|*.yml)
      if command -v yamllint >/dev/null; then yamllint -d relaxed "$f" 2>/dev/null; fi
      ;;
  esac
done

if ! git diff --quiet 2>/dev/null && [[ $FORMATTED -gt 0 ]]; then
  COUNT=$(git diff --name-only | wc -l | tr -d ' ')
  echo "auto-lint: formatted ${COUNT} file(s)"
fi

exit 0
