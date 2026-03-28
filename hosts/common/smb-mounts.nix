# Auto-mount SMB/CIFS shares from LAN servers.
#
# PREREQUISITES: Create the credentials file before first use:
#
#   sudo mkdir -p /etc/samba
#   sudo tee /etc/samba/creds-cloudgenius <<EOF
#   username=cloudgenius
#   password=YOUR_PASSWORD
#   EOF
#   sudo chmod 600 /etc/samba/creds-cloudgenius
#
# The file must be owned by root with mode 600 (no other users can read it).
# The same credentials are used for all servers listed below.
#
# Share discovery: the script runs `smbclient -L` against each server to
# enumerate available Disk shares. Shares with spaces in the name (e.g.
# "Macintosh HD") are skipped because they cannot be reliably auto-mounted.
# Mount attempts use SMB 3.0 first, falling back to 2.1.
#
# Timer: shares are re-checked every 30 minutes (mount-smb-shares-refresh.timer)
# so new shares or recovered servers get mounted automatically.
{
  config,
  lib,
  pkgs,
  ...
}: let
  user = "cloudgenius";
  servers = [
    "cosmos.cg.home.arpa"
    "p1.cg.home.arpa"
    "truenas.cg.home.arpa"
  ];
  baseMountRoot = "/mnt";
  credentialsFile = "/etc/samba/creds-${user}";
  mountHelper = pkgs.writeShellScriptBin "mount-smb-shares" ''
    set -euo pipefail
    MOUNT=/run/current-system/sw/bin/mount
    MOUNTPOINT=/run/current-system/sw/bin/mountpoint
    SMBCLIENT=/run/current-system/sw/bin/smbclient
    mkdir -p ${baseMountRoot}
    # Ensure credentials file permissions (provisioned externally)
    if [ -f ${credentialsFile} ]; then chmod 600 ${credentialsFile}; fi

    for server in ${lib.concatStringsSep " " servers}; do
      echo "== Scanning $server =="
      # Extract share names; skip names with spaces (unreliable to auto-mount)
      mapfile -t shares < <("$SMBCLIENT" -L "$server" -A ${credentialsFile} 2>/dev/null \
        | sed -n 's/^[[:space:]]*\([^[:space:]]*\)[[:space:]]*Disk.*/\1/p' \
        | grep -viE 'print|ipc$' || true)
      # Fallback to candidate list if server unreachable or no shares enumerated
      if [ "''${#shares[@]}" -eq 0 ]; then
        shares=( data media backup public photos videos documents )
      fi
      for share in "''${shares[@]}"; do
        targetDir="${baseMountRoot}/$server/$share"
        mkdir -p "$targetDir"
        if "$MOUNTPOINT" -q "''$targetDir"; then
          echo "Already mounted: $targetDir"
          continue
        fi
        echo "Mounting //$server/$share -> ''$targetDir"
        # Attempt mount with vers=3.0; fall back to 2.1 for older servers
        if ! "$MOUNT" -t cifs "//$server/$share" "''$targetDir" \
          -o "credentials=${credentialsFile},uid=${user},gid=users,iocharset=utf8,vers=3.0,nounix,serverino" 2>/dev/null; then
          "$MOUNT" -t cifs "//$server/$share" "''$targetDir" \
            -o "credentials=${credentialsFile},uid=${user},gid=users,iocharset=utf8,vers=2.1,nounix,serverino" 2>/dev/null || rm -rf "$targetDir"
        fi
      done
    done
  '';
in {
  environment.systemPackages = [mountHelper pkgs.cifs-utils pkgs.samba];

  systemd.services.mount-smb-shares = {
    description = "Auto-mount SMB shares from local servers";
    wantedBy = ["multi-user.target"];
    after = ["network-online.target"];
    wants = ["network-online.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${mountHelper}/bin/mount-smb-shares";
      RemainAfterExit = true;
      LoadCredential = ["smbcreds:${credentialsFile}"];
    };
    # Copy credential from systemd-managed secret to expected path if provided
    preStart = ''
      if [ -f "$CREDENTIALS_DIRECTORY/smbcreds" ]; then
        install -m600 -o root -g root "$CREDENTIALS_DIRECTORY/smbcreds" ${credentialsFile}
      fi
    '';
  };

  systemd.timers.mount-smb-shares-refresh = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "2m";
      OnUnitActiveSec = "30m";
      RandomizedDelaySec = "2m";
      Unit = "mount-smb-shares.service";
    };
  };

  # Ensure base mount root exists
  systemd.tmpfiles.rules = ["d ${baseMountRoot} 0755 root root -"];
}
