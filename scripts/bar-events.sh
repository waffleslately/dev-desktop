#!/usr/bin/env bash
i3-msg -t subscribe -m '["workspace","window"]' | while read -r _; do
  pkill -USR1 -x statusbar.sh 2>/dev/null || true
done
