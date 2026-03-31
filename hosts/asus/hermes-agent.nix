# Hermes Agent — self-improving AI agent framework by Nous Research.
#
# Uses the local Qwen model served by llama.cpp on port 8001.
#
# Usage:
#   hermes                    # interactive CLI
#   hermes setup              # re-run setup wizard
#   hermes model              # switch model/provider
#   hermes gateway            # start messaging gateway
#   systemctl status hermes-agent  # check gateway service
#
# Config: /var/lib/hermes/.hermes/config.yaml (managed by NixOS)
# Secrets: /etc/hermes-agent/secrets.env
{
  inputs,
  pkgs,
  ...
}: {
  imports = [inputs.hermes-agent.nixosModules.default];

  services.hermes-agent = {
    enable = true;
    addToSystemPackages = true;

    settings = {
      model = {
        default = "unsloth/Qwen3.5-27B";
        provider = "custom";
        base_url = "http://localhost:8001/v1";
        context_length = 131072;
      };
      terminal.backend = "local";
      memory = {
        memory_enabled = true;
        user_profile_enabled = true;
      };
    };

    environmentFiles = ["/etc/hermes-agent/secrets.env"];
  };

  # Symlink cloudgenius CLI .env to the vault-sourced secrets file.
  # cloudgenius is in the hermes group so can read the 640 root:hermes file.
  system.activationScripts.hermes-cli-env = ''
    rm -f /home/cloudgenius/.hermes/.env
    ln -sf /etc/hermes-agent/secrets.env /home/cloudgenius/.hermes/.env
  '';

  # Ensure secrets.env is merged into the hermes runtime .env on every
  # service start — not only at nixos-rebuild activation time.
  systemd.services.hermes-agent.serviceConfig.ExecStartPre = let
    mergeScript = pkgs.writeShellScript "merge-hermes-env" ''
      set -euo pipefail
      ENV_FILE="/var/lib/hermes/.hermes/.env"
      SRC="/etc/hermes-agent/secrets.env"
      if [ -f "$SRC" ]; then
        install -m 0600 -o hermes -g hermes /dev/null "$ENV_FILE"
        cat "$SRC" >> "$ENV_FILE"
      fi
    '';
  in ["${mergeScript}"];
}
