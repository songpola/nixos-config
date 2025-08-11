{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
lib.${namespace}.mkPresetModule config [ "tools" "devbox" ] {
  systemConfig = [
    {
      environment.systemPackages = [ pkgs.devbox ];
    }
  ];
}
