{ ... }: {
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/4f47c9a3-f61d-4cee-8f64-d38088a7056c";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/A315-BF00";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/470abbe0-ef13-45a7-aa84-f15ef9ad755d"; }
  ];
}
