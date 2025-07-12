{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
lib.${namespace}.mkPresetModule config [ "devenv" "devbox" ] {
  environment.systemPackages = [ pkgs.devbox ];
}
