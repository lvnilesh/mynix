{
  config,
  pkgs,
  lib,
  ...
}: {
  services.promtail = {
    enable = true;
    configuration = {
      server = {
        http_listen_port = 9080;
        grpc_listen_port = 0;
      };
      positions.filename = "/var/lib/promtail/positions.yaml";
      clients = [
        {url = "http://192.168.1.203:3100/loki/api/v1/push";}
      ];
      scrape_configs = [
        {
          job_name = "journal";
          journal = {
            max_age = "12h";
            labels = {
              job = "systemd-journal";
              host = config.networking.hostName;
            };
          };
          relabel_configs = [
            {
              source_labels = ["__journal__systemd_unit"];
              target_label = "unit";
            }
            {
              source_labels = ["__journal_priority_keyword"];
              target_label = "priority";
            }
          ];
        }
        {
          job_name = "docker";
          docker_sd_configs = [
            {
              host = "unix:///var/run/docker.sock";
              refresh_interval = "10s";
            }
          ];
          relabel_configs = [
            {
              source_labels = ["__meta_docker_container_name"];
              regex = "/(.*)";
              target_label = "container";
            }
            {
              source_labels = ["__meta_docker_container_log_stream"];
              target_label = "stream";
            }
            {
              source_labels = ["__meta_docker_compose_project"];
              target_label = "compose_project";
            }
            {
              source_labels = ["__meta_docker_compose_service"];
              target_label = "compose_service";
            }
            {
              target_label = "host";
              replacement = config.networking.hostName;
            }
          ];
        }
      ];
    };
  };

  # promtail needs access to journal and docker socket
  systemd.services.promtail.serviceConfig.SupplementaryGroups = ["docker" "systemd-journal"];

  # ensure positions directory exists before service starts
  systemd.tmpfiles.rules = [
    "d /var/lib/promtail 0755 promtail promtail -"
  ];
}
