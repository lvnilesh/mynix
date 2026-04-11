# Agenix recipients — who can decrypt secrets.
#
# Machine host keys: decrypt at boot (automatic, no manual unlock)
# Personal key:      decrypt for editing (loaded from Vaultwarden via rbw)
#
# To add a new machine:
#   cat /etc/ssh/ssh_host_ed25519_key.pub   (on the machine)
#   Add the ssh-ed25519 key below, then: cd ~/mynix && agenix -r
#
# To edit secrets from any machine:
#   rbw get age-priv-key > ~/.config/age/keys.txt && chmod 600 ~/.config/age/keys.txt
#   cd ~/mynix && agenix -e secrets/<file>.age -i ~/.config/age/keys.txt
let
  # Personal age key (stored in Vaultwarden as "age-priv-key")
  cloudgenius = "age1s60z4ck3ffekq99vkg2l28smnzmt4calv4w0ksn33az9dyyesqaskj0luf";

  # Machine SSH host keys (use directly — avoids ssh-to-age conversion issues)
  asus = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH2IiL9P2JzF9Leb5TERrmD4iejhtSG+Rnr9JtVJLmdO";

  admin = [cloudgenius];
in {
  "secrets/hermes.env.age".publicKeys = admin ++ [asus];
  "secrets/honcho.env.age".publicKeys = admin ++ [asus];
  "secrets/gog-keyring-password.age".publicKeys = admin ++ [asus];
  "secrets/gog-credentials.age".publicKeys = admin ++ [asus];
}
