{
  config,
  pkgs,
  lib,
  ...
}: {
  services.alloy = {
    enable = true;
    extraFlags = [
      "--stability.level=generally-available"
      "--disable-reporting"
    ];
  };

  # Alloy configuration file (River mode)
  environment.etc."alloy/config.alloy".text = let
    hostname = config.networking.hostName;
  in ''
    // -- Journal (systemd) --
    loki.source.journal "journal" {
      max_age        = "12h"
      forward_to     = [loki.write.default.receiver]
      relabel_rules  = loki.relabel.journal.rules
      labels         = {
        job  = "systemd-journal",
        host = "${hostname}",
      }
    }

    loki.relabel "journal" {
      forward_to = []

      rule {
        source_labels = ["__journal__systemd_unit"]
        target_label  = "unit"
      }
      rule {
        source_labels = ["__journal_priority_keyword"]
        target_label  = "priority"
      }
    }

    // -- Docker containers --
    discovery.docker "containers" {
      host             = "unix:///var/run/docker.sock"
      refresh_interval = "10s"
    }

    discovery.relabel "docker" {
      targets = discovery.docker.containers.targets

      rule {
        source_labels = ["__meta_docker_container_name"]
        regex         = "/(.*)"
        target_label  = "container"
      }
      rule {
        source_labels = ["__meta_docker_container_log_stream"]
        target_label  = "stream"
      }
      rule {
        source_labels = ["__meta_docker_compose_project"]
        target_label  = "compose_project"
      }
      rule {
        source_labels = ["__meta_docker_compose_service"]
        target_label  = "compose_service"
      }
      rule {
        target_label = "host"
        replacement  = "${hostname}"
      }
    }

    loki.source.docker "docker" {
      host       = "unix:///var/run/docker.sock"
      targets    = discovery.relabel.docker.output
      forward_to = [loki.write.default.receiver]
    }

    // -- Push to Loki --
    loki.write "default" {
      endpoint {
        url = "http://192.168.1.203:3100/loki/api/v1/push"
      }
    }
  '';

  # Alloy needs access to journal and docker socket
  systemd.services.alloy.serviceConfig.SupplementaryGroups = ["docker" "systemd-journal"];
}
