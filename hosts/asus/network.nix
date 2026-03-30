{
  config,
  lib,
  ...
}: {
  networking.hostName = "asus";
  networking.networkmanager.enable = true;

  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.eno1.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp0s20f3.useDHCP = lib.mkDefault true;

  # Enable Wake-on-LAN for ethernet interface
  networking.interfaces.eno1.wakeOnLan.enable = true;

  # Set higher route metric for USB NIC so br0 (metric 10) wins default route.
  # This ensures 192.168.1.14 (br0) is the primary IP for inbound services.
  networking.networkmanager.ensureProfiles.profiles.usb-nic = {
    connection = {
      id = "usb-nic";
      type = "ethernet";
      interface-name = "enp0s20f0u8u1";
    };
    ipv4 = {
      method = "auto";
      route-metric = "200";
    };
    ipv6 = {
      method = "auto";
      route-metric = "200";
    };
  };
}
