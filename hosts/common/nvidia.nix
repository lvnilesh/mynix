{config, ...}: {
  # NVIDIA production drivers for 4090 and 1080 Ti
  services.xserver.videoDrivers = ["nvidia"];

  # NVIDIA-specific Wayland env vars (moved from display-manager.nix so AMD hosts are unaffected)
  environment.variables = {
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    LIBVA_DRIVER_NAME = "nvidia";
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  hardware.graphics.enable = true;

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.production;
  };
}
