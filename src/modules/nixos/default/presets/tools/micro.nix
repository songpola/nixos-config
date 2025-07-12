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
lib.${namespace}.mkPresetModule config [ "tools" "micro" ] (mkMerge [
  {
    # Use micro as default (and fallback) text editor
    environment.systemPackages = [ pkgs.micro ];
  }
  (mkHomeConfigModule (mkMerge [
    {
      programs.micro = {
        enable = true;
        settings = {
          # Fix clipboard not working in SSH sessions:
          # Use OSC 52 (terminal clipboard)
          clipboard = "terminal";
        };
      };
    }
  ]))
])
