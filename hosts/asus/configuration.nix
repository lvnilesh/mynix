{pkgs, ...}: {
  imports = [
    ./partials/audio.nix
    ./partials/bootloader.nix
    ./partials/compute.nix
    ./partials/displayManager.nix
    ./partials/hardware-configuration.nix
    ./partials/network.nix
    ./partials/openssh.nix
    ./partials/storage.nix
    ./partials/tz.nix
  ];

  services.printing.enable = true;

  # System user definition (group membership here)
  users.users.cloudgenius = {
    isNormalUser = true;
    description = "Nilesh";
    extraGroups = ["networkmanager" "wheel"];
  };

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = ["nix-command" "flakes"];

  system.stateVersion = "25.05";
  # system.stateVersion = "25.11";
}
