# Minimal Home Manager config for headless servers (nuc, etc.)
# No desktop, no GUI, just shell essentials.
{pkgs, ...}: {
  home.username = "cloudgenius";
  home.homeDirectory = "/home/cloudgenius";
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    bat
    fd
    fzf
    eza
  ];
}
