{
  config,
  pkgs,
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
      name = "Nordic-Darker"; # try Nordic-Dark or Nordic if you prefer
      package = pkgs.nordic; # assumes nixpkgs attribute 'nordic'
    };
    iconTheme = {
      name = "Papirus-Dark"; # consistent icon set; can switch to Nordzy icon theme if desired
      package = pkgs.papirus-icon-theme;
    };
  };

  # Detect Kvantum availability; if absent, fall back to Adwaita-Dark for Qt
  qt = let
    kvantumPkg = pkgs.qt6Packages.kvantum-qt6 or null;
  in {
    enable = true;
    platformTheme = {name = "qtct";};
    style =
      if kvantumPkg != null
      then {
        name = "kvantum";
        package = kvantumPkg;
      }
      else {
        name = "Adwaita-Dark";
        package = pkgs.adwaita-qt;
      };
  };

  # Kvantum configuration to select Nordic theme for Qt apps
  home.file.".config/Kvantum/kvantum.kvconfig".text = ''
    [General]
    theme=Nordic-Darker
  '';

  home.packages = with pkgs; [
    kitty
    vscode
    google-chrome
    papirus-icon-theme
    nordic
    (pkgs.qt6Packages.kvantum-qt6 or pkgs.adwaita-qt)
  ];

  programs.git = {
    enable = true;
    aliases = {
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
          "editor.fontFamily" = "JetBrainsMono Nerd Font, monospace";
          "editor.fontLigatures" = true;
          "editor.bracketPairColorization.enabled" = true;
          "editor.semanticHighlighting.enabled" = true;
          "window.titleBarStyle" = "custom";
          "terminal.integrated.fontFamily" = "JetBrainsMono Nerd Font";
          "terminal.integrated.minimumContrastRatio" = 4.2;
          # Apply Nord-style Material Icon Theme tweaks
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
        };
      };
    };
  };
}
