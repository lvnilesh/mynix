{
  config,
  pkgs,
  ...
}: {
  environment.systemPackages = [
    pkgs.python312Packages.google-auth
    pkgs.python312Packages.google-api-python-client
  ];
}
