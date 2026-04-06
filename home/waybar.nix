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
      ExecStart = "/run/current-system/sw/bin/systemd-inhibit --what=idle:sleep --why=WaybarCaffeine /run/current-system/sw/bin/bash -c 'while true; do /run/current-system/sw/bin/sleep 60; done'";
    };
    Install = {
      WantedBy = ["default.target"];
    };
  };

  systemd.user.services.swayosd = {
    Unit = {
      Description = "SwayOSD on-screen display server";
      After = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
    };
    Service = {
      ExecStart = "/run/current-system/sw/bin/swayosd-server";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install = {
      WantedBy = ["graphical-session.target"];
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
      RestartSec = 2;
    };
    Install = {
      WantedBy = ["graphical-session.target"];
    };
  };
}
