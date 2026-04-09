# Honcho secrets via agenix — decrypted at boot using the SSH host key.
#
# No manual unlock required. Secrets are available immediately after boot.
#
# To edit secrets:
#   cd ~/mynix && agenix -e secrets/honcho.env.age -i ~/.config/age/keys.txt
{...}: {
  age.secrets."honcho-env" = {
    file = ../../secrets/honcho.env.age;
    mode = "0640";
    owner = "root";
    group = "docker";
    path = "/etc/honcho/env";
  };
}
