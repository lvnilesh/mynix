# Brother HL-4070 Laser Printer Configuration for NixOS
{pkgs, ...}: {
  # Enable CUPS printing service
  services.printing = {
    enable = true;
    drivers = with pkgs; [
      brlaser
      brgenml1lpr
      brgenml1cupswrapper
      gutenprint
      gutenprintBin
    ];

    # Enable printer discovery and network printing
    browsing = true;
    defaultShared = false;

    # Allow printing from network
    listenAddresses = ["127.0.0.1:631"];
    allowFrom = ["all"];

    # Extra configuration for CUPS
    extraConf = ''
      # Optimize for laser printer performance
      MaxLogSize 0
      # Disable colord color management integration (suppresses duplicate profile warnings)
      ColorManagement Off
      LogLevel info

      # Security settings
      <Location />
        Order allow,deny
        Allow localhost
        Allow @LOCAL
      </Location>
    '';
  };

  # Enable Avahi for printer discovery
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    nssmdns6 = true;
    openFirewall = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };

  # Open firewall for CUPS and IPP
  networking.firewall = {
    allowedTCPPorts = [631]; # CUPS
    allowedUDPPorts = [631 5353]; # CUPS and mDNS
  };

  # System packages for printer management
  environment.systemPackages = with pkgs; [
    cups
    ghostscript
    gutenprint
  ];

  # Declarative printer: Brother HL-4070CDW direct IPP connection
  # Monochrome default — change ColorModel to CMYK when color toners installed
  hardware.printers = {
    ensurePrinters = [
      {
        name = "Brother-Direct";
        location = "Garage";
        description = "Brother HL-4070CDW Direct";
        deviceUri = "ipp://brother.cg.home.arpa:631/ipp";
        model = "gutenprint.5.3://brother-hl-4040cn/expert";
      }
    ];
    ensureDefaultPrinter = "Brother-Direct";
  };

  # User groups for printing
  users.users.cloudgenius.extraGroups = ["lp"];
}
