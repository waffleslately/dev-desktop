#!/usr/bin/env bash
# pomodoro.sh - 25m work / 5m break pomodoro timer for i3bar and keyboard shortcut

STATE_FILE="/tmp/pomodoro_${USER:-user}_state"

save_state() {
  local state="$1"
  local mode="$2"
  local end_time="$3"
  local rem="$4"
  echo "STATE=$state" > "$STATE_FILE"
  echo "MODE=$mode" >> "$STATE_FILE"
  echo "END_TIME=$end_time" >> "$STATE_FILE"
  echo "REMAINING=$rem" >> "$STATE_FILE"
}

load_state() {
  STATE="idle"
  MODE="work"
  END_TIME=0
  REMAINING=1500
  if [ -r "$STATE_FILE" ]; then
    # shellcheck disable=SC1090
    source "$STATE_FILE"
  fi
}

notify_bar() {
  :
}

get_status() {
  load_state
  local now
  now=$(date +%s)

  if [ "$STATE" = "running" ]; then
    local rem=$((END_TIME - now))
    if [ "$rem" -le 0 ]; then
      if [ "$MODE" = "work" ]; then
        MODE="break"
        END_TIME=$((now + 300))
        save_state "running" "$MODE" "$END_TIME" 300
        echo "BREAK 05:00"
      else
        save_state "idle" "work" 0 1500
        echo "POMO Done!"
      fi
      return
    fi
    local m=$((rem / 60))
    local s=$((rem % 60))
    if [ "$MODE" = "break" ]; then
      printf "BREAK %02d:%02d\n" "$m" "$s"
    else
      printf "POMO %02d:%02d\n" "$m" "$s"
    fi
  elif [ "$STATE" = "paused" ]; then
    local m=$((REMAINING / 60))
    local s=$((REMAINING % 60))
    printf "PAUSE %02d:%02d\n" "$m" "$s"
  else
    echo "POMO 25:00"
  fi
}

toggle() {
  load_state
  local now
  now=$(date +%s)

  if [ "$STATE" = "running" ]; then
    local rem=$((END_TIME - now))
    [ "$rem" -lt 0 ] && rem=0
    save_state "paused" "$MODE" 0 "$rem"
  elif [ "$STATE" = "paused" ]; then
    local new_end=$((now + REMAINING))
    save_state "running" "$MODE" "$new_end" "$REMAINING"
  else
    local new_end=$((now + 1500))
    save_state "running" "work" "$new_end" 1500
  fi
  notify_bar
  get_status
}

reset_timer() {
  save_state "idle" "work" 0 1500
  notify_bar
  get_status
}

case "${1:-status}" in
  status) get_status ;;
  toggle) toggle ;;
  reset|stop) reset_timer ;;
  start)
    load_state
    now=$(date +%s)
    save_state "running" "work" "$((now + 1500))" 1500
    notify_bar
    get_status
    ;;
  *) get_status ;;
esac
