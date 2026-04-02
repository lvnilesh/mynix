# Load Honcho secrets from Vaultwarden via rbw.
#
# Secrets are stored as a Bitwarden Secure Note named "honcho-env"
# in the vault at vault.i.cloudgenius.app (user: nilesh@cloudgeni.us).
#
# Flow:
#   1. honcho-secrets.service runs as root
#   2. Calls rbw as cloudgenius (who has the registered vault)
#   3. Fetches secret env vars (API keys only)
#   4. Merges with non-secret config and writes to /etc/honcho/env
#   5. honcho docker-compose reads from /etc/honcho/env
#
# PREREQUISITE: rbw must be unlocked (same as hermes-secrets)
{pkgs, ...}: let
  rbw = pkgs.rbw;
  pinentry = pkgs.pinentry-curses;

  fetchScript = pkgs.writeShellScript "fetch-honcho-secrets" ''
    set -euo pipefail

    RBW="${rbw}/bin/rbw"
    SUDO="${pkgs.sudo}/bin/sudo"

    # Fetch secrets from Vaultwarden as cloudgenius
    SECRETS=$($SUDO -u cloudgenius \
      env HOME=/home/cloudgenius \
          XDG_CONFIG_HOME=/home/cloudgenius/.config \
          XDG_DATA_HOME=/home/cloudgenius/.local/share \
          XDG_RUNTIME_DIR=/run/user/1001 \
          PATH="${rbw}/bin:${pinentry}/bin:$PATH" \
      $RBW get --full honcho-env 2>/dev/null)

    if [ -z "$SECRETS" ]; then
      echo "ERROR: Failed to fetch honcho-env from Vaultwarden" >&2
      echo "Make sure rbw is unlocked: sudo -u cloudgenius rbw unlock" >&2
      exit 1
    fi

    mkdir -p /etc/honcho

    # Non-secret config (providers, models, endpoints, dialectic levels)
    cat > /etc/honcho/env <<'CONFIG'
    DB_CONNECTION_URI=postgresql+psycopg://honcho:honcho@database:5432/honcho
    CACHE_ENABLED=true
    CACHE_URL=redis://redis:6379/0
    LLM_OPENAI_COMPATIBLE_BASE_URL=https://lvnil-mlwu2sq4-eastus2.cognitiveservices.azure.com/openai/v1
    LLM_EMBEDDING_PROVIDER=openai
    LLM_EMBEDDING_MODEL=text-embedding-3-small
    LLM_OPENAI_EMBEDDING_BASE_URL=https://ai-cg.cognitiveservices.azure.com/openai/v1
    DERIVER_PROVIDER=custom
    DERIVER_MODEL=gpt-5.4-mini
    SUMMARY_PROVIDER=custom
    SUMMARY_MODEL=gpt-5.4-mini
    DREAM_PROVIDER=custom
    DREAM_MODEL=gpt-5.4-mini
    DIALECTIC_LEVELS__minimal__PROVIDER=custom
    DIALECTIC_LEVELS__minimal__MODEL=gpt-5.4-mini
    DIALECTIC_LEVELS__minimal__THINKING_BUDGET_TOKENS=0
    DIALECTIC_LEVELS__minimal__MAX_TOOL_ITERATIONS=1
    DIALECTIC_LEVELS__minimal__MAX_OUTPUT_TOKENS=250
    DIALECTIC_LEVELS__low__PROVIDER=custom
    DIALECTIC_LEVELS__low__MODEL=gpt-5.4-mini
    DIALECTIC_LEVELS__low__THINKING_BUDGET_TOKENS=0
    DIALECTIC_LEVELS__low__MAX_TOOL_ITERATIONS=2
    DIALECTIC_LEVELS__low__MAX_OUTPUT_TOKENS=500
    DIALECTIC_LEVELS__medium__PROVIDER=custom
    DIALECTIC_LEVELS__medium__MODEL=gpt-5.4-mini
    DIALECTIC_LEVELS__medium__THINKING_BUDGET_TOKENS=0
    DIALECTIC_LEVELS__medium__MAX_TOOL_ITERATIONS=3
    DIALECTIC_LEVELS__medium__MAX_OUTPUT_TOKENS=1000
    DIALECTIC_LEVELS__high__PROVIDER=custom
    DIALECTIC_LEVELS__high__MODEL=gpt-5.4-mini
    DIALECTIC_LEVELS__high__THINKING_BUDGET_TOKENS=0
    DIALECTIC_LEVELS__high__MAX_TOOL_ITERATIONS=4
    DIALECTIC_LEVELS__high__MAX_OUTPUT_TOKENS=2000
    DIALECTIC_LEVELS__max__PROVIDER=custom
    DIALECTIC_LEVELS__max__MODEL=gpt-5.4-mini
    DIALECTIC_LEVELS__max__THINKING_BUDGET_TOKENS=0
    DIALECTIC_LEVELS__max__MAX_TOOL_ITERATIONS=5
    DIALECTIC_LEVELS__max__MAX_OUTPUT_TOKENS=4000
    AUTH_REQUIRED=false
    CONFIG

    # Strip leading whitespace from heredoc
    sed -i 's/^[[:space:]]*//' /etc/honcho/env

    # Append secrets
    echo "$SECRETS" >> /etc/honcho/env

    chown root:docker /etc/honcho/env
    chmod 640 /etc/honcho/env
    echo "Honcho env written to /etc/honcho/env ($(wc -l < /etc/honcho/env) vars)"
  '';
in {
  systemd.services.honcho-secrets = {
    description = "Fetch Honcho secrets from Vaultwarden";
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = fetchScript;
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = "10s";
      RestartMaxDelaySec = "60s";
    };
  };
}
