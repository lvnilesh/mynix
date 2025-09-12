{
  pkgs,
  hyprland,
  lib,
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

  # Add NVIDIA + Wayland specific environment variables early in session
  # Canonical cursor theme + size defined here (system-wide) and complemented by home.pointerCursor for GTK/XDG settings.
  environment.variables = {
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    LIBVA_DRIVER_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
    NVD_BACKEND = "direct";
    WLR_NO_HARDWARE_CURSORS = "1";
    # If crashes persist, try uncommenting next line to force GLES instead of Vulkan
    # WLR_RENDERER = "gles2";
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = "60";
    HYPRCURSOR_THEME = "Bibata-Modern-Ice";
    HYPRCURSOR_SIZE = "60";
    GDK_BACKEND = "wayland"; # remove x11 fallback so GTK prefers Wayland
    QT_QPA_PLATFORM = "wayland"; # ensure Qt native Wayland
  };

  # Ensure xdg portals including hyprland
  xdg.portal = {
    enable = true;
    # Removed pkgs.xdg-desktop-portal-hyprland to prevent duplicate user unit (xdg-desktop-portal-hyprland.service)
    # Hyprland's package already brings the portal/unit. Keep GTK for GTK apps fallback.
    extraPortals = [pkgs.xdg-desktop-portal-gtk];
  };

  security.pam.services = {
    login.kwallet.enable = lib.mkDefault true;
    gdm-password.kwallet.enable = lib.mkDefault true;
  };
}
