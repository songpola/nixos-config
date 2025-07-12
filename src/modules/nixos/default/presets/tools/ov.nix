{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkMerge;
  inherit (lib.${namespace}) mkHomeConfigModule getConfigPath;
in
lib.${namespace}.mkPresetModule config [ "tools" "ov" ] (mkMerge [
  {
    # ov - feature rich terminal pager
    # https://github.com/noborus/ov
    environment.systemPackages = [ pkgs.ov ];

    # Set as default pager
    environment.variables = {
      PAGER = "ov";
    };
  }
  # Config file
  (mkHomeConfigModule {
    xdg.configFile = {
      "ov/config.yaml".source = getConfigPath "/ov/config.yaml";
    };
  })
])
