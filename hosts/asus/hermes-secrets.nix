# Load Hermes Agent secrets from Vaultwarden via rbw (Bitwarden CLI).
#
# Secrets are stored as a Bitwarden Secure Note named "hermes-agent-env"
# in the vault at vault.i.cloudgenius.app (user: nilesh@cloudgeni.us).
#
# Flow:
#   1. hermes-secrets.service runs as root
#   2. Calls rbw as cloudgenius (who has the registered vault)
#   3. Writes secrets to /etc/hermes-agent/secrets.env (640 root:hermes)
#   4. hermes-agent.service activation script merges into runtime .env
#
# PREREQUISITE: rbw must be registered and unlocked once interactively as cloudgenius:
#   rbw config set base_url https://vault.i.cloudgenius.app
#   rbw config set email nilesh@cloudgeni.us
#   rbw config set pinentry pinentry-curses
#   rbw config set lock_timeout 0 # this disables auto-lock btw. not a good idea.
#   rbw register
#   rbw unlock
{pkgs, ...}: let
  rbw = pkgs.rbw;
  pinentry = pkgs.pinentry-curses;

  fetchScript = pkgs.writeShellScript "fetch-hermes-secrets" ''
    set -euo pipefail

    # Run rbw as cloudgenius (vault is registered under this user)
    RBW="${rbw}/bin/rbw"
    SUDO="${pkgs.sudo}/bin/sudo"

    # Sync and fetch as cloudgenius
    SECRETS=$($SUDO -u cloudgenius \
      env HOME=/home/cloudgenius \
          XDG_CONFIG_HOME=/home/cloudgenius/.config \
          XDG_DATA_HOME=/home/cloudgenius/.local/share \
          XDG_RUNTIME_DIR=/run/user/1001 \
          PATH="${rbw}/bin:${pinentry}/bin:$PATH" \
      $RBW get --full hermes-agent-env 2>/dev/null)

    if [ -z "$SECRETS" ]; then
      echo "ERROR: Failed to fetch hermes-agent-env from Vaultwarden" >&2
      echo "Make sure rbw is unlocked: sudo -u cloudgenius rbw unlock" >&2
      exit 1
    fi

    # Write atomically with correct ownership
    TMPFILE=$(mktemp /etc/hermes-agent/.secrets.env.XXXXXX)
    echo "$SECRETS" > "$TMPFILE"
    chown root:hermes "$TMPFILE"
    chmod 640 "$TMPFILE"
    mv "$TMPFILE" /etc/hermes-agent/secrets.env

    echo "Hermes secrets loaded from Vaultwarden ($(echo "$SECRETS" | wc -l) vars)"
  '';
in {
  environment.systemPackages = [rbw pinentry];

  systemd.services.hermes-secrets = {
    description = "Fetch Hermes secrets from Vaultwarden";
    wantedBy = ["multi-user.target"];
    before = ["hermes-agent.service"];
    requiredBy = ["hermes-agent.service"];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = fetchScript;
      RemainAfterExit = true;
    };
  };
}
