{config, ...}: {
  # AMD GPU configuration
  services.xserver.videoDrivers = ["amdgpu"];
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  # Add any AMD-specific tweaks here
}
