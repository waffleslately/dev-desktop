#!/usr/bin/env bash
# Prints CPU, RAM and battery (or disk if no battery) on one line.
cpu() {
  read -r _ u1 n1 s1 i1 w1 q1 sq1 _ < /proc/stat
  sleep 0.5
  read -r _ u2 n2 s2 i2 w2 q2 sq2 _ < /proc/stat
  local dt=$(( (u2+n2+s2+i2+w2+q2+sq2) - (u1+n1+s1+i1+w1+q1+sq1) ))
  local di=$(( (i2+w2) - (i1+w1) ))
  echo $(( dt > 0 ? 100*(dt-di)/dt : 0 ))
}
ram() { free | awk '/Mem:/ {printf "%d", $3*100/$2}'; }
bat() {
  for b in /sys/class/power_supply/BAT*; do
    [ -r "$b/capacity" ] && { echo "BAT $(cat "$b/capacity")%"; return; }
  done
  echo "DISK $(df / | awk 'NR==2 {print $5}')"
}
echo "CPU $(cpu)%  RAM $(ram)%  $(bat)"
