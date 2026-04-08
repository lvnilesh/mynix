# Hermes secrets via agenix — decrypted at boot using the SSH host key.
#
# No manual unlock required. Secrets are available immediately after boot.
#
# To edit secrets:
#   cd ~/mynix && agenix -e secrets/hermes.env.age -i ~/.config/age/keys.txt
#
# Source of truth: Vaultwarden "hermes-agent-env" note
# When you update Vaultwarden, also update the agenix secret to stay in sync.
{...}: {
  age = {
    identityPaths = ["/etc/ssh/ssh_host_ed25519_key"];

    secrets."hermes-env" = {
      file = ../../secrets/hermes.env.age;
      mode = "0640";
      owner = "hermes";
      group = "hermes";
    };
  };
}
