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
lib.${namespace}.mkPresetModule config [ "tools" "delta" ] (mkMerge [
  {
    # delta - a syntax-highlighting pager for git, diff, grep, and blame output
    # https://github.com/dandavison/delta
    environment.systemPackages = [ pkgs.delta ];
  }
  (mkHomeConfigModule {
    programs.git = {
      # Use delta as the default pager for git
      delta = {
        enable = true;

        # options = {
        #   navigate = true; # use n and N to move between diff sections
        #   dark = true; # or light = true, or omit for auto-detection
        # };
      };
    };

    # Use delta as the default pager for jujutsu
    programs.jujutsu = {
      settings = {
        ui = {
          pager = "${pkgs.delta}/bin/delta";
          diff-formatter = ":git";
        };
        # merge-tools.delta = {
        #   diff-expected-exit-codes = [
        #     0
        #     1
        #   ];
        # };
      };
    };
  })
])
