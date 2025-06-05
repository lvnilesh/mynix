{...}: {
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/98b1af2b-5a50-40ff-a77e-6dee2aa2c87a";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/F723-38FD";
    fsType = "vfat";
    options = ["fmask=0077" "dmask=0077"];
  };

  swapDevices = [
    {device = "/dev/disk/by-uuid/68fc8f96-6b0f-4c7f-aa40-059641f1a15e";}
  ];
}
