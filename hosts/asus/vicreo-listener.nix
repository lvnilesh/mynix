{
  pkgs,
  lib,
  ...
}: let
  listenerScript = ../../scripts/vicreo-listener.py;
in {
  # VICREO-compatible hotkey listener — systemd user service.
  # Runs as cloudgenius user within the Hyprland Wayland session
  # so wtype can access the compositor.
  # TCP port 10001, no password by default.

  # Install the listener script
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "vicreo-listener" ''
      exec ${pkgs.python3}/bin/python3 ${listenerScript} "$@"
    '')
  ];

  # ydotool daemon (needed for mouse simulation)
  programs.ydotool.enable = true;

  # Allow all users to access ydotool socket (needed for user services)
  systemd.services.ydotoold.serviceConfig.RuntimeDirectoryMode = lib.mkForce "0755";
  systemd.services.ydotoold.serviceConfig.ExecStart = lib.mkForce "${pkgs.ydotool}/bin/ydotoold --socket-path=/run/ydotoold/socket --socket-perm=0666";

  # Systemd user service — starts after graphical session
  systemd.user.services.vicreo-listener = {
    description = "VICREO-compatible hotkey listener";
    after = ["graphical-session.target"];
    wantedBy = ["graphical-session.target"];

    path = [pkgs.ydotool pkgs.bash pkgs.coreutils pkgs.glib];
    environment = {
      YDOTOOL_SOCKET = "/run/ydotoold/socket";
      XDG_CURRENT_DESKTOP = "Hyprland";
    };
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.python3}/bin/python3 ${listenerScript} --port 10001";
      Restart = "on-failure";
      RestartSec = 3;
    };
  };

  # Firewall: listener port
  networking.firewall.allowedTCPPorts = [10001];
}
