{pkgs, ...}: {
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    curl
    htop
    wget
    tree
    alejandra
    firefox
  ];
}
