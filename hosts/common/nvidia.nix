{
  config,
  pkgs,
  ...
}: {
  # NVIDIA production drivers for 4090 and 1080 Ti
  services.xserver.videoDrivers = ["nvidia"];

  # Load Intel iGPU (i915) for VA-API video decode only — not for display driving.
  # The motherboard HDMI monitor (needed for UEFI) will also appear as a display.
  boot.initrd.kernelModules = ["i915"];

  # NVIDIA-specific Wayland env vars (moved from display-manager.nix so AMD hosts are unaffected)
  environment.variables = {
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    # Use Intel iGPU for VA-API video decode (browser video playback).
    # "nvidia" VA-API is broken for browser use; Intel iHD is excellent.
    LIBVA_DRIVER_NAME = "iHD";
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  hardware.graphics = {
    enable = true;
    # Intel VA-API driver so browsers can decode video on the iGPU
    extraPackages = with pkgs; [
      intel-media-driver # iHD — VA-API for Intel Gen 8+ (includes 14th-gen)
    ];
  };

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.production;
  };
}
