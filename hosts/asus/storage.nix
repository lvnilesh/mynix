{...}: {
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/4f47c9a3-f61d-4cee-8f64-d38088a7056c";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/A315-BF00";
    fsType = "vfat";
    options = ["fmask=0077" "dmask=0077"];
  };

  # NVMe data drives
  # nvme-2tb now has Windows installed - commented out
  # fileSystems."/mnt/nvme-2tb" = {
  #   device = "/dev/disk/by-uuid/d191e724-2ab0-4fd5-9c6b-3f732d9b0a18";
  #   fsType = "ext4";
  #   options = ["defaults" "nofail"];
  # };

  fileSystems."/mnt/nvme-1tb" = {
    device = "/dev/disk/by-uuid/ecf00eae-cf47-40c8-9bea-b47dd32d98ee";
    fsType = "ext4";
    options = ["defaults" "nofail"];
  };

  swapDevices = [
    {device = "/dev/disk/by-uuid/470abbe0-ef13-45a7-aa84-f15ef9ad755d";}
  ];
}
