#!/bin/sh
input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name')
five=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_resets=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# Build a 10-character color-coded progress bar from a percentage value
make_bar() {
  pct="$1"
  filled=$(awk "BEGIN { x = int($pct / 10 + 0.5); if (x > 10) x = 10; print x }")
  empty=$((10 - filled))
  pct_int=$(printf "%.0f" "$pct")
  if [ "$pct_int" -ge 80 ]; then
    color="\033[38;5;196m"
  elif [ "$pct_int" -ge 60 ]; then
    color="\033[38;5;214m"
  else
    color="\033[38;5;82m"
  fi
  filled_chars=""
  i=0
  while [ "$i" -lt "$filled" ]; do filled_chars="${filled_chars}▓"; i=$((i + 1)); done
  empty_chars=""
  i=0
  while [ "$i" -lt "$empty" ]; do empty_chars="${empty_chars}░"; i=$((i + 1)); done
  printf "%b%s\033[0m%s" "$color" "$filled_chars" "$empty_chars"
}

# 5-hour session limit usage with reset time
five_resets=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
if [ -n "$five" ]; then
  five_pct=$(printf "%.0f" "$five")
  if [ -n "$five_resets" ]; then
    reset_time=$(TZ=Asia/Bangkok date -d "@${five_resets}" +%H:%M 2>/dev/null || TZ=Asia/Bangkok date -r "$five_resets" +%H:%M 2>/dev/null)
    five_display="5h:$(make_bar "$five") ${five_pct}% (resets ${reset_time})"
  else
    five_display="5h:$(make_bar "$five") ${five_pct}%"
  fi
else
  five_display=""
fi

# Weekly rate limit usage
if [ -n "$week" ]; then
  week_pct=$(printf "%.0f" "$week")
  if [ -n "$week_resets" ]; then
    reset_date=$(TZ=Asia/Bangkok date -d "@${week_resets}" +"%b %d %H:%M" 2>/dev/null || TZ=Asia/Bangkok date -r "$week_resets" +"%b %d %H:%M" 2>/dev/null)
    week_display="7d:$(make_bar "$week") ${week_pct}% (resets ${reset_date})"
  else
    week_display="7d:$(make_bar "$week") ${week_pct}%"
  fi
else
  week_display=""
fi

# Working directory (shorten $HOME to ~)
cwd=$(pwd | sed "s|^$HOME|~|")
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

# Combine parts
context="$cwd"
[ -n "$branch" ] && context="$context ($branch)"
parts="$context | $model"
[ -n "$five_display" ] && parts="$parts | $five_display"
[ -n "$week_display" ] && parts="$parts  $week_display"

printf "%s" "$parts"
