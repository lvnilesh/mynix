{
  config,
  pkgs,
  lib,
  ...
}: {
  systemd.user.services.waybar-caffeine = {
    Unit = {
      Description = "Waybar Caffeine Inhibitor";
    };
    Service = {
      Type = "simple";
      ExecStart = "/run/current-system/sw/bin/systemd-inhibit --what=idle:sleep --why=WaybarCaffeine /run/current-system/sw/bin/bash -c 'while true; do sleep 60; done'";
    };
    Install = {
      WantedBy = ["default.target"];
    };
  };

  systemd.user.services.waybar = {
    Unit = {
      Description = "Waybar status bar";
      After = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
    };
    Service = {
      ExecStart = "/run/current-system/sw/bin/waybar";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = ["graphical-session.target"];
    };
  };
}
