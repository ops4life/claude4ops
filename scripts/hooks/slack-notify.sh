#!/bin/bash
# Notification hook: post Claude alerts to Slack.
# Requires SLACK_WEBHOOK env var.

[[ -z "${SLACK_WEBHOOK:-}" ]] && exit 0

INPUT=$(cat)
MSG=$(echo "$INPUT" | jq -r '.message // "Claude Code needs attention"')

curl -s -X POST "$SLACK_WEBHOOK" \
  -H 'Content-type: application/json' \
  -d "{\"text\": \":robot_face: *Claude Code*: ${MSG}\"}" \
  > /dev/null

exit 0
