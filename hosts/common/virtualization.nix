{
  pkgs,
  lib,
  ...
}: {
  virtualisation = {
    libvirtd.enable = true;
    spiceUSBRedirection.enable = true;
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

  networking.bridges."br0" = {
    interfaces = ["eno1"]; # Add eno1 to the bridge
    # Optional: You might want to set bridge priority, STP, etc. here if needed
    # settings = {
    #   ForwardDelay = 4;
    #   StpEnable = true;
    # };
  };

  # Also see modules/cpu-power.nix

  # CPU governor for consistent performance use systemd instead since cpufreq is unavailable
  # services.cpufreq = {
  #   enable = true;
  #   governor = "performance";
  # };

  # Set governor at boot using systemd service
  systemd.services.set-cpu-governor = {
    description = "Set CPU governor to performance";
    after = ["multi-user.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.linuxPackages.cpupower}/bin/cpupower frequency-set -g performance";
    };
  };

  environment.systemPackages = with pkgs; [
    pkgs.linuxPackages.cpupower # Ensure cpupower tool is available for governing performance
    virt-manager
    libguestfs
    spice
    spice-gtk
    virtiofsd # enable virtiofs for shared folders
    virt-viewer
    lm_sensors
    qemu
  ];

  # Firewall: open ports for VNC/SPICE access if needed
  networking.firewall.allowedTCPPorts = [5900 5901 5902];
}
