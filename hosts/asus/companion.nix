{
  pkgs,
  lib,
  ...
}: let
  version = "4.2.6";
  buildId = "8823";
  commitHash = "4ecdfe70ba";
  companionTarball = pkgs.fetchurl {
    url = "https://s4.bitfocus.io/builds/companion/companion-linux-x64-${version}+${buildId}-stable-${commitHash}.tar.gz";
    # Will need to be filled in after first build attempt
    hash = "sha256-rRAXMFdjaqnF+4svxivTGY+7uu/QFBdOQ6GT1HEeoNo=";
  };
  companionHome = "/var/lib/companion";
in {
  # Bitfocus Companion v4.2.6 — headless systemd service.
  # Web UI at http://localhost:8000
  # Uses nix-ld for dynamic linking (libusb, udev already in nix-ld config).

  users.users.companion = {
    isSystemUser = true;
    group = "companion";
    home = companionHome;
    createHome = true;
    extraGroups = ["plugdev"];
    description = "Bitfocus Companion service user";
  };
  users.groups.companion = {};

  systemd.services.companion = {
    description = "Bitfocus Companion v${version}";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];

    environment = {
      HOME = companionHome;
      COMPANION_CONFIG_DIR = "${companionHome}/config";
    };

    path = [pkgs.hostname];
    serviceConfig = {
      Type = "simple";
      User = "companion";
      Group = "companion";
      SupplementaryGroups = ["plugdev"];
      WorkingDirectory = "${companionHome}/app/resources";
      ExecStartPre = pkgs.writeShellScript "companion-install" ''
        set -euo pipefail
        INSTALL_DIR="${companionHome}/app"
        if [ ! -f "$INSTALL_DIR/.version-${version}" ]; then
          rm -rf "$INSTALL_DIR"
          mkdir -p "$INSTALL_DIR"
          ${pkgs.gnutar}/bin/tar --use-compress-program=${pkgs.gzip}/bin/gzip -xf ${companionTarball} -C "$INSTALL_DIR" --strip-components=1
          touch "$INSTALL_DIR/.version-${version}"
        fi
      '';
      ExecStart = "${companionHome}/app/resources/node-runtimes/main/bin/node ${companionHome}/app/resources/main.js";
      Restart = "on-failure";
      RestartSec = 5;
      KillSignal = "SIGINT";
      TimeoutStopSec = 60;

      # Hardening
      ProtectHome = "read-only";
      PrivateTmp = true;
      NoNewPrivileges = true;
      ReadWritePaths = [companionHome];
    };
  };

  # Firewall: Companion web UI
  networking.firewall.allowedTCPPorts = [8000];
}
