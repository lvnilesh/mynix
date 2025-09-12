{
  config,
  lib,
  pkgs,
  ...
}: let
  user = "cloudgenius";
  group = "users"; # primary group, explicit for clarity
  homeDir = "/home/${user}";
  dataDir = "${homeDir}/.local/share/resilio-sync";
  syncRoot = "${homeDir}/btsync";
in {
  systemd.services.resilio-sync = {
    description = "Resilio Sync";
    wantedBy = ["multi-user.target"];
    after = ["network-online.target"];
    wants = ["network-online.target"];
    serviceConfig = {
      ExecStart = ''${pkgs.resilio-sync}/bin/rslsync --nodaemon --config ${dataDir}/config.json'';
      User = user;
      # Use an always-existing directory so systemd can run preStart before dataDir exists
      WorkingDirectory = homeDir;
      Restart = "on-failure";
      AmbientCapabilities = "CAP_NET_BIND_SERVICE";
    };
    preStart = ''
            install -d -m0755 -o ${user} -g ${group} "${homeDir}/.local/share"
            install -d -m0755 -o ${user} -g ${group} ${dataDir}
            # Create sync root with group write & setgid so group ownership persists
            install -d -m2775 -o ${user} -g ${group} ${syncRoot}
            if [ ! -f ${dataDir}/config.json ]; then
              cat > ${dataDir}/config.json <<CFG
      {
        "device_name": "${config.networking.hostName}-resilio",
        "storage_path": "${dataDir}",
        "listening_port": 0,
        "directory_root": "${syncRoot}",
        "use_upnp": true,
        "webui": { "listen": "127.0.0.1:8888" }
      }
      CFG
              chown ${user}:${group} ${dataDir}/config.json
            fi
            # Ensure permissions each start (do not recurse to avoid clobbering share-level custom perms)
            chown ${user}:${group} ${syncRoot}
            chmod 2775 ${syncRoot}
    '';
  };

  # Expose only if you later change listen to 0.0.0.0
  # services.firewall.allowedTCPPorts = [ 8888 ];
}
