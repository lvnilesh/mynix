{
  pkgs,
  lib,
  ...
}: {
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        # OVMF images are now available by default with QEMU (no need to specify packages)
        # Legacy configuration (deprecated in NixOS 24.11+):
        # ovmf = {
        #   enable = true;
        #   packages = [pkgs.OVMFFull.fd]; # gives *secboot* firmware
        # };
        swtpm.enable = true;
      };
    };
    spiceUSBRedirection.enable = true;
  };

  # Provide generation-stable firmware paths under /etc so libvirt domain XML
  # does NOT embed a store hash that changes on each flake update. Use the 'ms'
  # (Microsoft keys) secure boot variant to match the vars template we copy below.
  environment.etc = {
    "ovmf/OVMF_CODE.ms.fd".source = "${pkgs.OVMFFull.fd}/FV/OVMF_CODE.ms.fd";
    "ovmf/OVMF_VARS.ms.fd".source = "${pkgs.OVMFFull.fd}/FV/OVMF_VARS.ms.fd";
  };

  users.groups.libvirtd = {};
  users.groups.kvm = {};

  networking.networkmanager.unmanaged = ["interface-name:eno1" "interface-name:br0"];

  networking.useDHCP = false; # Optional: Disable top-level DHCP if you configure all interfaces explicitly
  networking.interfaces.eno1 = {
    # Do NOT configure useDHCP or IP addresses here
    # This interface will be managed by the bridge
    # You might need specific L2 settings here eventually, but usually not.
  };

  networking.interfaces.br0 = {
    useDHCP = true; # Get IP address for the bridge interface
  };

  # Make br0 the primary route (lower metric = higher priority)
  networking.dhcpcd.extraConfig = ''
    interface br0
    metric 10
  '';

  networking.bridges."br0" = {
    interfaces = ["eno1"]; # Add eno1 to the bridge
    # Optional: You might want to set bridge priority, STP, etc. here if needed
    # settings = {
    #   ForwardDelay = 4;
    #   StpEnable = true;
    # };
  };

  # CPU governor — use NixOS-native option (persists across suspend/resume)
  powerManagement.cpuFreqGovernor = "performance";

  # Ensure nvram directory exists for QEMU VMs.
  # The win11_VARS.fd file is created by libvirt on first VM boot from the
  # OVMF_VARS template; no need to pre-seed it here.
  systemd.tmpfiles.rules = [
    "d /var/lib/libvirt/qemu/nvram 0750 qemu-libvirtd libvirtd -"
  ];

  environment.systemPackages = with pkgs; [
    virt-manager
    swtpm
    libguestfs
    spice
    spice-gtk
    virtiofsd
    xorriso
    openssl
    virt-viewer
    qemu
  ];

  # Firewall: open ports for VNC/SPICE access if needed
  networking.firewall.allowedTCPPorts = [5900 5901 5902];
}
