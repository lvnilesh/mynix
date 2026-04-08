{
  lib,
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
    ./common/logitech.nix
    ./asus/llamacpp.nix
    ./common/ollama.nix
    ./asus/hermes-agent.nix
    ./asus/hermes-secrets-agenix.nix
    ./asus/hermes-backup.nix
    ./common/chatbot.nix
    ./common/document-tools.nix
    ./common/home-assistant.nix
    ./common/promtail.nix
    ./asus/honcho-secrets.nix
    ./asus/honcho.nix
    ./asus/md.nix
  ];

  # Disable runtime PM for Thunderbolt 4 USB controller (Maple Ridge)
  # to prevent xHCI resume error loop that causes USB audio dropouts
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", KERNEL=="0000:3d:00.0", ATTR{power/control}="on"
  '';

  # RTX 4090 (Ada) only — use NVIDIA open kernel modules.
  # Shared nvidia.nix defaults to open=false for nuc's 1080 Ti (Pascal).
  hardware.nvidia.open = lib.mkForce true;

  programs.nano.enable = false;
  environment.variables.EDITOR = "vim";
  environment.variables.VISUAL = "vim";

  programs.gpu-screen-recorder.enable = true;
  services.printing.enable = true;
  services.tailscale.enable = true;
  hardware.bluetooth.enable = true;
  services.chatbot.enable = true;
  security.sudo.wheelNeedsPassword = false;

  # Hermes secrets reminder — shown only in interactive shells (not GDM)
  environment.interactiveShellInit = ''
    if [ -z "$HERMES_MOTD_SHOWN" ] && [ -n "$SSH_TTY" -o -n "$DISPLAY" -a -t 0 ]; then
      cat <<'MOTD'
    ┌──────────────────────────────────────────────────────────────────┐
    │  Secrets: agenix — auto-decrypted at boot (SSH host key)         │
    │  No manual unlock needed. Hermes starts automatically.           │
    │                                                                  │
    │  EDIT SECRETS:                                                   │
    │    cd ~/mynix && agenix -e secrets/hermes.env.age                │
    │    ./redo asus                                                   │
    │    (age key loaded from Vaultwarden "age-priv-key" via rbw)      │
    │                                                                  │
    │  SWITCH MODELS:                                                  │
    │    cd ~/mynix && ./switch-model gemma431   (or qwen27, qwen35)   │
    │                                                                  │
    │  Vault: vault.i.cloudgenius.app  (nilesh@cloudgeni.us)           │
    │                                                                  │
    │  AFTER OS REINSTALL (host key changes):                          │
    │    Update SSH key in secrets.nix, then: agenix -r && ./redo asus │
    └──────────────────────────────────────────────────────────────────┘
    MOTD
      export HERMES_MOTD_SHOWN=1
    fi
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
