{pkgs, ...}: let
  # Zoom wrapper launching with Wayland-friendly environment for Hyprland.
  # Provides a distinct desktop entry "Zoom (Wayland)".
  zoomWayland = pkgs.symlinkJoin {
    name = "zoom-wayland";
    paths = [
      (pkgs.writeShellScriptBin "zoom-wayland" ''
        #!${pkgs.bash}/bin/bash
        # Wayland + PipeWire wrapper for Zoom under Hyprland.
        # Enables: native Wayland, PipeWire camera/audio, portal-based screen share.

        # Prefer Wayland; fall back to X11 if it fails.
        export QT_QPA_PLATFORM=wayland
        export XDG_SESSION_TYPE=wayland
        export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
        # High DPI / scaling
        export QT_ENABLE_HIGHDPI_SCALING=1

        # PipeWire (camera & audio) – ensure PipeWire / wireplumber services are running system-wide.
        # Zoom still uses ALSA/Pulse internally; on NixOS Pulse is usually a PipeWire compat layer.
        export PIPEWIRE_LATENCY="128/48000"
        # Encourage usage of portals for screen sharing (xdg-desktop-portal + xdg-desktop-portal-wlr/hyprland/gtk already in systemPackages)
        export XDG_CURRENT_DESKTOP=Hyprland
        export XDG_SESSION_DESKTOP=Hyprland
        # Disable Wayland color management features that sometimes cause capture issues (optional)
        # export WLR_NO_HARDWARE_CURSORS=1  # Uncomment if cursor missing in shares

        # Optional: force portal for screen sharing (some apps honor this)
        export GTK_USE_PORTAL=1

        # Camera troubleshooting tip (uncomment if camera fails):
        # export LIBVA_DRIVER_NAME=nvidia

        exec ${pkgs.zoom-us}/bin/zoom "$@" || (
          echo "Wayland launch failed – retrying with X11 (xcb)" >&2;
          QT_QPA_PLATFORM=xcb exec ${pkgs.zoom-us}/bin/zoom "$@"
        )
      '')
      (pkgs.makeDesktopItem {
        name = "zoom-wayland";
        desktopName = "Zoom (Wayland)";
        genericName = "Zoom Video Conference";
        comment = "Zoom with Wayland + PipeWire (camera/audio/screen share) under Hyprland";
        categories = ["Network" "Chat" "Video"];
        exec = "zoom-wayland";
        icon = "Zoom"; # Icon from zoom-us package
        terminal = false;
        type = "Application";
      })
    ];
  };

  # Obsidian Wayland wrapper (Electron flags for smoother Wayland experience)
  obsidianWayland = pkgs.symlinkJoin {
    name = "obsidian-wayland";
    paths = [
      (pkgs.writeShellScriptBin "obsidian-wayland" ''
        #!${pkgs.bash}/bin/bash
        export XDG_SESSION_TYPE=wayland
        export XDG_CURRENT_DESKTOP=Hyprland
        export XDG_SESSION_DESKTOP=Hyprland
        export OZONE_PLATFORM=wayland
        export QT_QPA_PLATFORM=wayland
        # Optional: reduce input latency / enable VAAPI if desired
        # export ELECTRON_OZONE_PLATFORM_HINT=wayland
        # export LIBVA_DRIVER_NAME=nvidia
        exec ${pkgs.obsidian}/bin/obsidian \
          --enable-features=WaylandWindowDecorations \
          --ozone-platform=wayland \
          --enable-wayland-ime \
          "$@"
      '')
      (pkgs.makeDesktopItem {
        name = "obsidian-wayland";
        desktopName = "Obsidian (Wayland)";
        genericName = "Markdown Knowledge Base";
        comment = "Obsidian with native Wayland flags";
        categories = ["Office" "Utility" "TextEditor"];
        exec = "obsidian-wayland";
        icon = "obsidian";
        terminal = false;
        type = "Application";
      })
    ];
  };

  # RustDesk X11 wrapper: force X11 backend if Wayland causes input issues
  rustdeskX11 = pkgs.symlinkJoin {
    name = "rustdesk-x11";
    paths = [
      (pkgs.writeShellScriptBin "rustdesk-x11" ''
        #!${pkgs.bash}/bin/bash
        # Force RustDesk to use X11 backend when running under Wayland (Hyprland)
        # This can resolve certain keyboard/input or clipboard edge cases.
        unset WAYLAND_DISPLAY # discourage toolkits from picking Wayland
        export WINIT_UNIX_BACKEND=x11
        export QT_QPA_PLATFORM=xcb
        # Optional: disable Wayland-specific env that might linger
        export XDG_SESSION_TYPE=x11
        exec ${pkgs.rustdesk}/bin/rustdesk "$@"
      '')
      (pkgs.makeDesktopItem {
        name = "rustdesk-x11";
        desktopName = "RustDesk (X11)";
        genericName = "Remote Desktop";
        comment = "RustDesk forced to X11 backend";
        categories = ["Network" "RemoteAccess" "Utility"];
        exec = "rustdesk-x11";
        icon = "rustdesk"; # Provided by package
        terminal = false;
        type = "Application";
      })
    ];
  };
in {
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    curl
    htop
    wget
    tree
    alejandra
    firefox

    htop
    vlc
    unzip
    bat
    neofetch
    fastfetch
    dmidecode
    # albert
    (google-cloud-sdk.withExtraComponents [
      google-cloud-sdk.components.gke-gcloud-auth-plugin
      google-cloud-sdk.components.kubectl
    ])
    azure-cli
    awscli2
    # notify

    libgtop
    # Add the .dev output for header files needed for compilation
    libgtop.dev
    dunst # notify-send
    mako # notify-send
    libnotify # notify-send
    glib # notify-send

    # Packages that should be installed to the user profile.
    neofetch
    nnn # terminal file manager

    # archives
    zip
    xz
    unzip
    p7zip

    # utils
    ripgrep # recursively searches directories for a regex pattern
    jq # A lightweight and flexible command-line JSON processor
    yq-go # yaml processor https://github.com/mikefarah/yq
    eza # A modern replacement for ‘ls’
    fzf # A command-line fuzzy finder
    # Terminal utilities
    fd
    tldr
    bc
    # Development tools
    git
    gh
    platformio-core # embedded / microcontroller development (pio)

    meslo-lgs-nf # Standalone package
    nerd-fonts.droid-sans-mono
    nerd-fonts.fira-code
    jetbrains-mono
    noto-fonts-color-emoji
    nerd-fonts._0xproto
    nerd-fonts.droid-sans-mono

    # networking tools
    nmap
    mtr # A network diagnostic tool
    iperf3
    speedtest-cli # Internet speed test
    tcpdump # packet capture and analysis
    iw # configure and show wireless devices
    iproute2 # modern replacement providing ip, ss, bridge, tc, etc.
    dnsutils # `dig` + `nslookup`
    ldns # replacement of `dig`, it provide the command `drill`
    aria2 # A lightweight multi-protocol & multi-source command-line download utility
    socat # replacement of openbsd-netcat
    nmap # A utility for network discovery and security auditing
    ipcalc # it is a calculator for the IPv4/v6 addresses
    wakeonlan # send Wake-on-LAN magic packets
    arp-scan # ARP scanning and fingerprinting tool

    # misc
    cowsay
    file
    which
    tree
    gnused
    gnutar
    gawk
    zstd

    # nix related
    #
    # it provides the command `nom` works just like `nix`
    # with more details log output
    nix-output-monitor

    # productivity
    glow # markdown previewer in terminal
    rustdesk # remote desktop client/server (GUI)
    rustdeskX11 # wrapper forcing X11 backend
    thunderbird # full-featured email + calendar (Lightning), OpenPGP built-in
    localsend # cross-platform file sharing via local network

    btop # replacement of htop/nmon
    iotop # io monitoring
    iftop # network monitoring

    # conferencing / meetings (Wayland-wrapped Zoom; replaces bare zoom-us entry)
    zoomWayland
    obsidian
    obsidianWayland

    # system call monitoring
    strace # system call monitoring
    ltrace # library call monitoring
    lsof # list open files

    # busybox # this messes up grep # a single binary that provides several stripped-down Unix tools in a single executable

    # system tools
    sysstat
    lm_sensors # for `sensors` command
    ethtool
    pciutils # lspci
    usbutils # lsusb
    efibootmgr # EFI boot manager utility
    mokutil # MOK (Machine Owner Key) management for Secure Boot
    efivar # EFI variable manipulation tool
    blueman
    # blueman-utils

    # for pip install pygobject

    python3
    python3Packages.pygobject3
    playerctl
    gobject-introspection
    playerctl
    ninja
    gcc
    pkg-config
    cmake
    cairo
    python3Packages.pycairo

    waybar
    hyprpaper
    mako
    pavucontrol
    # Switched from Dolphin to Nautilus for GNOME-friendly file management
    nautilus
    wofi
    # Removed xdg-desktop-portal-hyprland (added via xdg.portal.extraPortals)
    wlsunset
    eww
    dunst
    xdg-desktop-portal
    xdg-desktop-portal-gtk
    playerctl
    # rofi
    kitty
    swaybg
    swayidle
    pamixer
    light
    brillo
    cava
    hyprshot
    spotify
    nwg-displays # generate monitor config for hyprland

    libinput
    # Flashing USB images – balenaEtcher attr missing in current nixpkgs; using popsicle instead
    popsicle
    # Balena CLI (for balenaCloud / openBalena)
    balena-cli

    samba
    cifs-utils
    evince
    xournalpp
    # Image viewer: use Eye of GNOME (eog) instead of Gwenview
    eog
    mpv
    audacity
    file-roller
    gedit
    localsearch # provides unified local search (replaces tracker-miners / tracker3 CLI)

    # RGB lighting control
    openrgb
    openrgb-with-all-plugins

    # Audio visualization and effects
    # cava # already listed above
    pulseeffects-legacy
    easyeffects
  ];
}
