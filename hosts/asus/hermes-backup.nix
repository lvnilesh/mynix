# Declarative backup for Hermes Agent state (CLI + gateway).
#
# Uses restic with local repository. Backs up only irreplaceable state:
# memories, secrets, config, skills, sessions DB, cron jobs.
# Skips regeneratable data: checkpoints, cache, logs, bundled binaries.
#
# Backup:   systemctl start restic-backups-hermes
# Browse:   restic -r /home/cloudgenius/backups/hermes-restic snapshots
# Restore:  restic -r /home/cloudgenius/backups/hermes-restic restore latest --target /
# Password: /etc/hermes-agent/restic-password (replace with sops-nix later)
{pkgs, ...}: {
  environment.systemPackages = [pkgs.sqlite pkgs.restic];

  services.restic.backups.hermes = {
    initialize = true;
    repository = "/home/cloudgenius/backups/hermes-restic";
    passwordFile = "/etc/hermes-agent/restic-password";

    paths = [
      # CLI user state (irreplaceable)
      "/home/cloudgenius/.hermes/memories"
      "/home/cloudgenius/.hermes/config.yaml"
      "/home/cloudgenius/.hermes/.env"
      "/home/cloudgenius/.hermes/SOUL.md"
      "/home/cloudgenius/.hermes/cron"
      "/home/cloudgenius/.hermes/skills"

      # Gateway state (irreplaceable)
      "/var/lib/hermes/.hermes/memories"
      "/var/lib/hermes/.hermes/.env"

      # Gateway secrets source
      "/etc/hermes-agent/secrets.env"

      # SQLite consistent snapshots (created by prepare command)
      "/tmp/hermes-db-backup"
    ];

    exclude = [
      ".bundled_manifest"
      ".hub/"
    ];

    # Pre-backup: consistent SQLite snapshots + prune stale checkpoints
    backupPrepareCommand = ''
      # SQLite must be backed up via dump, not raw file copy
      mkdir -p /tmp/hermes-db-backup
      if [ -f /home/cloudgenius/.hermes/state.db ]; then
        ${pkgs.sqlite}/bin/sqlite3 /home/cloudgenius/.hermes/state.db \
          "VACUUM INTO '/tmp/hermes-db-backup/cli-state.db'"
      fi
      if [ -f /var/lib/hermes/.hermes/state.db ]; then
        ${pkgs.sqlite}/bin/sqlite3 /var/lib/hermes/.hermes/state.db \
          "VACUUM INTO '/tmp/hermes-db-backup/gateway-state.db'"
      fi

      # Prune checkpoint dirs older than 3 days (stale session snapshots)
      ${pkgs.findutils}/bin/find /home/cloudgenius/.hermes/checkpoints \
        -mindepth 1 -maxdepth 1 -type d -mtime +3 -exec rm -rf {} + 2>/dev/null || true
    '';

    backupCleanupCommand = ''
      rm -rf /tmp/hermes-db-backup
    '';

    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };

    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 6"
    ];
  };
}
