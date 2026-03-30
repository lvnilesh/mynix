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
{inputs, ...}: {
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
}
