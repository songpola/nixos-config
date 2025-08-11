{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
lib.${namespace}.mkPresetModule config [ "tools" "just" ] {
  systemConfig = [
    {
      # just - Just a command runner
      # https://github.com/casey/just
      environment.systemPackages = [ pkgs.just ];
    }
  ];
}
