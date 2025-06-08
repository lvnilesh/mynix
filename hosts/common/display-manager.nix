{
  pkgs,
  hyprland,
  ...
}: {
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  # services.displayManager.gdm.wayland = false; # default is true;
  services.desktopManager.gnome.enable = true;
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "cloudgenius";
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  environment.gnome.excludePackages = with pkgs; [
    geary
    gnome-calendar
    gnome-music
    gnome-tour
    gnome-weather
    gnome-clocks
    gnome-maps
    simple-scan
    totem
    gnome-characters
    gnome-sound-recorder
  ];

  # Configuration for Hyprland and GDM integration

  # Enable Hyprland as an optional session in GDM
  programs.hyprland = {
    enable = true;
    package = hyprland.packages.${pkgs.system}.default;
  };

  # Add Hyprland to the list of session packages for the display manager
  services.displayManager.sessionPackages = [pkgs.hyprland];
}
