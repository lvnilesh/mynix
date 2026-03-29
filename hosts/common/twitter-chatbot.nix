{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.twitter-chatbot;
  chatbotDir = "/home/cloudgenius/services/twitter-chatbot";
in {
  options.services.twitter-chatbot = {
    enable = lib.mkEnableOption "Twitter Chatbot API Server";
    port = lib.mkOption {
      type = lib.types.int;
      default = 3001;
      description = "Port to listen on";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.twitter-chatbot = {
      description = "Twitter Chatbot API Server";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      serviceConfig = {
        Type = "simple";
        User = "cloudgenius";
        WorkingDirectory = chatbotDir;
        ExecStart = "${pkgs.python3}/bin/python3 ${chatbotDir}/server.py";
        Restart = "always";
        RestartSec = 5;
        Environment = "PORT=${toString cfg.port}";
      };
    };

    networking.firewall.allowedTCPPorts = [cfg.port];
  };
}
