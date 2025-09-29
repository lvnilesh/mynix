{pkgs, ...}: {
  # Enable OpenRGB package and udev rules for ASUS PRIME Z790-P WIFI
  # Note: Service disabled to avoid port conflicts with manual music-reactive scripts
  services.hardware.openrgb = {
    enable = false; # Disabled to prevent server conflicts
    motherboard = "intel"; # Intel Z790 chipset (i9-14900K)
  };

  # Add udev rules for ASUS Aura devices (PRIME Z790-P WIFI specific)
  services.udev.extraRules = ''
    # ASUS Aura LED Controller (PRIME Z790-P WIFI)
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0b05", ATTRS{idProduct}=="19af", MODE="0666", TAG+="uaccess"
    # Additional ASUS RGB devices
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0b05", MODE="0666", TAG+="uaccess"
    # Generic RGB device access
    SUBSYSTEM=="hidraw", KERNEL=="hidraw*", MODE="0666", TAG+="uaccess"
    # I2C devices for motherboard RGB (SMBus)
    SUBSYSTEM=="i2c-dev", MODE="0666", TAG+="uaccess"
    # ASUS Aura motherboard RGB via I2C
    KERNEL=="i2c-[0-9]*", MODE="0666", TAG+="uaccess"
    # G.Skill RGB RAM support (F5-6400J3239G32G detected)
    # G.Skill uses ENE controllers on i2c addresses 0x71, 0x73
    SUBSYSTEM=="i2c-dev", KERNEL=="i2c-0", MODE="0666", TAG+="uaccess"
  '';

  # System packages for RGB control and music visualization
  environment.systemPackages = with pkgs; [
    openrgb # RGB control software (currently crashing)
    openrgb-plugin-effects # Effects plugins

    # Alternative RGB control tools
    liquidctl # Alternative RGB/fan controller (supports many devices)
    i2c-tools # Direct I2C communication tools (i2cdetect, i2cset, i2cget)

    # G.Skill RGB RAM control tools
    # Note: G.Skill F5-6400J3239G32G detected - requires specific tools
    dmidecode # Hardware identification (already working)

    # Music visualization and audio processing
    pavucontrol # Audio control
    pulseaudio # For pactl commands
    alsa-utils # For audio monitoring

    # Python packages for custom audio-reactive scripts
    python3Packages.numpy
    python3Packages.scipy
    python3Packages.pyaudio
    python3Packages.smbus2 # Python I2C library for direct hardware control
  ];

  # Ensure the user is in required groups for hardware access
  users.users.cloudgenius.extraGroups = ["input" "audio" "i2c"];

  # Load necessary kernel modules
  boot.kernelModules = [
    "i2c-dev" # I2C device access for motherboard RGB
    "i2c-i801" # Intel I2C controller (Z790 chipset)
    "snd-aloop" # Audio loopback for monitoring
  ];

  # Enable hardware access
  hardware.i2c.enable = true;

  # Audio configuration for music reactive lighting (using existing PipeWire setup)
  # Note: Audio is already configured in audio.nix with PipeWire
  # No additional audio configuration needed here
}
