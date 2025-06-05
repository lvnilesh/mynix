{
  config,
  lib,
  ...
}: {
  networking.hostName = "venus";
  networking.networkmanager.enable = true;

  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.eno1.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp0s20f3.useDHCP = lib.mkDefault true;
}
