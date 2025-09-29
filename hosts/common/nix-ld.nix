{pkgs, ...}: {
  # Enable nix-ld to supply a dynamic linker and common runtime libs for
  # pre-built binaries (e.g. PlatformIO toolchains) that expect FHS paths.
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      glibc # core C library / dynamic linker
      stdenv.cc.cc # provides libstdc++ & libgcc_s
      zlib
      openssl
      libusb1
      libffi
      xz
      # Prefer real systemd udev; libudev-zero is lighter but may miss features
      udev
    ];
  };
}
