{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
lib.${namespace}.mkPresetModule config [ "tools" "nixos-rebuild-ng" ] {
  systemConfig = [
    {
      environment.systemPackages = [ pkgs.nixos-rebuild-ng ];
    }
  ];
}
