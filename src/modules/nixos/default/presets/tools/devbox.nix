{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
lib.${namespace}.mkPresetModule2 config [ "tools" "devbox" ] {
  systemConfig = [
    {
      environment.systemPackages = [ pkgs.devbox ];
    }
  ];
}
