#!/usr/bin/env bash
# Map Huion Kamvas 13 pen to its own monitor.
# The Kamvas is mounted upside-down (transform 2), so the pen digitizer
# needs the same 180° rotation. We look up the monitor by description
# so it works regardless of which DP port it lands on.
#
# Usage: run manually if DP port changes, or switch hyprland.conf
# from static device blocks to: exec-once = ~/.config/hypr/scripts/map-kamvas-pen.sh

sleep 2  # wait for monitors to settle

KAMVAS=$(hyprctl monitors -j \
  | python3 -c "import sys,json; [print(m['name']) for m in json.load(sys.stdin) if 'Kamvas' in m.get('description','')]" \
  2>/dev/null)

if [ -z "$KAMVAS" ]; then
  echo "Kamvas monitor not found, skipping pen mapping"
  exit 0
fi

hyprctl keyword "device[tablet-monitor-stylus]:output" "$KAMVAS"
hyprctl keyword "device[tablet-monitor-stylus]:transform" 2
hyprctl keyword "device[tablet-monitor]:output" "$KAMVAS"
hyprctl keyword "device[tablet-monitor]:transform" 2

echo "Pen mapped to $KAMVAS with transform 2"
