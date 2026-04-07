{...}: {
  boot.initrd.availableKernelModules = ["xhci_pci" "ahci" "nvme" "thunderbolt" "usbhid" "usb_storage" "sd_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-intel"];
  boot.extraModulePackages = [];
  hardware.cpu.intel.updateMicrocode = true;

  # nvidia-drm.modeset=1: required for Wayland compositors (Hyprland) to use
  # NVIDIA DRM/KMS directly. Without it, Hyprland falls back to software cursor
  # and loses direct scanout.
  # nvidia-drm.fbdev=1: enable framebuffer device for console and GDM on NVIDIA.
  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    "nvidia-drm.fbdev=1"
    # Force EFI reboot — UEFI system; "bios" vector hangs after NVIDIA
    # releases the framebuffer, "efi" lets firmware handle the reset.
    "reboot=efi"
  ];
}
