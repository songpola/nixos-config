{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkMerge;
  inherit (lib.${namespace}) mkHomeConfigModule;
in
lib.${namespace}.mkPresetModule config [ "tools" "direnv" ] (mkMerge [
  {
    # Enable Direnv system-wide
    # nix-direnv is enabled by default
    programs.direnv.enable = true;
  }
  (mkHomeConfigModule {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  })
])
