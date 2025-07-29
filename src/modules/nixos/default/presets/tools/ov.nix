{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib.${namespace}) getConfigPath;
in
lib.${namespace}.mkPresetModule config [ "tools" "ov" ] {
  systemConfig = [
    {
      # ov - feature rich terminal pager
      # https://github.com/noborus/ov
      environment.systemPackages = [ pkgs.ov ];

      # Set as default pager (also used by systemd)
      environment.sessionVariables = {
        PAGER = "ov";
        SYSTEMD_PAGERSECURE = "false";
      };
    }
  ];
  homeConfig = [
    {
      # Config file
      xdg.configFile = {
        "ov/config.yaml".source = getConfigPath "/ov/config.yaml";
      };
    }
  ];
}
