{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
lib.${namespace}.mkPresetModule config [ "tools" "ripgrep" ] {
  systemConfig = [
    {
      environment.systemPackages = [
        pkgs.ripgrep
      ];
    }
  ];
}
