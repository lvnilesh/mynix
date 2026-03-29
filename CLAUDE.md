# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A flake-based NixOS system configuration for two hosts (`asus` and `venus`) with integrated Home Manager for user `cloudgenius`. The `asus` host is an AI/ML workstation with dual NVIDIA GPUs (4090 + 1080 Ti) and Intel iGPU; `venus` is an AMD GPU secondary machine.

## Build & Deploy Commands

```bash
# Format and rebuild (primary workflow):
./redo                    # runs alejandra formatter + sudo nixos-rebuild switch --flake .#asus

# Manual rebuild:
sudo nixos-rebuild switch --flake ~/mynix#asus
sudo nixos-rebuild switch --flake ~/mynix#venus

# Update flake inputs:
nix flake update

# Dev shell (ffmpeg, mediainfo, jq, tcpdump, websocat):
nix develop
```

The Nix formatter is `alejandra` — always run it before rebuilding.

## Architecture

**Entry point**: `flake.nix` defines two NixOS configurations and a dev shell.

**Module graph**:
```
flake.nix
├── hosts/asus.nix          # Intel CPU, NVIDIA GPUs, PRIME offload
│   ├── hosts/asus/*.nix    # compute, network, storage
│   └── hosts/common/*.nix  # shared system modules
├── hosts/venus.nix         # AMD GPU variant
│   ├── hosts/venus/*.nix
│   └── hosts/common/*.nix
└── home/cloudgenius.nix    # Home Manager (themes, programs, dotfiles)
    ├── home/hypr.nix       # Hyprland + hyprpaper + waybar dotfile links
    └── home/waybar.nix     # Waybar systemd user service
```

**Shared modules** (`hosts/common/`): Each `.nix` file is a self-contained concern (audio, docker, nvidia, virtualization, smb-mounts, llamacpp, etc.). Host configs import only the modules they need.

**Dotfiles** (`dotfiles/`): Hyprland, Kitty, and Waybar configs live here and are symlinked into `~/.config/` by Home Manager via `home/hypr.nix`.

**Special args**: `hyprland` and `inputs` are passed through `specialArgs` to all NixOS modules.

## Key Services

- **llama.cpp** (`hosts/common/llamacpp.nix`): Qwen 27B on port 8001, Qwen 35B also on 8001 (conflicting — only one at a time), Nomic embeddings on port 8002
- **Twitter chatbot** (`hosts/common/twitter-chatbot.nix`): Custom Python API on port 3001
- **SMB mounts** (`hosts/common/smb-mounts.nix`): Auto-mount from cosmos/p1/truenas, credentials at `/etc/samba/creds-cloudgenius`, timer refresh every 30 min
- **Ollama** (`hosts/common/ollama.nix`): Model server

## Conventions

- System version is `25.11` for asus, `25.05` for venus
- Desktop is Wayland-first: Hyprland with GNOME/GDM fallback, NVIDIA-specific env vars in `display-manager.nix`-
- Home Manager state version is `25.05`
- PipeWire for audio with Focusrite Scarlett Solo as default device
- Nord theme throughout (Starship, GTK, VSCode, Kitty)
