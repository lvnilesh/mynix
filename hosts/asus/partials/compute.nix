{...}: {
  boot.initrd.availableKernelModules = ["xhci_pci" "ahci" "nvme" "thunderbolt" "usbhid" "usb_storage" "sd_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-intel"];
  boot.extraModulePackages = [];
}
