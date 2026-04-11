# gogcli — Google Workspace CLI (Gmail, Calendar, Contacts, Drive)
#
# Upstream: github.com/steipete/gogcli
# Binary: gog (from cmd/gog)
#
# Two commands installed:
#   gog       — raw binary, needs GOG_KEYRING_* env vars
#   gog-send  — wrapper that pre-loads keyring password from agenix
#
# First-time OAuth setup (interactive, as cloudgenius):
#   export GOG_KEYRING_BACKEND=file
#   export GOG_KEYRING_PASSWORD="$(cat /run/agenix/gog-keyring-password)"
#   gog auth credentials /run/agenix/gog-credentials
#   gog auth add sbh449@cloudgeni.us --services gmail,calendar,contacts
#
# Then copy credentials to hermes user:
#   sudo mkdir -p /var/lib/hermes/.config/gog
#   sudo cp -r ~/.config/gog/* /var/lib/hermes/.config/gog/
#   sudo chown -R hermes:hermes /var/lib/hermes/.config/gog/
{
  pkgs,
  config,
  ...
}: let
  gogcli = pkgs.buildGoModule rec {
    pname = "gogcli";
    version = "0.12.0";

    src = pkgs.fetchFromGitHub {
      owner = "steipete";
      repo = "gogcli";
      rev = "v${version}";
      hash = "sha256-KtjqZLR4Uf77865IGHFmcjwpV8GWkiaV7fBeTrsx93E=";
    };

    vendorHash = "sha256-8RKzJq4nlg7ljPw+9mtiv0is6MeVtkMEiM2UUdKPP3U=";

    env.CGO_ENABLED = 0;

    subPackages = ["cmd/gog"];

    ldflags = [
      "-s"
      "-w"
      "-X github.com/steipete/gogcli/internal/cmd.version=v${version}"
    ];

    meta = {
      description = "Google Suite CLI: Gmail, GCal, GDrive, GContacts";
      homepage = "https://github.com/steipete/gogcli";
      mainProgram = "gog";
    };
  };

  # Wrapper that pre-loads keyring secrets from agenix for non-interactive use
  gog-send = pkgs.writeShellScriptBin "gog-send" ''
    export GOG_KEYRING_BACKEND=file
    export GOG_KEYRING_PASSWORD="$(cat /run/agenix/gog-keyring-password)"
    exec ${gogcli}/bin/gog "$@"
  '';
in {
  environment.systemPackages = [gogcli gog-send];

  # Agenix secrets for gog
  age.secrets."gog-keyring-password" = {
    file = ../../secrets/gog-keyring-password.age;
    mode = "0640";
    owner = "hermes";
    group = "hermes";
  };
  age.secrets."gog-credentials" = {
    file = ../../secrets/gog-credentials.age;
    mode = "0640";
    owner = "hermes";
    group = "hermes";
  };
}
