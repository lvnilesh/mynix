{...}: {
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/743f4ba1-f010-44db-9a96-6cae3906da80";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/0489-D0B1";
    fsType = "vfat";
    options = ["fmask=0077" "dmask=0077"];
  };

  fileSystems."/data" = {
    device = "/dev/disk/by-uuid/75efcc2f-eebc-440e-8f27-c3a84b35aeb6";
    fsType = "ext4";
  };

  swapDevices = [
    {device = "/dev/disk/by-uuid/2db2309a-81de-4668-973e-01fc7ef7ff77";}
  ];
}
