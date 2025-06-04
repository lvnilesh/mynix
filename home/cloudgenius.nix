{
  config,
  pkgs,
  ...
}: {
  home.username = "cloudgenius";
  home.homeDirectory = "/home/cloudgenius";
  home.stateVersion = "25.05";
  # home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  home.sessionVariables = {
    # Add any session variables here if needed
  };

  home.packages = with pkgs; [
    kitty
    alacritty
    vscode
    google-chrome
  ];

  programs.git.enable = true;
  programs.zsh.enable = true;
}
