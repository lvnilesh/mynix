{pkgs, ...}: let
  # Apple SF Pro & SF Mono fonts (local, from ~/mynix/fonts/)
  apple-fonts = pkgs.stdenvNoCC.mkDerivation {
    pname = "apple-fonts";
    version = "1.0";
    src = ../../fonts;
    installPhase = ''
      mkdir -p $out/share/fonts/opentype
      cp *.otf *.ttf $out/share/fonts/opentype/
    '';
  };
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
  fonts.packages = [apple-fonts];

  environment.systemPackages = with pkgs; [
    # Core CLI
    rbw
    libopus
    age
    pinentry-curses
    vim
    wget
    git
    curl
    htop
    tree
    bitwarden-cli
    alejandra
    bat
    autojump
    dmidecode
    file
    which
    gnused
    gnutar
    gawk
    zstd
    bc

    # Remote desktop
    remmina

    # Browsers
    firefox

    # Media
    vlc
    mpv
    audacity
    easyeffects
    cava
    spotify
    playerctl
    imagemagick
    ffmpeg-full

    # Cloud CLIs
    (google-cloud-sdk.withExtraComponents [
      google-cloud-sdk.components.gke-gcloud-auth-plugin
      google-cloud-sdk.components.kubectl
    ])
    azure-cli
    awscli2
    hcloud

    # Libraries (for pygobject / compilation)
    libgtop
    libgtop.dev
    libnotify
    glib
    gobject-introspection
    cairo
    python3Packages.pycairo
    python3Packages.pygobject3

    # Notification daemon (mako for Hyprland/Wayland)
    mako

    # Terminal / shell
    fastfetch
    nnn

    # Archives
    zip
    xz
    unzip
    p7zip

    # Search / utils
    ripgrep
    jq
    yq-go
    eza
    fzf
    fd
    tldr

    # Development tools
    uv
    gh
    platformio-core
    python3
    ninja
    gcc
    pkg-config
    cmake
    jdk17
    gradle
    android-tools

    # Fonts
    meslo-lgs-nf
    nerd-fonts.droid-sans-mono
    nerd-fonts.fira-code
    jetbrains-mono
    noto-fonts-color-emoji
    nerd-fonts._0xproto

    # Infrastructure management
    ansible

    # Networking
    nmap
    mtr
    iperf3
    speedtest-cli
    tcpdump
    iw
    iproute2
    dnsutils
    ldns
    aria2
    socat
    ipcalc
    wakeonlan
    arp-scan

    # Nix tools
    nix-output-monitor

    # Productivity
    glow
    rustdesk
    rustdeskX11
    thunderbird
    localsend

    # Monitoring
    btop
    iotop
    iftop

    # Conferencing
    zoomWayland
    obsidian
    obsidianWayland

    # System call monitoring
    strace
    ltrace
    lsof

    # System tools
    sysstat
    lm_sensors
    ethtool
    pciutils
    usbutils
    efibootmgr
    mokutil
    efivar
    # blueman  # disabled — causes BLE scan storm on dbus

    # Hyprland desktop
    waybar
    pavucontrol
    nautilus
    wofi
    wlsunset
    eww
    xdg-desktop-portal
    xdg-desktop-portal-gtk
    swaybg
    swayidle
    pamixer
    brightnessctl
    brillo
    hyprshot
    hyprlock
    hypridle
    swayosd
    bemoji
    wtype
    cliphist
    wl-clipboard
    wf-recorder
    walker
    nwg-displays
    libinput

    # USB imaging / IoT
    popsicle
    balena-cli

    # File management / viewers
    evince
    xournalpp
    eog
    file-roller
    gedit
    localsearch

    # RGB lighting (liquidctl is primary; openrgb kept for GUI fallback)
    openrgb-with-all-plugins

    # Misc
    cowsay
    foot

    # Kitty terminal terminfo — allows correct cursor/line handling when
    # SSHing from a Kitty terminal (TERM=xterm-kitty) into this host.
    kitty.terminfo
  ];

  # LocalSend discovery (UDP) and file transfer (TCP)
  networking.firewall.allowedTCPPorts = [53317];
  networking.firewall.allowedUDPPorts = [53317];

  # Chrome managed policy directory for dynamic theme switching via BrowserThemeColor
  systemd.tmpfiles.rules = ["d /etc/opt/chrome/policies/managed 0755 root root -"];
}
