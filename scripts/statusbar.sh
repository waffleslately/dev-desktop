#!/usr/bin/env bash
# statusbar.sh – i3bar JSON protocol with click_events.
# Click CPU  → opens top in kitty
# Click RAM  → opens free -h in kitty
# Click clock/timer → toggles pomodoro
#
# Redraws immediately on SIGUSR1 (sent by pomodoro.sh).

SYSINFO="${HOME}/.local/bin/sysinfo.sh"
POMODORO="${HOME}/.local/bin/pomodoro.sh"
STAT_FILE="/tmp/.cpu_stat_${USER:-user}"
KITTY_CMD="env -u WAYLAND_DISPLAY LIBGL_ALWAYS_SOFTWARE=1 kitty"

# ── helpers ──────────────────────────────────────────────────────────────────
cpu() {
  local u2 n2 s2 i2 w2 q2 sq2
  read -r _ u2 n2 s2 i2 w2 q2 sq2 _ < /proc/stat
  if [ -r "$STAT_FILE" ]; then
    read -r u1 n1 s1 i1 w1 q1 sq1 < "$STAT_FILE"
    local dt=$(( (u2+n2+s2+i2+w2+q2+sq2) - (u1+n1+s1+i1+w1+q1+sq1) ))
    local di=$(( (i2+w2) - (i1+w1) ))
    echo "$u2 $n2 $s2 $i2 $w2 $q2 $sq2" > "$STAT_FILE"
    [ "$dt" -gt 0 ] && echo $(( 100*(dt-di)/dt )) && return
  fi
  echo "$u2 $n2 $s2 $i2 $w2 $q2 $sq2" > "$STAT_FILE"
  sleep 0.2
  read -r _ u3 n3 s3 i3 w3 q3 sq3 _ < /proc/stat
  local dt=$(( (u3+n3+s3+i3+w3+q3+sq3) - (u2+n2+s2+i2+w2+q2+sq2) ))
  local di=$(( (i3+w3) - (i2+w2) ))
  echo "$u3 $n3 $s3 $i3 $w3 $q3 $sq3" > "$STAT_FILE"
  echo $(( dt > 0 ? 100*(dt-di)/dt : 0 ))
}

ram() { free | awk '/Mem:/ {printf "%d", $3*100/$2}'; }

bat() {
  for b in /sys/class/power_supply/BAT*; do
    [ -r "$b/capacity" ] && { echo "BAT $(cat "$b/capacity")%"; return; }
  done
  echo "DISK $(df / | awk 'NR==2 {print $5}')"
}

pomo_str() {
  if [ -x "$POMODORO" ]; then
    "$POMODORO" status 2>/dev/null || echo "POMO 25:00"
  else
    echo "POMO 25:00"
  fi
}

pomo_color() {
  local s="$1"
  case "$s" in
    BREAK*) echo "#a6e3a1" ;;
    PAUSE*) echo "#f9e2af" ;;
    *)      echo "#cba6f7" ;;
  esac
}

cpu_color() {
  local v="$1"
  if   [ "$v" -ge 85 ]; then echo "#f38ba8"
  elif [ "$v" -ge 60 ]; then echo "#f9e2af"
  else                        echo "#89b4fa"
  fi
}

ram_color() {
  local v="$1"
  if   [ "$v" -ge 85 ]; then echo "#f38ba8"
  elif [ "$v" -ge 70 ]; then echo "#f9e2af"
  else                        echo "#a6e3a1"
  fi
}

emit() {
  local cpu_val ram_val bat_str pomo date_str
  cpu_val=$(cpu)
  ram_val=$(ram)
  bat_str=$(bat)
  pomo=$(pomo_str)
  date_str=$(date '+%a %d %b %H:%M')

  local cc rc pc
  cc=$(cpu_color "$cpu_val")
  rc=$(ram_color "$ram_val")
  pc=$(pomo_color "$pomo")

  local line
  line='['
  line="${line}{\"name\":\"cpu\",\"instance\":\"cpu\",\"full_text\":\" CPU ${cpu_val}%\",\"color\":\"${cc}\",\"separator\":false,\"separator_block_width\":12},"
  line="${line}{\"name\":\"ram\",\"instance\":\"ram\",\"full_text\":\"RAM ${ram_val}%\",\"color\":\"${rc}\",\"separator\":false,\"separator_block_width\":12},"
  line="${line}{\"name\":\"bat\",\"instance\":\"bat\",\"full_text\":\"${bat_str}\",\"color\":\"#f9e2af\",\"separator\":false,\"separator_block_width\":12},"
  line="${line}{\"name\":\"timer\",\"instance\":\"timer\",\"full_text\":\"${pomo}\",\"color\":\"${pc}\",\"separator\":false,\"separator_block_width\":12},"
  line="${line}{\"name\":\"clock\",\"instance\":\"clock\",\"full_text\":\"${date_str}\",\"color\":\"#cdd6f4\"}]"
  printf '%s\n' "$line"
}

# ── click-event handler (runs in background) ──────────────────────────────────
handle_clicks() {
  read -r   # consume opening bracket sent by i3bar
  while read -r ev; do
    ev="${ev#,}"   # strip leading comma on subsequent events
    local name button
    if [[ "$ev" =~ \"name\":[[:space:]]*\"([^\"]+)\" ]]; then
      name="${BASH_REMATCH[1]}"
    fi
    if [[ "$ev" =~ \"button\":[[:space:]]*([0-9]+) ]]; then
      button="${BASH_REMATCH[1]}"
    fi
    [ "$button" = "1" ] || continue   # only left-click
    case "$name" in
      cpu)
        env -u WAYLAND_DISPLAY LIBGL_ALWAYS_SOFTWARE=1 kitty --hold -e top &
        ;;
      ram)
        env -u WAYLAND_DISPLAY LIBGL_ALWAYS_SOFTWARE=1 kitty --hold -e free -h &
        ;;
      timer|clock)
        [ -x "$POMODORO" ] && "$POMODORO" toggle &
        # notify_bar is called inside pomodoro.sh, no extra signal needed
        ;;
    esac
    kill -SIGUSR1 $$ 2>/dev/null
  done
}

# ── main ─────────────────────────────────────────────────────────────────────
# Header
printf '{"version":1,"click_events":true}\n'
# Opening bracket for the infinite array
printf '[\n'

# Start click handler reading from stdin
handle_clicks &
CLICK_PID=$!

# Signal: redraw immediately
REDRAW=0
trap 'REDRAW=1' SIGUSR1

FIRST=1
while true; do
  if [ "$FIRST" -eq 1 ]; then
    emit
    FIRST=0
  else
    printf ','
    emit
  fi

  # Wait up to 2 s, waking early on SIGUSR1
  REDRAW=0
  read -r -t 2 _dummy </dev/null 2>/dev/null || true
  # If SIGUSR1 already fired during the read, REDRAW will be 1
  if [ "$REDRAW" -eq 0 ]; then
    # Extra sleep to fill remainder of the 2 s interval is already done by read -t 2
    :
  fi
done

# shellcheck disable=SC2317
wait "$CLICK_PID"
