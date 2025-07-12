{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkMerge;
  # inherit (lib.${namespace}) mkHomeConfigModule;
in
lib.${namespace}.mkPresetModule config [ "tools" "nh" ] (mkMerge [
  {
    # nh - Yet another Nix CLI helper
    # https://github.com/nix-community/nh
    programs.nh = {
      enable = true;
      clean.enable = true; # auto clean (all) (default: weekly)
    };
  }
  # NOTE: Don't need this; already done by the system options above
  # (mkHomeConfigModule {
  #   programs.nh = {
  #     enable = true;
  #     clean.enable = true; # auto clean (user) (default: weekly)
  #   };
  # })
])
