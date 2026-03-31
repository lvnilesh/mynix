{
  pkgs,
  modulesPath,
  inputs,
  ...
}: {
  # Set system architecture
  nixpkgs.hostPlatform = "x86_64-linux";

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
    ./common/wake-on-lan.nix
    ./common/nix-ld.nix
    ./common/serial-perms.nix
    ./common/brother-printer.nix
    ./common/rgb.nix
    ./asus/llamacpp.nix
    ./common/ollama.nix
    ./asus/hermes-agent.nix
    ./asus/hermes-backup.nix
    ./asus/hermes-secrets.nix
    ./common/twitter-chatbot.nix
    ./common/document-tools.nix
  ];

  # Disable runtime PM for Thunderbolt 4 USB controller (Maple Ridge)
  # to prevent xHCI resume error loop that causes USB audio dropouts
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", KERNEL=="0000:3d:00.0", ATTR{power/control}="on"
  '';

  programs.gpu-screen-recorder.enable = true;
  services.printing.enable = true;
  services.tailscale.enable = true;
  services.twitter-chatbot.enable = true;
  security.sudo.wheelNeedsPassword = false;

  # Login MOTD — Vaultwarden / Hermes secrets reminder
  users.motd = ''
    ┌──────────────────────────────────────────────────────────────────┐
    │  Hermes Agent secrets — Vaultwarden single source of truth       │
    │                                                                  │
    │  Secrets are stored as a Bitwarden Secure Note named             │
    │  "hermes-agent-env" in vault.i.cloudgenius.app                   │
    │  (user: nilesh@cloudgeni.us).                                    │
    │                                                                  │
    │  Flow:                                                           │
    │    1. hermes-secrets.service runs as root                        │
    │    2. Calls rbw as cloudgenius (who has the registered vault)    │
    │    3. Writes secrets to /etc/hermes-agent/secrets.env            │
    │    4. hermes-agent.service merges into runtime .env              │
    │                                                                  │
    │  AFTER REBOOT run as cloudgenius:                                │
    │    rbw unlock                                                    │
    │    sudo systemctl restart hermes-secrets.service                 │
    │    sudo systemctl restart hermes-agent.service                   │
    │                                                                  │
    │  First-time setup:                                               │
    │    rbw config set base_url https://vault.i.cloudgenius.app       │
    │    rbw config set email nilesh@cloudgeni.us                      │
    │    rbw config set pinentry pinentry-curses                       │
    │    rbw config set lock_timeout 0                                 │
    │    # this disables auto-lock btw. not a good idea.               │
    │    rbw register                                                  │
    │    rbw unlock                                                    │
    └──────────────────────────────────────────────────────────────────┘
  '';

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
      "dialout" # serial devices
      "uucp" # alternative serial device group on some distros
      "hermes" # read /etc/hermes-agent/secrets.env for CLI usage
    ];
  };

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = ["nix-command" "flakes"];

  services.gnome.localsearch.enable = true;

  system.stateVersion = "25.11";
}
