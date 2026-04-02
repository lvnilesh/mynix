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
#
# exa-py fix: using fork until upstream merges PR #4649
# Revert flake.nix to github:NousResearch/hermes-agent when merged.
# Tracked: https://github.com/NousResearch/hermes-agent/issues/4648
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

  # Fix permissions so hermes (in users group) can traverse cloudgenius's
  # home and .hermes dirs. Root-owns .hermes dirs so hermes CLI's
  # _secure_dir(os.chmod 0o700) fails with EPERM and is silently ignored.
  # Both cloudgenius and hermes access via users group (770).
  system.activationScripts.hermes-home-perms = {
    deps = ["users" "groups"];
    text = ''
      chmod 750 /home/cloudgenius
      chown root:users /home/cloudgenius/.hermes
      chmod 770 /home/cloudgenius/.hermes
      chown root:users /home/cloudgenius/.hermes/cron
      chmod 770 /home/cloudgenius/.hermes/cron
      chown root:users /home/cloudgenius/.hermes/cron/output 2>/dev/null || true
      chmod 770 /home/cloudgenius/.hermes/cron/output 2>/dev/null || true
    '';
  };

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

  # Add hermes user to users group so it can read cloudgenius's .hermes directory
  # This allows the gateway to access cron jobs in /home/cloudgenius/.hermes/cron/
  users.extraUsers.hermes.extraGroups = ["users"];

  # Symlink gateway's cron dir to cloudgenius CLI's copy so both share one
  # jobs.json. tmpfiles 'L+' removes any existing dir/file before linking.
  systemd.tmpfiles.rules = [
    "L+ /var/lib/hermes/.hermes/cron - - - - /home/cloudgenius/.hermes/cron"
  ];

  # Watch jobs.json for changes and fix permissions immediately.
  # hermes CLI save_jobs() uses mkstemp+rename which creates files as 600.
  # This inotify-based watcher triggers within milliseconds — no polling.
  systemd.paths.hermes-cron-perms = {
    wantedBy = ["paths.target"];
    pathConfig.PathChanged = "/home/cloudgenius/.hermes/cron/jobs.json";
  };
  systemd.services.hermes-cron-perms = {
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.coreutils}/bin/chmod 640 /home/cloudgenius/.hermes/cron/jobs.json";
    };
  };
}
