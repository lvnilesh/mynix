# Declarative backup for Hermes Agent state (CLI + gateway) and Honcho.
#
# Uses restic with local repository. Backs up only irreplaceable state:
# memories, secrets, config, skills, sessions DB, cron jobs,
# and Honcho PostgreSQL (agent memory/context service).
# Skips regeneratable data: checkpoints, cache, logs, bundled binaries.
#
# Backup:   systemctl start restic-backups-hermes
# Browse:   restic -r /home/cloudgenius/backups/hermes-restic snapshots
# Restore:  restic -r /home/cloudgenius/backups/hermes-restic restore latest --target /
# Password: RESTIC_PASSWORD in Vaultwarden hermes-agent-env note,
#           extracted from /etc/hermes-agent/secrets.env at backup time.
{pkgs, ...}: let
  # Extract RESTIC_PASSWORD from secrets.env into a standalone file
  # that the restic module can read via passwordFile.
  extractPassword = pkgs.writeShellScript "extract-restic-password" ''
    set -euo pipefail
    ${pkgs.gnugrep}/bin/grep '^RESTIC_PASSWORD=' /etc/hermes-agent/secrets.env \
      | ${pkgs.coreutils}/bin/cut -d= -f2- \
      > /run/restic-hermes-password
    ${pkgs.coreutils}/bin/chmod 600 /run/restic-hermes-password
  '';
in {
  environment.systemPackages = [pkgs.sqlite pkgs.restic];

  services.restic.backups.hermes = {
    initialize = true;
    repository = "/home/cloudgenius/backups/hermes-restic";
    passwordFile = "/run/restic-hermes-password";

    paths = [
      # CLI user state (irreplaceable)
      "/home/cloudgenius/.hermes/memories"
      "/home/cloudgenius/.hermes/config.yaml"
      "/home/cloudgenius/.hermes/.env"
      "/home/cloudgenius/.hermes/SOUL.md"
      "/home/cloudgenius/.hermes/cron"
      "/home/cloudgenius/.hermes/skills"
      "/home/cloudgenius/.hermes/mcp-servers"
      "/home/cloudgenius/.hermes/images"
      "/home/cloudgenius/.hermes/pastes"
      "/home/cloudgenius/.hermes/.hermes_history"

      # Gateway state (irreplaceable)
      "/var/lib/hermes/.hermes/memories"
      "/var/lib/hermes/.hermes/.env"

      # Gateway secrets source
      "/etc/hermes-agent/secrets.env"

      # Honcho config (docker-compose + env)
      "/home/cloudgenius/services/honcho/.env"
      "/home/cloudgenius/services/honcho/docker-compose.yml"

      # DB consistent snapshots (SQLite + Honcho pg_dump, created by prepare command)
      "/tmp/hermes-db-backup"
    ];

    exclude = [
      ".bundled_manifest"
      ".hub/"
    ];

    # Pre-backup: extract password, SQLite snapshots, prune checkpoints
    backupPrepareCommand = ''
      # Extract restic password from secrets.env
      ${extractPassword}
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

      # Honcho PostgreSQL atomic dump (agent memory/context DB)
      if ${pkgs.docker}/bin/docker inspect honcho-database-1 >/dev/null 2>&1; then
        ${pkgs.docker}/bin/docker exec honcho-database-1 \
          pg_dump -U honcho honcho \
          | ${pkgs.gzip}/bin/gzip > /tmp/hermes-db-backup/honcho.sql.gz
      fi

      # Prune checkpoint dirs older than 3 days (stale session snapshots)
      ${pkgs.findutils}/bin/find /home/cloudgenius/.hermes/checkpoints \
        -mindepth 1 -maxdepth 1 -type d -mtime +3 -exec rm -rf {} + 2>/dev/null || true
    '';

    backupCleanupCommand = ''
      rm -rf /tmp/hermes-db-backup
      # Ensure backup repo is readable for rsync pull from cosmos
      ${pkgs.coreutils}/bin/chmod -R a+rX /home/cloudgenius/backups/hermes-restic
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
