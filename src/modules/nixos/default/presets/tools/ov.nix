{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkMerge mkIf;
  inherit (lib.${namespace}) mkHomeConfigModule hasPresetEnabled getConfigPath;
in
lib.${namespace}.mkPresetModule config [ "tools" "ov" ] (mkMerge [
  {
    # ov - feature rich terminal pager
    # https://github.com/noborus/ov
    environment.systemPackages = [ pkgs.ov ];
  }
  (mkHomeConfigModule (mkMerge [
    # Config file
    {
      xdg.configFile = {
        "ov/config.yaml".source = getConfigPath "/ov/config.yaml";
      };
    }
    # Integrate with shells if present enabled
    (mkIf (config |> hasPresetEnabled [ "shells" ]) {
      programs.nushell = {
        extraConfig = ''
          $env.PAGER = "ov"
        '';
      };
    })
  ]))
])
