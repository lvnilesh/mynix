{
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./asus/compute.nix
    ./asus/network.nix
    ./asus/storage.nix

    ./common/apps.nix

    ./common/audio.nix
    ./common/bootloader.nix
    ./common/display-manager.nix
    # ./common/amd.nix  # For AMD GPUs
    ./common/nvidia.nix # For NVIDIA GPUs
    ./common/openssh.nix
    ./common/tz.nix
    # ./common/docker-amd.nix  # For AMD GPUs
    ./common/docker-nvidia.nix # For NVIDIA GPUs
    ./common/virtualization.nix
    ./common/ipv6.nix
    ./common/i2c-dev.nix
    ./common/resilio-sync.nix
    ./common/smb-mounts.nix
  ];

  services.printing.enable = true;

  # System user definition (group membership here)
  users.users.cloudgenius = {
    isNormalUser = true;
    description = "Nilesh";
    extraGroups = [
      "wheel" # Enable ‘sudo’ for the user.
      "networkmanager"
      "docker"
      "libvirtd"
      "audio"
      "video"
      "input"
      "kvm"
      "libvirt"
    ];
  };

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = ["nix-command" "flakes"];

  services.gnome.localsearch.enable = true;

  system.stateVersion = "25.05";
  # system.stateVersion = "25.11";
}
