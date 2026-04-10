# Hermes Agent — self-improving AI agent framework by Nous Research.
#
# Uses the local Qwen model served by llama.cpp on port 8001.
#
# Usage:
#   hermes                    # interactive CLI
#   hermes setup              # re-run setup wizard (BLOCKED in managed mode)
#   hermes model              # switch model/provider (BLOCKED in managed mode)
#   systemctl status hermes-agent  # check gateway service
#
# Config: gateway at /var/lib/hermes/.hermes/config.yaml (managed by NixOS)
#         CLI at /home/cloudgenius/.hermes/config.yaml (separate copy)
# Secrets: config.age.secrets."hermes-env".path (via agenix)
#
# exa-py fix: using fork until upstream merges PR #4649
# Revert flake.nix to github:NousResearch/hermes-agent when merged.
# Tracked: https://github.com/NousResearch/hermes-agent/issues/4648
{
  config,
  inputs,
  pkgs,
  ...
}: let
  # Shared env block for MCP servers that need secrets from .env.
  # Hermes filters subprocess environments to a safe allowlist;
  # HERMES_HOME must be passed explicitly via the "env" key.
  mcpEnv = {HERMES_HOME = "/home/cloudgenius/.hermes";};

  # QMD — semantic markdown search for Brain vault
  qmd-wrapper = pkgs.writeShellScriptBin "qmd" ''
    export PATH="${pkgs.nodejs_22}/bin:$PATH"
    QMD_DIR="$HOME/.local/share/qmd"
    if [ ! -f "$QMD_DIR/node_modules/.bin/qmd" ]; then
      mkdir -p "$QMD_DIR"
      cd "$QMD_DIR"
      ${pkgs.nodejs_22}/bin/npm install @tobilu/qmd@2.1.0 --prefix "$QMD_DIR" 2>/dev/null
    fi
    exec "$QMD_DIR/node_modules/.bin/qmd" "$@"
  '';

  # Settings shared by both the gateway service and the interactive CLI.
  sharedSettings = {
    model = {
      default = "kai-os/Carnice-27b";
      provider = "custom";
      base_url = "http://localhost:8001/v1";
      context_length = 131072;
    };
    auxiliary.vision = {
      provider = "custom";
      model = "qwen2.5-vl-7b";
      base_url = "http://nuc:8001/v1";
      api_key = "sk-no-key-required";
      timeout = 300;
    };
    terminal.backend = "local";
    memory = {
      memory_enabled = true;
      user_profile_enabled = true;
      provider = "honcho";
    };
    honcho = {
      base_url = "http://localhost:8200";
      memory_mode = "hybrid";
      recall_mode = "hybrid";
    };
    display = {
      streaming = true;
      show_reasoning = true;
      personality = "kawaii";
    };
    mcp_servers = {
      brain = {
        command = "qmd";
        args = ["mcp"];
      };
      paperless = {
        command = "bash";
        args = [
          "-c"
          "source \$HERMES_HOME/.env && npx -y @nloui/paperless-mcp \$PAPERLESS_NGX_API_ENDPOINT \$PAPERLESS_NGX_TOKEN"
        ];
        env = mcpEnv;
      };
      md = {
        command = "bash";
        args = [
          "-c"
          "cd /home/cloudgenius/src/md && uv run md-mcp"
        ];
      };
      flux2-pro = {
        command = "bash";
        args = [
          "-c"
          "set -a && source \$HERMES_HOME/.env && set +a && uv run --with httpx --with mcp /home/cloudgenius/.hermes/mcp-servers/flux2-pro/server.py"
        ];
        env = mcpEnv;
      };
      # Disabled: HA lacks native MCP support (mcp/tools/list unknown command).
      # Re-enable when Home Assistant adds MCP integration.
      # homeassistant = {
      #   command = "bash";
      #   args = [
      #     "-c"
      #     "source \$HERMES_HOME/.env && HASS_WS=\$(echo \$HASS_URL | sed s/^http/ws/)/api/websocket && uvx mcp-server-home-assistant --url \$HASS_WS --token \$HASS_TOKEN"
      #   ];
      #   env = mcpEnv;
      # };
    };
  };

  # Generate a YAML config for the CLI user (separate from the gateway's copy).
  yamlFormat = pkgs.formats.yaml {};
  cliConfigFile = yamlFormat.generate "hermes-cli-config.yaml" sharedSettings;
in {
  imports = [inputs.hermes-agent.nixosModules.default];

  services.hermes-agent = {
    enable = true;
    addToSystemPackages = true;
    settings = sharedSettings;
    environmentFiles = [config.age.secrets."hermes-env".path];
  };

  # Ensure gateway starts after model backend and memory layer are ready
  systemd.services.hermes-agent = {
    after = ["carnice27.service" "honcho.service"];
    wants = ["carnice27.service" "honcho.service"];
    environment = {
      TELEGRAM_ALLOWED_USERS = "6366923819";
      AUXILIARY_VISION_PROVIDER = "custom";
      AUXILIARY_VISION_MODEL = "qwen2.5-vl-7b";
      AUXILIARY_VISION_BASE_URL = "http://nuc:8001/v1";
      AUXILIARY_VISION_API_KEY = "sk-no-key-required";
      AUXILIARY_VISION_TIMEOUT = "300";
    };
  };

  # QMD auto-index: re-index Brain vault every 5 minutes
  systemd.services.qmd-update = {
    description = "Re-index QMD Brain vault";
    serviceConfig = {
      Type = "oneshot";
      User = "cloudgenius";
      ExecStart = pkgs.writeShellScript "qmd-update" ''
        export PATH="${pkgs.nodejs_22}/bin:$PATH"
        QMD="$HOME/.local/share/qmd/node_modules/.bin/qmd"
        [ -x "$QMD" ] && $QMD update && $QMD embed --max-batch-mb 50
      '';
    };
  };
  systemd.timers.qmd-update = {
    description = "QMD Brain vault re-index timer";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "5min";
    };
  };

  # agenix CLI for editing encrypted secrets
  environment.systemPackages = [inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default qmd-wrapper];

  # CLI config.yaml is a symlink to a nix-generated file in the store.
  # Updates automatically on rebuild (e.g. after switch-model). Read-only by design
  # since config is nix-managed; hermes will log a harmless write error on exit.
  # Bridge: hermes-agent NixOS module expects "setupSecrets" activation script
  # (old agenix naming). Current agenix uses "agenixNewGeneration". Provide an
  # alias so the dependency resolves.
  system.activationScripts.setupSecrets = {
    text = ""; # no-op — agenix handles secrets via its own scripts
    deps = ["agenixNewGeneration"];
  };

  systemd.tmpfiles.rules = [
    "L+ /home/cloudgenius/.hermes/config.yaml - - - - ${cliConfigFile}"
    "L+ /home/cloudgenius/.hermes/.env - - - - /run/agenix/hermes-env"
  ];
}
