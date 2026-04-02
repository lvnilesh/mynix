{
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 20; # Keep more generations for safe rollback
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.enable = false;

  # Garbage collect old generations (optional: run manually with `sudo nix-collect-garbage -d`)
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Nix store optimization — hardlink identical files to save disk
  nix.settings.auto-optimise-store = true;
}
