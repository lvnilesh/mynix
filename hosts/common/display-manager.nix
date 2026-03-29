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
    package = hyprland.packages.${pkgs.system}.default; # use only the flake input build
  };

  # Removed services.displayManager.sessionPackages = [ pkgs.hyprland ]; to avoid two Hyprland versions.

  # Wayland session environment variables (GPU-agnostic).
  # NVIDIA-specific vars (__GLX_VENDOR_LIBRARY_NAME, LIBVA_DRIVER_NAME, WLR_NO_HARDWARE_CURSORS)
  # live in nvidia.nix so they are only applied on NVIDIA hosts.
  environment.variables = {
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = "60";
    HYPRCURSOR_THEME = "Bibata-Modern-Ice";
    HYPRCURSOR_SIZE = "60";
    GDK_BACKEND = "wayland";
    QT_QPA_PLATFORM = "wayland";
  };

  # Ensure xdg portals including hyprland
  xdg.portal = {
    enable = true;
    # Removed pkgs.xdg-desktop-portal-hyprland to prevent duplicate user unit (xdg-desktop-portal-hyprland.service)
    # Hyprland's package already brings the portal/unit. Keep GTK for GTK apps fallback.
    extraPortals = [pkgs.xdg-desktop-portal-gtk];
  };
}
