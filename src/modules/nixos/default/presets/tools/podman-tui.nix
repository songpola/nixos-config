{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
lib.${namespace}.mkPresetModule config [ "tools" "podman-tui" ] {
  systemConfig = [
    {
      environment.systemPackages = [ pkgs.podman-tui ];
    }
  ];
}
