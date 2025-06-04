sudo nixos-rebuild switch -I nixos-config=$HOME/mynix/configuration.nix
nix-store --verify --check-contents
sudo nixos-rebuild switch --flake ~/mynix#asus
nixos-generate-config
echo $XDG_SESSION_TYPE