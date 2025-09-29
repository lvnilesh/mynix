# Brother HL-4070 Laser Printer Configuration for NixOS
{pkgs, ...}: {
  # Enable CUPS printing service
  services.printing = {
    enable = true;
    drivers = with pkgs; [
      # Brother printer drivers
      brlaser # Open source Brother laser printer driver
      brgenml1lpr # Brother generic LPR driver
      brgenml1cupswrapper # Brother CUPS wrapper
    ];

    # Enable printer discovery and network printing
    browsing = true;
    defaultShared = false;

    # Allow printing from network
    listenAddresses = ["localhost:631"];
    allowFrom = ["all"];

    # Extra configuration for CUPS
    extraConf = ''
      # Optimize for laser printer performance
      MaxLogSize 0
      LogLevel info

      # Network printer settings
      BrowseProtocols cups
      BrowseAddress @LOCAL

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
    cups # Common Unix Printing System
    system-config-printer # GUI printer configuration
    ghostscript # PostScript interpreter
    foomatic-db # Printer database
    foomatic-db-ppds # Printer description files
    gutenprint # High quality printer drivers
  ];

  # User groups for printing
  users.users.cloudgenius.extraGroups = ["lp"];
}
