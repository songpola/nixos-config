{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
lib.${namespace}.mkPresetModule config [ "tools" "gh" ] {
  systemConfig = [
    {
      # GitHub CLI
      environment.systemPackages = [ pkgs.gh ];
    }
  ];
  homeConfig = [
    {
      programs.gh.enable = true;
    }
  ];
}
