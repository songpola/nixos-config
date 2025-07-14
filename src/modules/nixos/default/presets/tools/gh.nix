{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
lib.${namespace}.mkPresetModule2 config [ "tools" "gh" ] {
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
