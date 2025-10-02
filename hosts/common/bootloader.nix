{
  pkgs,
  lib,
  ...
}: {
  # ===========================================================================
  # Bootloader Configuration with Secure Boot Support via Lanzaboote
  # ===========================================================================
  #
  # IMPORTANT: systemd-boot and lanzaboote are MUTUALLY EXCLUSIVE
  # Only ONE can be enabled at a time. They cannot coexist.
  #
  # Current State: INITIAL SETUP (systemd-boot enabled, lanzaboote disabled)
  #
  # Setup Process:
  # 1. Initial state (now):
  #    - systemd-boot.enable = true  (regular UEFI boot)
  #    - lanzaboote.enable = false   (Secure Boot disabled)
  #
  # 2. Create Secure Boot keys:
  #    sudo mkdir -p /etc/secureboot
  #    sudo sbctl create-keys
  #    sudo sbctl enroll-keys --microsoft
  #
  # 3. Switch to lanzaboote:
  #    Change the settings below to:
  #    - boot.loader.systemd-boot.enable = false;  (MUST disable systemd-boot)
  #    - boot.lanzaboote.enable = true;            (Enable Secure Boot)
  #    Then rebuild: ./redo
  #
  # 4. Enable Secure Boot in UEFI and reboot
  #
  # WHY THIS MATTERS:
  # - Lanzaboote is a systemd-boot replacement that adds Secure Boot signing
  # - Both tools manage the same EFI boot entries and boot loader files
  # - Having both enabled causes conflicts and build failures
  # - systemd-boot must be explicitly disabled (mkForce false) when enabling lanzaboote
  #
  # ===========================================================================

  # systemd-boot: Standard UEFI boot loader (no Secure Boot)
  # Use mkDefault so it can be easily overridden when switching to lanzaboote
  # boot.loader.systemd-boot.enable = lib.mkDefault true;

  # When enabling lanzaboote, uncomment this line to force disable systemd-boot:
  boot.loader.systemd-boot.enable = lib.mkForce false;

  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.enable = false;

  # Lanzaboote: Secure Boot enabled boot loader
  # Replaces systemd-boot entirely when enabled
  # Automatically signs kernel and initrd on each rebuild
  boot.lanzaboote = {
    enable = true; # Set to true ONLY after creating Secure Boot keys
    pkiBundle = "/etc/secureboot"; # Location of Secure Boot signing keys
  };

  # Required packages for Secure Boot management
  environment.systemPackages = with pkgs; [
    sbctl # Tool for creating and managing Secure Boot keys
  ];
}
