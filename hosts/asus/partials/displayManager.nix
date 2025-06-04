{pkgs, ...}: {
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
    weather
    simple-scan
    totem
    gnome-characters
  ];
}
