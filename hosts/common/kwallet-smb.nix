{
  config,
  pkgs,
  lib,
  ...
}: {
  # Add required packages for Dolphin SMB + password storage
  environment.systemPackages = with pkgs; [
    kio-extras
    kdePackages.kwallet
    kdePackages.kwalletmanager
    samba
    cifs-utils
  ];

  # Ensure Samba client libraries present (already by samba package) and enable minimal client config
  # Optional: place a minimal smb.conf if needed later.

  # Enable kwallet PAM integration so Dolphin can query stored creds seamlessly.
  security.pam.services = {
    login.kwallet.enable = lib.mkDefault true;
    gdm-password.kwallet.enable = lib.mkDefault true; # GDM password phase
  };

  # In case gdm service name differs, also enable generic gdm autologin keyring unlock (best effort)
  # security.pam.services.gdm-launch-environment.kwallet.enable = true;

  # Optionally let kwallet auto-migrate to new format
  # programs.kde.enable = lib.mkDefault true; # provides KDE runtime bits needed by wallet
}
