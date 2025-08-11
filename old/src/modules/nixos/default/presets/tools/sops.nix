{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
lib.${namespace}.mkPresetModule config [ "tools" "sops" ] {
  systemConfig = [
    {
      environment.systemPackages = [ pkgs.sops ];
    }
  ];
}
