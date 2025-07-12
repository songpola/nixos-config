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
lib.${namespace}.mkPresetModule config [ "tools" "fzf" ] (mkMerge [
  {
    # fzf - a command-line fuzzy finder
    # https://github.com/junegunn/fzf
    environment.systemPackages = [ pkgs.fzf ];
  }
  (mkHomeConfigModule {
    programs.fzf.enable = true;
  })
])
