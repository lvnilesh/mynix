# Crash Notes — Mar 27-28, 2026

## Crashes (Chronological Order)

| # | When | Process | Signal | Root Cause |
|---|------|---------|--------|------------|
| 1 | Mar 27 21:12 | Entire session | SIGTERM | User-initiated reboot; PipeWire X11 I/O error during teardown |
| 2 | Mar 28 10:23 | virt-manager | SIGSEGV | VNC library bug (libgvnc/libspice segfault) |
| 3 | Mar 28 16:26 | Ollama | SIGKILL | Manual `pkill -9 ollama` by user (freeing VRAM) |
| 4 | Mar 28 16:31 | Qwen27 | Clean exit | Graceful service restart |
| 5 | Mar 28 16:32 | Qwen27 | SIGKILL (137) | Killed ~34s after restart; manual or OOM |
| 6 | Mar 28 21:57 | Waybar | SIGSEGV | GTK3 + NVIDIA Wayland rendering crash |
| 7 | Mar 28 22:43 | Wofi | SIGSEGV | Race condition — launched before compositor fully ready |
| 8 | Mar 28 23:03 | Hyprland/GDM | SIGABRT | Mutex deadlock in gdm-wayland-session during user reboot |

## Recurring Patterns

- **GTK3 + NVIDIA Wayland segfaults** (waybar, wofi, virt-manager) — most concerning. Fix: set `GDK_BACKEND=wayland` to prevent mixed-mode fallback.
- **VRAM contention** — Ollama and Qwen27 fighting over 4090 VRAM, requiring manual kills. Fix: systemd `Conflicts=` between the two services.
- **Wofi startup race** — launched before compositor fully ready. Fix: add delay before wofi in Hyprland exec-once.

## Fixes Applied

- Added `GDK_BACKEND=wayland` to hyprland.conf env vars
- Added `conflicts = ["ollama.service"]` to qwen27 systemd service
- Added startup delay for wofi in hyprland.conf exec-once
