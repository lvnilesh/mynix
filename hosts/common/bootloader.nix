{
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10; # Keep recent generations in boot menu
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.enable = false;

  # Garbage collect old generations (optional: run manually with `sudo nix-collect-garbage -d`)
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d"; # Delete generations older than 14 days
  };
}
