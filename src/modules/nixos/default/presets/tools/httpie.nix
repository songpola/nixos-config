{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
lib.${namespace}.mkPresetModule config [ "tools" "httpie" ] {
  systemConfig = [
    {
      environment.systemPackages = [
        pkgs.httpie
      ];
    }
  ];
}
