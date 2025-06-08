{
  config,
  pkgs,
  ...
}: {
  # Enable i2c kernel modules
  boot.kernelModules = ["i2c-dev" "ddcci" "ddcci-backlight"];
  boot.extraModulePackages = with config.boot.kernelPackages; [ddcci-driver];

  # Install DDC utilities
  environment.systemPackages = with pkgs; [
    ddcutil
    i2c-tools # Add this for i2cdetect and related tools
  ];

  # Create groups for monitor control
  users.groups.ddc = {};
  users.groups.i2c = {};
  users.users.cloudgenius.extraGroups = ["ddc" "i2c"]; # Add both groups

  # Add udev rules for DDC permissions
  services.udev.extraRules = ''
    KERNEL=="i2c-[0-9]*", GROUP="ddc", MODE="0660"
  '';
}
