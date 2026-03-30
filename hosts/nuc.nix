# NUC — headless inference server
# Intel NUC8i7BEH + GTX 1080 Ti via Razer Core X (Thunderbolt 3 eGPU)
{
  config,
  pkgs,
  modulesPath,
  ...
}: {
  nixpkgs.hostPlatform = "x86_64-linux";

  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./nuc/compute.nix
    ./nuc/network.nix
    ./nuc/storage.nix
    ./nuc/services.nix

    ./common/bootloader.nix
    ./common/openssh.nix
    ./common/tz.nix
    ./common/nvidia.nix
    ./common/docker-nvidia.nix
    ./common/ipv6.nix
    ./common/nix-ld.nix
    ./common/wake-on-lan.nix
  ];

  # Thunderbolt eGPU: auto-authorize Razer Core X
  services.hardware.bolt.enable = true;
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="thunderbolt", ATTR{authorized}=="0", ATTR{authorized}="1"
  '';

  # eGPU kernel params
  boot.kernelParams = [
    "nvidia.NVreg_RegistryDwords=EnableBrightnessControl=0"
    "pci=realloc" # fix Thunderbolt NHI BAR conflict (EBUSY on 0000:04:00.0)
  ];

  # Headless — no display manager
  services.tailscale.enable = true;
  security.sudo.wheelNeedsPassword = false;

  users.users.cloudgenius = {
    isNormalUser = true;
    description = "Nilesh";
    extraGroups = [
      "wheel"
      "docker"
      "video"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAYzzsBsxKU1Ogg6Q33ChLQpqNkYYP39U8NKQTD1G81G cloudgenius@asus"
    ];
  };

  # Headless server packages
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
    htop
    btop
    jq
    bitwarden-cli
    ripgrep
    tree
    pciutils
    usbutils
    ethtool
    lm_sensors
    kitty.terminfo
  ];

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = ["nix-command" "flakes"];
  nix.settings.trusted-users = ["root" "cloudgenius"];

  system.stateVersion = "25.11";
}
