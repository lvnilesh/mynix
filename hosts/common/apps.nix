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

    htop
    vlc
    unzip
    bat
    neofetch
    fastfetch
    # albert
    (google-cloud-sdk.withExtraComponents [
      google-cloud-sdk.components.gke-gcloud-auth-plugin
      google-cloud-sdk.components.kubectl
    ])
    azure-cli
    awscli2
    # notify

    libgtop
    # Add the .dev output for header files needed for compilation
    libgtop.dev
    dunst # notify-send
    mako # notify-send
    libnotify # notify-send
    glib # notify-send

    # Packages that should be installed to the user profile.
    neofetch
    nnn # terminal file manager

    # archives
    zip
    xz
    unzip
    p7zip

    # utils
    ripgrep # recursively searches directories for a regex pattern
    jq # A lightweight and flexible command-line JSON processor
    yq-go # yaml processor https://github.com/mikefarah/yq
    eza # A modern replacement for ‘ls’
    fzf # A command-line fuzzy finder
    # Terminal utilities
    fd
    tldr

    # Development tools
    git
    gh

    meslo-lgs-nf # Standalone package
    nerd-fonts.droid-sans-mono
    nerd-fonts.fira-code
    jetbrains-mono
    noto-fonts-emoji
    nerd-fonts._0xproto
    nerd-fonts.droid-sans-mono

    # networking tools
    nmap
    mtr # A network diagnostic tool
    iperf3
    dnsutils # `dig` + `nslookup`
    ldns # replacement of `dig`, it provide the command `drill`
    aria2 # A lightweight multi-protocol & multi-source command-line download utility
    socat # replacement of openbsd-netcat
    nmap # A utility for network discovery and security auditing
    ipcalc # it is a calculator for the IPv4/v6 addresses

    # misc
    cowsay
    file
    which
    tree
    gnused
    gnutar
    gawk
    zstd

    # nix related
    #
    # it provides the command `nom` works just like `nix`
    # with more details log output
    nix-output-monitor

    # productivity
    glow # markdown previewer in terminal

    btop # replacement of htop/nmon
    iotop # io monitoring
    iftop # network monitoring

    # system call monitoring
    strace # system call monitoring
    ltrace # library call monitoring
    lsof # list open files

    # busybox # this messes up grep # a single binary that provides several stripped-down Unix tools in a single executable

    # system tools
    sysstat
    lm_sensors # for `sensors` command
    ethtool
    pciutils # lspci
    usbutils # lsusb

    blueman
    # blueman-utils

    # for pip install pygobject

    python3
    python3Packages.pygobject3
    playerctl
    gobject-introspection
    playerctl
    ninja
    gcc
    pkg-config
    cmake
    cairo
    python3Packages.pycairo

    waybar
    hyprpaper
    mako
    pavucontrol
    kdePackages.dolphin
    wofi
    wlsunset
    eww
    dunst
    xdg-desktop-portal
    xdg-desktop-portal-gtk
    playerctl
    rofi
    kitty
    swaybg
    swayidle
    pamixer
    light
    brillo
    cava
    hyprshot
    spotify
    nwg-displays # generate monitor config for hyprland
  ];
}
