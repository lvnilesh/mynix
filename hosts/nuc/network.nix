{lib, ...}: {
  networking.hostName = "nuc";
  networking.networkmanager.enable = true;
  networking.useDHCP = lib.mkDefault true;
}
