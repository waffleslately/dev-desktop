#!/usr/bin/env bash
# Prints CPU, RAM and battery (or disk if no battery).
# Supports optional argument: cpu | ram | bat (default: all on one line)

STAT_FILE="/tmp/.sysinfo_stat_${USER:-user}"

cpu() {
  local u2 n2 s2 i2 w2 q2 sq2
  read -r _ u2 n2 s2 i2 w2 q2 sq2 _ < /proc/stat
  if [ -r "$STAT_FILE" ]; then
    read -r u1 n1 s1 i1 w1 q1 sq1 < "$STAT_FILE"
    local dt=$(( (u2+n2+s2+i2+w2+q2+sq2) - (u1+n1+s1+i1+w1+q1+sq1) ))
    local di=$(( (i2+w2) - (i1+w1) ))
    echo "$u2 $n2 $s2 $i2 $w2 $q2 $sq2" > "$STAT_FILE"
    if [ "$dt" -gt 0 ]; then
      echo $(( 100*(dt-di)/dt ))
      return
    fi
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

case "$1" in
  cpu)
    echo "CPU $(cpu)%"
    ;;
  ram)
    echo "RAM $(ram)%"
    ;;
  bat)
    bat
    ;;
  *)
    echo "CPU $(cpu)%  RAM $(ram)%  $(bat)"
    ;;
esac
