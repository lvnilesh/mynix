# IPv6 disabled: LAN is IPv4-only (Proxmox, TrueNAS, SMB, DHCP).
# Disabling avoids RA/SLAAC noise, simplifies firewall rules, and prevents
# accidental dual-stack exposure of inference APIs.
# Re-enable when the LAN migrates to dual-stack.
{
  boot.kernel.sysctl = {
    "net.ipv6.conf.all.disable_ipv6" = 1;
    "net.ipv6.conf.default.disable_ipv6" = 1;
    # Optionally, disable on loopback too, though often not strictly necessary
    # "net.ipv6.conf.lo.disable_ipv6" = 1;
  };
}
