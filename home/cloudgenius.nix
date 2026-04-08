{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./hypr.nix
    ./waybar.nix
    ./localsend.nix
  ];

  home.username = "cloudgenius";
  home.homeDirectory = "/home/cloudgenius";
  home.stateVersion = "25.05";
  gtk.gtk4.theme = null;
  xdg.userDirs.setSessionVariables = false;

  programs.home-manager.enable = true;

  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    package = pkgs.bibata-cursors; # ensures theme is installed
    name = "Bibata-Modern-Ice";
    size = 60; # reduced from 96 to balance Wayland/XWayland appearance
  };

  # System-wide dark theme (Nord) for GTK + Qt
  gtk = {
    enable = true;
    theme = {
      name = "Nordic-darker";
      package = pkgs.nordic;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
  };

  # Qt theming via Kvantum (Nordic Kvantum theme is bundled in the nordic package)
  qt = {
    enable = true;
    platformTheme.name = "kvantum";
    style.name = "kvantum";
  };

  # Kvantum config: use the Nordic-Darker Kvantum theme

  xdg.configFile."Kvantum/kvantum.kvconfig".text = ''
    [General]
    theme=Nordic-Darker
  '';
  # Symlink the Nordic Kvantum theme from the nordic package
  xdg.configFile."Kvantum/Nordic-Darker".source = "${pkgs.nordic}/share/Kvantum/Nordic-Darker";

  # Solaar config for Logitech Bolt receiver (paired devices below).
  # Solaar persists device settings here; Home Manager owns this file.
  # To find key IDs: `solaar config "DEVICE" divert-keys`
  # To find available settings: `solaar config "DEVICE"`
  # After changing values here, rebuild + restart solaar for them to take effect.
  xdg.configFile."solaar/config.yaml".force = true;
  xdg.configFile."solaar/config.yaml".text = ''
    - 1.1.19
    # ── MX Keys Mini (keyboard) ──────────────────────────────────────────
    - _NAME: MX Keys Mini
      # _absent: features this device does NOT support (solaar skips them)
      _absent: [hi-res-scroll, lowres-scroll-mode, hires-smooth-invert, hires-smooth-resolution, hires-scroll-mode, scroll-ratchet, scroll-ratchet-torque, smart-shift,
        thumb-scroll-invert, thumb-scroll-mode, onboard_profiles, report_rate, report_rate_extended, pointer_speed, dpi, dpi_extended, speed-change, backlight-timed,
        led_control, led_zone_, rgb_control, rgb_zone_, brightness_control, per-key-lighting, reprogrammable-keys, persistent-remappable-keys, force-sensing,
        crown-smooth, divert-crown, divert-gkeys, m-key-leds, mr-key-led, gesture2-gestures, gesture2-divert, gesture2-params, haptic-level, haptic-play, sidetone,
        equalizer, adc_power_management]
      _battery: 4100                    # last-seen battery level (solaar internal)
      _modelId: B36900000000            # hardware model ID
      _sensitive: {hires-scroll-mode: ignore, hires-smooth-invert: ignore, hires-smooth-resolution: ignore}
      _serial: 56ABC2DE                 # device serial number
      _unitId: 56ABC2DE                 # device unit ID
      _wpid: B369                       # wireless PID
      backlight: 1                      # backlight mode: 1 = automatic
      backlight_duration_hands_in: 30   # seconds backlight stays on after typing
      backlight_duration_hands_out: 30  # seconds backlight stays on after hands leave
      backlight_duration_powered: 300   # seconds backlight stays on when plugged in
      backlight_level: 3                # brightness level (0-5)
      change-host: null                 # don't auto-switch host on startup
      # disable-keyboard-keys: 1=CapsLock, 8=Insert, 16=Win — all enabled (false)
      disable-keyboard-keys: {1: false, 8: false, 16: false}
      # divert-keys: 0 = Regular (OS gets the keypress), 1 = Diverted (solaar intercepts)
      # ALL set to Regular — Solaar divert is useless on Wayland.
      # In Regular mode with MacOS layout (multiplatform: 0):
      #   226=Backlight Down, 227=Backlight Up — firmware-handled (no HID event)
      #   229=Dictation — DEAD: no HID event in Regular mode on Wayland
      #   231=Emoji — sends Super+Ctrl+Space (bound in hyprland.conf → bemoji)
      #   232=ScreenCapture — sends Super+Shift+4 (bound in hyprland.conf → hyprshot)
      #   233=MicMute — DEAD: no HID event in Regular mode on Wayland
      #   259=Play/Pause — KEY_PLAYPAUSE (works)
      #   264=Mute — KEY_MUTE (works)
      #   266=VolDown — KEY_VOLUMEDOWN (works)
      #   279=Delete — standard Delete key
      #   284=VolUp — KEY_VOLUMEUP (works)
      divert-keys: {226: 0, 227: 0, 229: 0, 231: 0, 232: 0, 233: 0, 259: 0, 264: 0, 266: 0, 279: 0, 284: 0}
      fn-swap: true                     # true = F-keys are primary, Fn+F-key for media (swap Fx function)
      multiplatform: 1                  # OS mode: 0=Linux 1=MacOS 2=iOS 3=Chrome (no Windows on this KB; MacOS keeps Super left of spacebar)
    # ── MX Master 3S (mouse) ────────────────────────────────────────────
    - _NAME: MX Master 3S
      _modelId: B03400000000            # hardware model ID
      _serial: 6EAB6B99                 # device serial number
      _unitId: 6EAB6B99                 # device unit ID
      _wpid: B034                       # wireless PID
      # DPI: 200-8000 in steps of 50. Set device DPI to desired speed, keep
      # Hyprland sensitivity at 0 (no software scaling) for full sensor precision.
      # Try 1600/2400/3200 if too fast or slow.
      dpi: 4000
      # scroll-ratchet: Ratcheted = clicky detents, Freespinning = free scroll
      scroll-ratchet: Ratcheted
      # smart-shift: speed threshold (1-50) to auto-switch ratchet→freespin.
      # Lower = easier to trigger freespin. 50 = always ratcheted.
      smart-shift: 12
      # divert-keys: 0 = Regular (OS gets the click), 1 = Diverted (solaar rules handle it)
      #   82 = Middle Button:    Regular — normal middle-click
      #   83 = Back Button:      Regular — browser back (was Diverted, broke navigation)
      #   86 = Forward Button:   Regular — browser forward
      #  195 = Gesture Button:   Regular — sends mouse:277, bound in Hyprland to clipboard history
      #  196 = Smart Shift:      Diverted — ratchet/freespin toggle via solaar firmware
      # thumb-scroll-mode: false = thumb wheel sends normal horizontal scroll to compositor.
      # true = Diverted (sends HID++ to Solaar rules, breaks horizontal scrolling in apps).
      thumb-scroll-mode: false
      # hires-scroll-mode: false = main wheel sends normal scroll to compositor.
      hires-scroll-mode: false
      divert-keys: {82: 0, 83: 0, 86: 0, 195: 0, 196: 1}
  '';

  # GTK4 gtk.css is managed by theme-switch script (not HM) for live theme switching

  home.packages = with pkgs; [
    kitty
    vscode
    (pkgs.symlinkJoin {
      name = "google-chrome";
      paths = [pkgs.google-chrome];
      buildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/google-chrome-stable \
          --set LIBVA_DRIVER_NAME iHD \
          --add-flags "--ozone-platform=wayland" \
          --add-flags "--enable-features=WaylandWindowDecorations,VaapiVideoDecodeLinuxGL,VaapiVideoEncoder,AcceleratedVideoEncoder" \
          --add-flags "--ignore-gpu-blocklist" \
          --add-flags "--enable-gpu-rasterization" \
          --add-flags "--force-dark-mode"
      '';
    })
    papirus-icon-theme
    resilio-sync
    yt-dlp
    # claude-code # — managed via npm; nixpkgs 2.1.88 was yanked from registry
    prismlauncher
    nerd-fonts.jetbrains-mono
    (pkgs.writeShellScriptBin "nettools-help" ''
            #!/usr/bin/env bash
            set -euo pipefail
            cat <<'EOF'
      Legacy -> Modern (iproute2)
      ---------------------------------------------
      ifconfig            -> ip -c -br a    (or: ip addr)
      ifconfig eth0 up    -> ip link set eth0 up
      ifconfig eth0 1.2.3.4/24 -> ip addr add 1.2.3.4/24 dev eth0
      route -n            -> ip route show
      netstat -tulpn      -> ss -tulpn
      netstat -plant      -> ss -plant
      netstat -i          -> ip -s -h link
      arp -n              -> ip neigh
      # monitor changes
      ip monitor all

      Cheat aliases installed (if using bash in Home Manager):
        ifconfig, route, netstat, arp, iwconfig -> translated to ip/ss/iw equivalents
      Extra helpers:
        ifstats  (interface counters)
        netmon   (live routing/link/address events)

      More examples:
        # Add a route
        sudo ip route add 10.10.0.0/16 via 192.168.1.1

        # Flush DHCP address
        sudo ip addr flush dev eth0

        # Show IPv6 routes
        ip -6 route

        # Show policy routing rules / tables
        ip rule show
        ip route show table main
        ip route show table 100

        # Active listening sockets summary
        ss -ltunp

      EOF
    '')
  ];

  programs.git = {
    enable = true;
    settings.user.name = "Nilesh";
    settings.user.email = "nilesh@cloudgeni.us";

    settings.alias = {
      # Quality-of-life navigation / inspection
      st = "status -sb"; # short status
      s = "status";
      br = "branch";
      co = "checkout";
      cob = "checkout -b";
      sw = "switch";
      swc = "switch -c";
      cp = "cherry-pick";
      cpa = "cherry-pick --abort";
      cpc = "cherry-pick --continue";

      # Commits
      ci = "commit";
      com = "commit -m";
      amend = "commit --amend";
      amendn = "commit --amend --no-edit";
      ca = "commit -a -m";
      wip = "commit -am WIP";
      fixup = "commit --fixup";

      # Logs / diff
      lg = "log --graph --decorate --oneline --abbrev-commit";
      lga = "log --graph --decorate --oneline --abbrev-commit --all";
      last = "log -1 --stat";
      df = "diff";
      dff = "diff --name-only";
      dfc = "diff --cached";

      # Staging helpers
      unstage = "reset HEAD --"; # git unstage <path>
      discard = "checkout --"; # git discard <path>
      aa = "add -A";
      ap = "add -p";

      # Rebases / merges
      rb = "rebase";
      rbi = "rebase -i";
      rbc = "rebase --continue";
      rba = "rebase --abort";
      mt = "mergetool";

      # Reset / clean
      undo = "reset --soft HEAD~1";
      hard = "reset --hard";
      cleanall = "clean -fdx";

      # Stash
      ss = "stash";
      sl = "stash list";
      sa = "stash apply";
      sp = "stash pop";

      # Push / pull
      pl = "pull --ff-only";
      plr = "pull --rebase";
      ps = "push";
      psu = "push -u origin HEAD";
      please = "push --force-with-lease"; # safer than --force

      # Upstream & root info
      root = "rev-parse --show-toplevel";
      ahead = "rev-list --count @{u}..HEAD";
      behind = "rev-list --count HEAD..@{u}";
      where = "branch --show-current";
    };
  };
  programs.autojump = {
    enable = true;
  };

  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    defaultOptions = ["--height 40%" "--reverse" "--border"];
    historyWidgetOptions = ["--sort" "--exact"];
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    extraConfig = ''
      KeepAlive yes
    '';
    matchBlocks = {
      "*" = {
        addKeysToAgent = "yes";
        forwardAgent = true;
        serverAliveInterval = 60;
        extraOptions = {
          LogLevel = "ERROR";
        };
      };
      "192.168.1.* *.cg.home.arpa" = {
        extraOptions = {
          StrictHostKeyChecking = "off";
          UserKnownHostsFile = "/dev/null";
        };
      };
      "* !*.*" = {
        extraOptions = {
          StrictHostKeyChecking = "no";
          UserKnownHostsFile = "/dev/null";
        };
      };
      # --- Homelab (short names for VS Code Remote SSH + Tailscale MagicDNS) ---
      "asus" = {user = "cloudgenius";};
      "venus" = {user = "root";};
      "nuc" = {user = "cloudgenius";};
      "cosmos" = {user = "cloudgenius";};
      "imac" = {user = "cloudgenius";};
      "mini" = {user = "cloudgenius";};
      "chromebox" = {user = "cloudgenius";};
      "p1" = {user = "cloudgenius";};
      "m1" = {user = "stacey";};
      "msi" = {user = "cloudgenius";};
      "clara" = {user = "cloudgenius";};
      "clara-staging" = {user = "cloudgenius";};
      "docker-host" = {user = "cloudgenius";};
      "actions-runner" = {user = "cloudgenius";};
      "apps" = {user = "cloudgenius";};
      "t" = {user = "cloudgenius";};
      "u1.tail52f7b.ts.net" = {};
      "echo" = {
        hostname = "192.168.1.21";
        port = 8022;
        user = "u0_a147";
      };
      # --- Cloud ---
      "azure" = {
        hostname = "20.3.131.188";
        user = "cloudgenius";
      };
      "CloudGenius" = {
        hostname = "35.85.45.83";
        user = "ubuntu";
        forwardAgent = true;
        extraOptions.StrictHostKeyChecking = "no";
        identityFile = "~/.ssh/CloudGenius";
        localForwards = [
          {
            bind.port = 8080;
            host.address = "127.0.0.1";
            host.port = 80;
          }
          {
            bind.port = 4000;
            host.address = "127.0.0.1";
            host.port = 4000;
          }
        ];
      };
      "nat" = {
        hostname = "13.56.161.217";
        user = "ubuntu";
        forwardAgent = true;
        identityFile = "~/.ssh/id_rsa";
      };
      "app-0" = {
        hostname = "10.128.1.136";
        user = "ubuntu";
        forwardAgent = true;
        identityFile = "~/.ssh/id_rsa";
        proxyCommand = "ssh -q -W %h:%p nat";
      };
      "app-1" = {
        hostname = "10.128.1.122";
        user = "ubuntu";
        forwardAgent = true;
        identityFile = "~/.ssh/id_rsa";
        proxyCommand = "ssh -q -W %h:%p nat";
      };
    };
  };

  programs.bash = {
    enable = true;
    initExtra = ''
      # Autojump initialization for directory navigation with `j`
      [ -f "${pkgs.autojump}/share/autojump/autojump.sh" ] && . "${pkgs.autojump}/share/autojump/autojump.sh"

      # Up/Down arrow: search history by prefix already typed
      bind '"\e[A": history-search-backward'
      bind '"\e[B": history-search-forward'

      # Kitty SSH kitten only inside Kitty; plain ssh elsewhere (Foot etc.)
      [[ "$TERM" == "xterm-kitty" ]] && alias ssh='kitten ssh'
    '';
    shellAliases = {
      agenix = "agenix -i <(rbw get age-priv-key)";
      g = "git"; # enables `g st` etc. using defined git aliases
      open = "xdg-open"; # quick opener alias
      whatsapp = "google-chrome-stable --ozone-platform-hint=wayland --enable-features=UseOzonePlatform --app=https://web.whatsapp.com/";
      # Networking legacy-to-modern helpers
      ifconfig = "ip -c -br a"; # colorful brief address summary
      route = "ip route";
      netstat = "ss -tupan"; # show TCP/UDP listeners with PIDs
      arp = "ip neigh";
      iwconfig = "iw dev"; # quick wireless devices view
      # Quick interface stats similar to `netstat -i`
      ifstats = "ip -s -h link";
      # Monitor link/address/route events like 'ip monitor all'
      netmon = "ip monitor all";
      # Cross-machine clipboard via SSH (p1 = macOS, uses pbcopy/pbpaste)
      p1-paste = "ssh p1 pbpaste | wl-copy && echo 'p1 clipboard → asus'";
      p1-copy = "wl-paste | ssh p1 pbcopy && echo 'asus clipboard → p1'";
      m1-paste = "ssh m1 pbpaste | wl-copy && echo 'm1 clipboard → asus'";
      m1-copy = "wl-paste | ssh m1 pbcopy && echo 'asus clipboard → m1'";
    };
  };

  # Starship prompt — enabled here, config managed by theme-switch for live palette switching
  programs.starship.enable = true;

  programs.kitty = {
    enable = true;
    settings = {
      confirm_os_window_close = 0;
      # Use a patched Nerd Font so starship/Powerline glyphs render correctly
      # NOTE: fontconfig reports the NL (no ligatures) mono family as present: "JetBrainsMonoNL Nerd Font Mono"
      # We standardize on that to avoid fallback mismatches and boxes for Nerd glyphs.
      font_family = "SF Mono";
      font_size = 14.0;
    };
  };

  # Removed custom LocalSearch user services: upstream CLI no longer exposes
  # 'store' or 'miner' subcommands directly. We rely on the packaged
  # localsearch-3.service (Tracker daemon) which already runs.
  # Provide an init helper to ensure XDG directories are explicitly added
  # (idempotent) in minimal sessions where autostart rules may not run.
  systemd.user.services.localsearch-init = {
    Unit = {
      Description = "LocalSearch init: add XDG dirs and start miners";
      After = ["graphical-session.target"]; # run after login session
    };
    Service = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "localsearch-init.sh" ''
        set -euo pipefail
        BIN="${pkgs.localsearch}/bin/localsearch"
        # Add typical directories (ignore errors if already present)
        for d in "$HOME/Documents" "$HOME/Downloads" "$HOME/Pictures" "$HOME/Videos" "$HOME/Music"; do
          [ -d "$d" ] || continue
          $BIN index --add --recursive "$d" 2>/dev/null || true
        done
        # Start miners (safe if already running)
        $BIN daemon --start || true
      '';
      RemainAfterExit = true;
    };
    Install = {WantedBy = ["default.target"];};
  };

  # Provide default GTK bookmarks file to silence Nautilus warning.
  home.file.".config/gtk-3.0/bookmarks".text = ''
    file:///home/cloudgenius/Documents Documents
    file:///home/cloudgenius/Downloads Downloads
    file:///home/cloudgenius/Pictures Pictures
    file:///home/cloudgenius/Videos Videos
  '';

  # Home Manager XDG user dirs (system module unavailable on this channel)
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    desktop = "$HOME"; # avoid separate Desktop dir
    documents = "$HOME/Documents";
    download = "$HOME/Downloads";
    music = "$HOME/Music";
    pictures = "$HOME/Pictures";
    publicShare = "$HOME";
    templates = "$HOME";
    videos = "$HOME/Videos";
  };

  # Enforce Nordic dark for GTK apps
  home.sessionVariables = {
    GTK_THEME = "Nordic-darker";
  };

  # dconf: tell GNOME/libadwaita to prefer dark color scheme
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "Nordic-darker";
      text-scaling-factor = 1.5;
      font-name = "SF Pro Display 12";
    };
  };

  # VSCode Nord Dark theme configuration
  programs.vscode = {
    enable = true;
    profiles = {
      default = {
        extensions = with pkgs.vscode-extensions; [
          arcticicestudio.nord-visual-studio-code
          pkief.material-icon-theme
        ];
        userSettings = {
          "workbench.colorTheme" = "Nord";
          "workbench.preferredDarkColorTheme" = "Nord";
          "workbench.startupEditor" = "none";
          "editor.fontFamily" = "SF Mono, monospace";
          "editor.fontSize" = 14;
          "editor.fontLigatures" = true;
          "editor.bracketPairColorization.enabled" = true;
          "editor.semanticHighlighting.enabled" = true;
          "window.titleBarStyle" = "custom";
          # Prefer the mono patched variant for terminals so glyphs render correctly
          "terminal.integrated.fontFamily" = "SF Mono, monospace";
          "terminal.integrated.fontSize" = 14;
          "terminal.integrated.minimumContrastRatio" = 4.2;
          "workbench.iconTheme" = "material-icon-theme";
          "material-icon-theme.saturation" = 0;
          "material-icon-theme.folders.color" = "#81A1C1";
          "material-icon-theme.files.color" = "#88C0D0";
          "material-icon-theme.folders.theme" = "specific";
          "material-icon-theme.hidesExplorerArrows" = false;
          "files.trimTrailingWhitespace" = true;
          "files.insertFinalNewline" = true;
          "explorer.compactFolders" = false;
          "git.confirmSync" = false;
          "workbench.editor.tabCloseButton" = "left";
          "workbench.editor.tabActionLocation" = "left";
          # Disable update checks
          "update.mode" = "none";
          "update.showReleaseNotes" = false;
          "extensions.autoCheckUpdates" = false;
          "extensions.autoUpdate" = false;
        };
      };
    };
  };

  # Desktop entry for WhatsApp (Chrome app mode) so it shows as its own app in launchers
  xdg.desktopEntries.whatsapp = {
    name = "WhatsApp";
    genericName = "WhatsApp";
    comment = "WhatsApp Web (Chrome App)";
    exec = "google-chrome-stable --ozone-platform-hint=wayland --enable-features=UseOzonePlatform --app=https://web.whatsapp.com/";
    categories = ["Network" "InstantMessaging"];
    terminal = false;
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      # Documents
      # Evince correct desktop id is org.gnome.Evince.desktop (was evince.desktop)
      "application/pdf" = ["org.gnome.Evince.desktop"];
      "application/epub+zip" = ["org.gnome.Evince.desktop"];
      # Images
      # Images now handled by Eye of GNOME (eog)
      "image/jpeg" = ["org.gnome.eog.desktop"];
      "image/png" = ["org.gnome.eog.desktop"];
      "image/webp" = ["org.gnome.eog.desktop"];
      "image/gif" = ["org.gnome.eog.desktop"];
      "image/tiff" = ["org.gnome.eog.desktop"];
      "image/svg+xml" = ["org.gnome.eog.desktop"];
      # Video
      "video/mp4" = ["mpv.desktop"];
      "video/x-matroska" = ["mpv.desktop"];
      "video/x-msvideo" = ["mpv.desktop"];
      "video/webm" = ["mpv.desktop"];
      "video/quicktime" = ["mpv.desktop"];
      # Audio
      "audio/mpeg" = ["vlc.desktop"];
      "audio/flac" = ["vlc.desktop"];
      "audio/x-wav" = ["vlc.desktop"];
      "audio/ogg" = ["vlc.desktop"];
      # Text / code now default to gedit
      "text/plain" = ["org.gnome.gedit.desktop"];
      "text/markdown" = ["org.gnome.gedit.desktop"];
      "application/json" = ["org.gnome.gedit.desktop"];
      "application/x-yaml" = ["org.gnome.gedit.desktop"];
      "application/x-yml" = ["org.gnome.gedit.desktop"];
      "text/css" = ["org.gnome.gedit.desktop"];
      "application/xml" = ["org.gnome.gedit.desktop"];
      "text/html" = ["firefox.desktop"];
      "application/xhtml+xml" = ["firefox.desktop"];
      # Archives
      "application/zip" = ["org.gnome.FileRoller.desktop"];
      "application/x-xz" = ["org.gnome.FileRoller.desktop"];
      "application/x-bzip2" = ["org.gnome.FileRoller.desktop"];
      "application/gzip" = ["org.gnome.FileRoller.desktop"];
      "application/x-tar" = ["org.gnome.FileRoller.desktop"];
      # Folders
      "inode/directory" = ["org.gnome.Nautilus.desktop"];
      # Generic fallback
      "application/octet-stream" = ["org.gnome.Nautilus.desktop"];
    };
  };

  # Remove ad-hoc user override files that can fight with declarative defaults under Hyprland + non-Plasma session.
  home.activation.cleanMimeOverrides = lib.hm.dag.entryAfter ["writeBoundary"] ''
    echo "[activation] Cleaning conflicting mimeapps overrides" >&2
    rm -f "$HOME/.local/share/applications/mimeapps.list" "$HOME/.config/kde-mimeapps.list"
    rm -f "$HOME/.cache/mimeinfo.cache"
    rm -f "$HOME/.config/dolphinrc" "$HOME/.config/katerc" "$HOME/.config/gwenviewrc" "$HOME/.config/arkrc" || true
    rm -rf "$HOME/.cache/ksycoca6"* "$HOME/.cache/ksycoca5"* || true
  '';

  # Thunderbird with Google Calendar provider (Lightning calendar built-in upstream).
  programs.thunderbird = {
    enable = true;
    profiles.default = {
      isDefault = true;
      settings = {
        # Example preference: show week numbers in calendar
        "calendar.view.showWeekNumber" = true;
      };
      # Google Calendar provider extension not packaged in current nixpkgs set.
      # Install manually via: Add-ons Manager -> Extensions -> search "Provider for Google Calendar".
    };
  };
}
