#!/usr/bin/env bash
# nettools-help: guidance for migrating from legacy net-tools to iproute2.
set -euo pipefail
cat <<'EOF'
Legacy -> Modern (iproute2)
---------------------------------------------
ifconfig            -> ip -c -br a    (or: ip addr)
ifconfig eth0 up    -> ip link set eth0 up
ifconfig eth0 1.2.3.4/24 -> ip addr add 1.2.3.4/24 dev eth0
route -n            -> ip route show
netstat -tulpn      -> ss -tulpn
netstat -plant      -> ss -plant
netstat -i          -> ip -s -h link
arp -n              -> ip neigh
# monitor changes
ip monitor all

Cheat aliases installed (if using bash in Home Manager):
  ifconfig, route, netstat, arp, iwconfig -> translated to ip/ss/iw equivalents
Extra helpers:
  ifstats  (interface counters)
  netmon   (live routing/link/address events)

More examples:
  # Add a route
  sudo ip route add 10.10.0.0/16 via 192.168.1.1

  # Flush DHCP address
  sudo ip addr flush dev eth0

  # Show IPv6 routes
  ip -6 route

  # Show policy routing rules / tables
  ip rule show
  ip route show table main
  ip route show table 100

  # Active listening sockets summary
  ss -ltunp

EOF
