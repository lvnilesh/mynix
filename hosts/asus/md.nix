# md — Personal LLM Knowledge Base web server
#
# Clones from GitHub, sets up venv, runs the web UI + API on port 8070.
# Proxied via Traefik on cosmos as https://md.i.cloudgenius.app
#
# Usage:
#   sudo systemctl start md
#   sudo systemctl status md
#   journalctl -u md -f
#
# Update to latest code:
#   sudo systemctl restart md-setup   # re-clones + rebuilds venv
#   sudo systemctl restart md         # restart server
#
{pkgs, ...}: let
  user = "cloudgenius";
  homeDir = "/home/${user}";
  installDir = "/var/lib/md";
  venvPython = "${installDir}/.venv/bin/python";
  port = 8070;
  repo = "git@github.com:lvnilesh/md.git";
  branch = "main";
  # nix-ld library path for numpy/sentence-transformers native deps
  nixLdLib = "${pkgs.stdenv.cc.cc.lib}/lib";

  setupScript = pkgs.writeShellScript "md-setup" ''
    set -euo pipefail
    export PATH="${pkgs.git}/bin:${pkgs.python313}/bin:$PATH"
    export LD_LIBRARY_PATH="${nixLdLib}:''${LD_LIBRARY_PATH:-}"
    export HOME="${homeDir}"
    export GIT_SSH_COMMAND="${pkgs.openssh}/bin/ssh -i ${homeDir}/.ssh/id_ed25519 -o StrictHostKeyChecking=accept-new"

    # Clone or update repo
    if [ -d "${installDir}/.git" ]; then
      cd "${installDir}"
      ${pkgs.git}/bin/git fetch origin
      ${pkgs.git}/bin/git reset --hard origin/${branch}
    else
      ${pkgs.git}/bin/git clone --branch ${branch} ${repo} ${installDir}
    fi

    cd "${installDir}"

    # Create/update venv and install deps
    if [ ! -d .venv ]; then
      ${pkgs.python313}/bin/python3 -m venv .venv
    fi
    .venv/bin/pip install --quiet -e .
    .venv/bin/pip install --quiet "markitdown[pdf]" sentence-transformers
  '';
in {
  # Setup service: clones repo + builds venv (runs once before md starts)
  systemd.services.md-setup = {
    description = "md Knowledge Base - Setup/Update";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    requiredBy = ["md.service"];
    before = ["md.service"];

    environment = {
      LD_LIBRARY_PATH = nixLdLib;
      HOME = homeDir;
    };

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = user;
      Group = "users";
      ExecStart = setupScript;
      TimeoutStartSec = 300; # allow time for pip install
    };
  };

  # Main server service
  systemd.services.md = {
    description = "md Knowledge Base Server";
    after = ["network.target" "md-setup.service"];
    wants = ["network.target"];
    requires = ["md-setup.service"];
    wantedBy = ["multi-user.target"];

    environment = {
      LD_LIBRARY_PATH = nixLdLib;
      HOME = homeDir;
    };

    serviceConfig = {
      Type = "simple";
      User = user;
      Group = "users";
      WorkingDirectory = installDir;
      ExecStart = "${venvPython} -m md serve --host 0.0.0.0 --port ${toString port}";
      Restart = "on-failure";
      RestartSec = 10;

      # Hardening
      ProtectSystem = "strict";
      ProtectHome = "read-only";
      PrivateTmp = true;
      NoNewPrivileges = true;
      ReadWritePaths = [
        installDir # repo + venv
        "${homeDir}/md" # vault data directory
        "${homeDir}/.cache" # HuggingFace model cache
        "${homeDir}/.config/md"
      ];
    };
  };

  # Ensure install directory exists with correct ownership
  systemd.tmpfiles.rules = [
    "d ${installDir} 0755 ${user} users -"
  ];

  # Open firewall for LAN access
  networking.firewall.allowedTCPPorts = [port];
}
