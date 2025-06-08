#!/usr/bin/env bash
if systemctl --user is-active --quiet waybar-caffeine.service; then
  echo '{"text": "☕", "icon": "☕", "class": "caffeine-on"}'
else
  echo '{"text": "💤", "icon": "💤", "class": "caffeine-on"}'
fi