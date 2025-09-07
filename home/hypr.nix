{
  config,
  pkgs,
  ...
}: {
  #  wayland.windowManager.hyprland = {
  #    enable = true;
  #    extraConfig = builtins.readFile ../dotfiles/hyprland.conf;
  #  };

  # Link Hyprland config from dotfiles
  home.file.".config/hypr/hyprland.conf".source = ../dotfiles/hyprland.conf;

  home.file.".config/waybar/config".source = ../dotfiles/waybar/config;
  home.file.".config/waybar/style.css".source = ../dotfiles/waybar/style.css;
  home.file.".config/waybar/caffeine_status.sh".source = ../dotfiles/waybar/caffeine_status.sh;
  home.file.".config/waybar/caffeine_toggle.sh".source = ../dotfiles/waybar/caffeine_toggle.sh;
}
