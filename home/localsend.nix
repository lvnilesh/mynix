{
  config,
  pkgs,
  lib,
  ...
}: {
  systemd.user.services.localsend = {
    Unit = {
      Description = "LocalSend file sharing";
      After = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
    };
    Service = {
      ExecStart = "${pkgs.localsend}/bin/localsend_app";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install = {
      WantedBy = ["graphical-session.target"];
    };
  };
}
