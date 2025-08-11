{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
lib.${namespace}.mkPresetModule config [ "tools" "fastfetch" ] {
  systemConfig = [
    {
      environment.systemPackages = [ pkgs.fastfetch ];
    }
  ];
}
