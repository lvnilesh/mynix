```
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
```


# Create this file manually  `/etc/samba/creds-cloudgenius`

```
username=cloudgenius
password=password
```
and then run `./redo`

# check GPU use
```
ps -ef | grep -E 'hypr|wayland|waybar|gdm|Xwayland' | grep -v grep
nvidia-smi
```

# stop gdm display hypr wayland etc

```
sudo systemctl stop display-manager.service
nvidia-smi
```

# restart gdm display hypr wayland etc

```
sudo systemctl start display-manager.service
nvidia-smis
```


# fresh install from minimal iso

# partition schemes for NixOS on /dev/sda (UEFI)
```
sudo -i
parted /dev/sda -- mklabel gpt
parted /dev/sda -- mkpart root ext4 512MB -64GB
parted /dev/sda -- mkpart swap linux-swap -64GB 100%
parted /dev/sda -- mkpart ESP fat32 1MB 512MB
parted /dev/sda -- set 3 esp on

# Installing NixOS on /dev/sda

```
mkfs.ext4 -L nixos /dev/sda1
mkswap -L swap /dev/sda2
swapon /dev/sda2
mkfs.fat -F 32 -n BOOT /dev/sda3        # (for UEFI systems only)
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot                      # (for UEFI systems only)
mount -o umask=077 /dev/disk/by-label/BOOT /mnt/boot # (for UEFI systems only)
nixos-generate-config --root /mnt
nano /mnt/etc/nixos/configuration.nix
nixos-install
reboot
```
