{
  lib,
  pkgs,
  ...
}: {
  # Serial development support:
  #  - udev rules from PlatformIO for common boards (/dev/ttyUSB*, /dev/ttyACM*)
  #  - User group membership handled directly in host files (asus.nix / venus.nix)
  #    so this module stays minimal and composable.
  services.udev.packages = lib.mkAfter [pkgs.platformio-core.udev];
}
