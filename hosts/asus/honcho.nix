# Honcho — self-hosted cross-session memory layer for Hermes Agent
#
# Upstream: plastic-labs/honcho, pinned to v3.0.4
# Two patches applied:
#   1. honcho-embedding-baseurl.patch — Azure embedding base URL + separate API key support
#   2. honcho-deriver-reasoning.patch — reasoning_effort minimal → low
#
# Secrets come from honcho-secrets.nix (/etc/honcho/env).
# Source is fetched from GitHub + patched by Nix (no manual git clone).
{pkgs, ...}: let
  # Pin upstream honcho source and apply patches
  honchoSrc = pkgs.applyPatches {
    src = pkgs.fetchFromGitHub {
      owner = "plastic-labs";
      repo = "honcho";
      rev = "v3.0.4";
      sha256 = "1g19x3hdq3z8dp5q3pgbd2sa425crz4n98wc94jy4rdm7h23vh0w";
    };
    patches = [
      ./honcho-embedding-baseurl.patch
      ./honcho-deriver-reasoning.patch
    ];
  };

  composeFile = pkgs.writeText "honcho-docker-compose.yml" ''
    services:
      api:
        build: ${honchoSrc}
        image: honcho:latest
        ports:
          - "8200:8000"
        env_file: /etc/honcho/env
        depends_on:
          database:
            condition: service_healthy
          redis:
            condition: service_healthy
        restart: unless-stopped

      deriver:
        image: honcho:latest
        command: python -m src.deriver
        env_file: /etc/honcho/env
        healthcheck:
          disable: true
        depends_on:
          database:
            condition: service_healthy
          redis:
            condition: service_healthy
        restart: unless-stopped

      database:
        image: pgvector/pgvector:pg15
        environment:
          POSTGRES_USER: honcho
          POSTGRES_PASSWORD: honcho
          POSTGRES_DB: honcho
        ports:
          - "127.0.0.1:5433:5432"
        volumes:
          - honcho-db:/var/lib/postgresql/data
        healthcheck:
          test: ["CMD-SHELL", "pg_isready -U honcho"]
          interval: 5s
          timeout: 5s
          retries: 5
        restart: unless-stopped

      redis:
        image: redis:8.2
        ports:
          - "127.0.0.1:6380:6379"
        volumes:
          - honcho-redis:/data
        healthcheck:
          test: ["CMD", "redis-cli", "ping"]
          interval: 5s
          timeout: 5s
          retries: 5
        restart: unless-stopped

    volumes:
      honcho-db:
      honcho-redis:
  '';

  # Wait for Honcho API to be healthy before declaring service started
  healthCheck = pkgs.writeShellScript "honcho-health-check" ''
    for i in $(seq 1 60); do
      if ${pkgs.curl}/bin/curl -sf http://localhost:8200/docs > /dev/null 2>&1; then
        echo "Honcho API healthy after ''${i}s"
        exit 0
      fi
      sleep 1
    done
    echo "Honcho API not ready after 60s" >&2
    exit 1
  '';
in {
  # Redis requires memory overcommit for background saves
  boot.kernel.sysctl."vm.overcommit_memory" = 1;

  # Write the compose file to a known location
  environment.etc."honcho/docker-compose.yml".source = composeFile;

  # Systemd service to keep honcho running
  systemd.services.honcho = {
    description = "Honcho memory layer";
    wantedBy = ["multi-user.target"];
    after = ["docker.service" "honcho-secrets.service"];
    requires = ["docker.service" "honcho-secrets.service"];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.docker}/bin/docker compose -f /etc/honcho/docker-compose.yml up -d --remove-orphans";
      ExecStartPost = healthCheck;
      ExecStop = "${pkgs.docker}/bin/docker compose -f /etc/honcho/docker-compose.yml down";
    };
  };
}
