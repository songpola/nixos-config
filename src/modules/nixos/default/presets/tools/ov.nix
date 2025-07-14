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
lib.${namespace}.mkPresetModule2 config [ "tools" "ov" ] {
  systemConfig = [
    {
      # ov - feature rich terminal pager
      # https://github.com/noborus/ov
      environment.systemPackages = [ pkgs.ov ];

      # Set as default pager
      environment.variables = {
        PAGER = "ov";
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
