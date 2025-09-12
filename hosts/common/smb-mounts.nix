{
  config,
  lib,
  pkgs,
  ...
}: let
  user = "cloudgenius";
  # Password is no longer stored here. Provide a file at build or runtime containing lines:
  #   username=cloudgenius
  #   password=YOURPASSWORD
  # It will be referenced via systemd credentials (LoadCredential=).
  # Define the SMB servers and a list of shares to attempt. If share list is empty, we will probe.
  servers = [
    "cosmos.cg.home.arpa"
    "m1.cg.home.arpa"
    "truenas.cg.home.arpa"
  ];
  # Static list of common shares to try. Adjust as needed.
  candidateShares = ["data" "media" "backup" "public" "photos" "videos" "documents"];
  baseMountRoot = "/mnt";
  credentialsFile = "/etc/samba/creds-${user}";
  mountHelper = pkgs.writeShellScriptBin "mount-smb-shares" ''
      set -euo pipefail
      MOUNT=/run/current-system/sw/bin/mount
      MOUNTPOINT=/run/current-system/sw/bin/mountpoint
    SMBCLIENT=/run/current-system/sw/bin/smbclient
    AWK=/run/current-system/sw/bin/awk
      mkdir -p ${baseMountRoot}
      # credentials are provisioned externally (systemd LoadCredential or tmpfiles). Ensure perms.
      if [ -f ${credentialsFile} ]; then chmod 600 ${credentialsFile}; fi

      for server in ${lib.concatStringsSep " " servers}; do
        echo "== Scanning $server =="
        # list shares (suppress printer/admin shares)
    mapfile -t shares < <("$SMBCLIENT" -L "$server" -A ${credentialsFile} 2>/dev/null | "$AWK" '/Disk/ {print $1}' | grep -viE 'print|ipc$' || true)
        # fallback to candidate list if none enumerated
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
          # attempt mount with vers negotiation
    if ! "$MOUNT" -t cifs "//$server/$share" "''$targetDir" \
            -o "credentials=${credentialsFile},uid=${user},gid=users,iocharset=utf8,vers=3.1.1,nounix,serverino" 2>/dev/null; then
            # retry with vers=3.0 then 2.1
            "$MOUNT" -t cifs "//$server/$share" "''$targetDir" \
              -o "credentials=${credentialsFile},uid=${user},gid=users,iocharset=utf8,vers=3.0,nounix,serverino" 2>/dev/null || \
            "$MOUNT" -t cifs "//$server/$share" "''$targetDir" \
              -o "credentials=${credentialsFile},uid=${user},gid=users,iocharset=utf8,vers=2.1,nounix,serverino" || rm -rf "$targetDir"
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

  # Optional: periodic remount/refresh via timer
  systemd.timers.mount-smb-shares-refresh = {
    wantedBy = ["timers.target"];
    partOf = ["mount-smb-shares.service"];
    timerConfig = {
      OnBootSec = "2m";
      OnUnitActiveSec = "30m";
      RandomizedDelaySec = "2m";
    };
  };

  # Ensure base mount root exists
  systemd.tmpfiles.rules = ["d ${baseMountRoot} 0755 root root -"];

  # NOTE: Credentials stored in world-inaccessible file; consider secret management improvements.
}
