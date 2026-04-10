{...}: {
  # Elgato Stream Deck, Infinitton, and X-keys USB device permissions.
  # Allows non-root users in "plugdev" group to access HID devices
  # used by Bitfocus Companion.
  # Source: https://github.com/bitfocus/companion-pi/blob/main/50-companion.rules

  users.groups.plugdev = {};

  services.udev.extraRules = ''
    # Stream Deck (Elgato, vendor 0fd9)
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="0060", MODE:="666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="0063", MODE:="666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="006c", MODE:="666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="006d", MODE:="666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="0080", MODE:="666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="0084", MODE:="666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="0086", MODE:="666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="008f", MODE:="666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="0090", MODE:="666", GROUP="plugdev"
    KERNEL=="hidraw*", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="0060", MODE:="666", GROUP="plugdev"
    KERNEL=="hidraw*", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="0063", MODE:="666", GROUP="plugdev"
    KERNEL=="hidraw*", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="006c", MODE:="666", GROUP="plugdev"
    KERNEL=="hidraw*", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="006d", MODE:="666", GROUP="plugdev"
    KERNEL=="hidraw*", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="0080", MODE:="666", GROUP="plugdev"
    KERNEL=="hidraw*", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="0084", MODE:="666", GROUP="plugdev"
    KERNEL=="hidraw*", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="0086", MODE:="666", GROUP="plugdev"
    KERNEL=="hidraw*", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="008f", MODE:="666", GROUP="plugdev"
    KERNEL=="hidraw*", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="0090", MODE:="666", GROUP="plugdev"

    # Infinitton (vendor ffff)
    SUBSYSTEM=="usb", ATTRS{idVendor}=="ffff", ATTRS{idProduct}=="1f40", MODE:="666", GROUP="plugdev"
    KERNEL=="hidraw*", ATTRS{idVendor}=="ffff", ATTRS{idProduct}=="1f40", MODE:="666", GROUP="plugdev"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="ffff", ATTRS{idProduct}=="1f41", MODE:="666", GROUP="plugdev"
    KERNEL=="hidraw*", ATTRS{idVendor}=="ffff", ATTRS{idProduct}=="1f41", MODE:="666", GROUP="plugdev"

    # X-keys (vendor 05f3)
    SUBSYSTEM=="usb", ATTRS{idVendor}=="05f3", MODE:="666", GROUP="plugdev"
    KERNEL=="hidraw*", ATTRS{idVendor}=="05f3", MODE:="666", GROUP="plugdev"
  '';
}
