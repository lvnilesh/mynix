{
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 5; # Keep only 5 most recent generations in boot menu
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.enable = false;

  # Garbage collect old generations (optional: run manually with `sudo nix-collect-garbage -d`)
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d"; # Delete generations older than 14 days
  };
}
