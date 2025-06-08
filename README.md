sudo nixos-rebuild switch -I nixos-config=$HOME/mynix/configuration.nix
nix-store --verify --check-contents
sudo nixos-rebuild switch --flake ~/mynix#asus
nixos-generate-config
echo $XDG_SESSION_TYPE

which GPU should hypr use?

lspci -d ::03xx
ls -l /dev/dri/by-path

env = AQ_DRM_DEVICES,/dev/dri/card2:/dev/dri/card0

hyprctl monitors
xrandr --listmonitors
wlrandr