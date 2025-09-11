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

  programs.git.enable = true;
  programs.zsh.enable = true;

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
