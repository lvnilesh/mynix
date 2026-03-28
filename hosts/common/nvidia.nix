{config, ...}: {
  # NVIDIA production drivers for 4090 and 1080 Ti
  services.xserver.videoDrivers = ["nvidia"];

  # Enable Intel iGPU for display output (monitor on motherboard)
  hardware.graphics.enable = true;

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.production;
    # PRIME: Intel iGPU for display, NVIDIA for offload/compute
    prime = {
      offload.enable = true;
      offload.enableOffloadCmd = true;
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };
}
