{...}: {
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/78b5c433-7fdb-4f0a-996d-34bd838cad18";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/1BA3-0F35";
    fsType = "vfat";
    options = ["fmask=0022" "dmask=0022"];
  };

  swapDevices = [];
}
