#!/usr/bin/env bash
if systemctl --user is-active --quiet waybar-caffeine.service; then
  systemctl --user stop waybar-caffeine.service
else
  systemctl --user start waybar-caffeine.service
fi