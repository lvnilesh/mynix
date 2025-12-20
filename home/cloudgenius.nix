{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./hypr.nix
    ./waybar.nix
  ];

  home.username = "cloudgenius";
  home.homeDirectory = "/home/cloudgenius";
  home.stateVersion = "25.05";
  # home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    package = pkgs.bibata-cursors; # ensures theme is installed
    name = "Bibata-Modern-Ice";
    size = 60; # reduced from 96 to balance Wayland/XWayland appearance
  };

  # System-wide dark theme (Nord) for GTK + Qt
  # GTK theme package 'nordic' provides Nordic-Darker/Nordic-Dark variants.
  gtk = {
    enable = true;
    theme = {
      name = "Adwaita"; # built into GTK/libadwaita; no package needed (avoids missing gtk-4.0 css warning)
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
  };

  home.packages = with pkgs; [
    kitty
    vscode
    google-chrome
    papirus-icon-theme
    resilio-sync
    yt-dlp
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
  programs.bash = {
    enable = true;
    shellAliases = {
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
    };
  };

  # Starship prompt (Nord aligned)
  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      palette = "nord";
      palettes = {
        nord = {
          nord0 = "#2E3440";
          nord1 = "#3B4252";
          nord4 = "#D8DEE9";
          cyan = "#88C0D0";
          blue = "#81A1C1";
          green = "#A3BE8C";
          purple = "#B48EAD";
          yellow = "#EBCB8B";
          red = "#BF616A";
        };
      };
      # Removed time module and updated symbols; order kept concise
      format = "$directory$git_branch$git_status$nodejs$rust$python$cmd_duration\n$character";
      scan_timeout = 10; # ms per module scan to keep prompt snappy
      character = {
        success_symbol = "[➜](blue)"; # new primary prompt arrow
        error_symbol = "[✗](red)"; # clearer error indicator
        vicmd_symbol = "[«](purple)"; # normal mode indicator in modal shells
      };
      directory = {
        style = "bold cyan";
        truncation_length = 3;
        truncate_to_repo = true;
      };
      git_branch = {
        symbol = " "; # nerd font branch icon
        style = "blue";
      };
      git_status = {
        style = "yellow";
        conflicted = "⚔";
        ahead = "↑";
        behind = "↓";
        diverged = "⇅";
        staged = "+";
        modified = "~";
        renamed = "»";
        deleted = "✖";
        untracked = "?";
      };
      cmd_duration = {
        min_time = 500;
        format = "[⏱ $duration](purple)";
      };
      nodejs = {
        symbol = " ";
        style = "green";
      };
      python = {
        symbol = " ";
        style = "yellow";
      };
      rust = {
        symbol = " ";
        style = "red";
      };
    };
  };

  programs.kitty = {
    enable = true;
    settings = {
      confirm_os_window_close = 0;
      # Use a patched Nerd Font so starship/Powerline glyphs render correctly
      # NOTE: fontconfig reports the NL (no ligatures) mono family as present: "JetBrainsMonoNL Nerd Font Mono"
      # We standardize on that to avoid fallback mismatches and boxes for Nerd glyphs.
      font_family = "JetBrainsMonoNL Nerd Font Mono";
      font_size = 12.0;
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

  # Enforce Adwaita dark for GTK apps even if environment incomplete (Hyprland session)
  home.sessionVariables = {
    GTK_THEME = "Adwaita:dark"; # request dark variant properly
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
          "editor.fontFamily" = "JetBrainsMono Nerd Font, monospace";
          "editor.fontLigatures" = true;
          "editor.bracketPairColorization.enabled" = true;
          "editor.semanticHighlighting.enabled" = true;
          "window.titleBarStyle" = "custom";
          # Prefer the mono patched variant for terminals so glyphs render correctly
          "terminal.integrated.fontFamily" = "JetBrainsMono Nerd Font Mono, monospace";
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
        # Clear cache so xdg-mime re-evaluates
        rm -f "$HOME/.cache/mimeinfo.cache"
      # Remove obsolete KDE configs
      rm -f "$HOME/.config/dolphinrc" "$HOME/.config/katerc" "$HOME/.config/gwenviewrc" "$HOME/.config/arkrc" || true
      rm -rf "$HOME/.cache/ksycoca6"* "$HOME/.cache/ksycoca5"* || true
    # Purge Kvantum remnants
    rm -rf "$HOME/.config/Kvantum" || true
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
