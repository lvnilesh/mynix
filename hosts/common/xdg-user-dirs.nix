{
  config,
  lib,
  pkgs,
  ...
}: {
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    desktop = null; # no Desktop dir created
    documents = "${config.users.users.cloudgenius.home}/Documents";
    download = "${config.users.users.cloudgenius.home}/Downloads";
    music = "${config.users.users.cloudgenius.home}/Music";
    pictures = "${config.users.users.cloudgenius.home}/Pictures";
    publicShare = null;
    templates = null;
    videos = "${config.users.users.cloudgenius.home}/Videos";
  };
}
