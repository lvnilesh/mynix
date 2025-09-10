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

  home.packages = with pkgs; [
    kitty
    alacritty
    vscode
    google-chrome
  ];

  programs.git.enable = true;
  programs.zsh.enable = true;

  programs.kitty = {
    enable = true;
    settings = {
      confirm_os_window_close = 0;
    };
  };
}
