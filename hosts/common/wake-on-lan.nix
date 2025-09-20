{
  config,
  lib,
  pkgs,
  ...
}: {
  # Install wakeonlan and ethtool packages
  environment.systemPackages = with pkgs; [
    ethtool
    wakeonlan
  ];

  # Create a systemd service to enable WoL on network interfaces
  systemd.services.wake-on-lan = {
    description = "Enable Wake-on-LAN";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "enable-wol" ''
        # Find all ethernet interfaces and enable WoL
        for interface in $(${pkgs.iproute2}/bin/ip link show | grep -E '^[0-9]+: (eth|en|em)' | cut -d: -f2 | tr -d ' '); do
          if [ -n "$interface" ] && [ -e "/sys/class/net/$interface" ]; then
            echo "Enabling Wake-on-LAN for interface: $interface"
            ${pkgs.ethtool}/bin/ethtool -s "$interface" wol g 2>/dev/null || echo "Failed to enable WoL for $interface"
          fi
        done

        # Report current WoL status
        for interface in $(${pkgs.iproute2}/bin/ip link show | grep -E '^[0-9]+: (eth|en|em)' | cut -d: -f2 | tr -d ' '); do
          if [ -n "$interface" ] && [ -e "/sys/class/net/$interface" ]; then
            echo "WoL status for $interface:"
            ${pkgs.ethtool}/bin/ethtool "$interface" | grep "Wake-on:" || echo "  Could not check WoL status"
          fi
        done
      '';
    };
  };
}
