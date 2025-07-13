{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkMerge;
  inherit (lib.${namespace}) mkHomeConfigModule;
in
lib.${namespace}.mkPresetModule config [ "tools" "gh" ] (mkMerge [
  {
    # GitHub CLI
    environment.systemPackages = [ pkgs.gh ];
  }
  (mkHomeConfigModule {
    programs.gh.enable = true;
  })
])
