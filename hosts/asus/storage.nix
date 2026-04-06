{...}: {
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/75efcc2f-eebc-440e-8f27-c3a84b35aeb6";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/89F6-AADA";
    fsType = "vfat";
    options = ["fmask=0077" "dmask=0077"];
  };

  fileSystems."/data" = {
    device = "/dev/disk/by-uuid/6a34f4e8-7bed-4128-aadf-b9d447b8492f";
    fsType = "ext4";
  };

  swapDevices = [
    {device = "/dev/disk/by-uuid/74916f0a-05ee-4e47-9577-5f30c7dea78f";}
  ];
}
