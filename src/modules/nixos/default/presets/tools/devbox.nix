{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
lib.${namespace}.mkPresetModule config [ "tools" "devbox" ] {
  environment.systemPackages = [ pkgs.devbox ];
}
