#!/usr/bin/env bash
# Refreshes the stats every 2 seconds for i3bar.
while true; do
  echo "$("$HOME/.local/bin/sysinfo.sh")  |  $(date '+%a %d %b %H:%M')"
  sleep 2
done
