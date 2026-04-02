{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.chatbot;
  chatbotDir = "/home/cloudgenius/services/chatbot";
in {
  options.services.chatbot = {
    enable = lib.mkEnableOption "Chatbot API Server";
    port = lib.mkOption {
      type = lib.types.int;
      default = 3001;
      description = "Port to listen on";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.chatbot = {
      description = "Chatbot API Server";
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
