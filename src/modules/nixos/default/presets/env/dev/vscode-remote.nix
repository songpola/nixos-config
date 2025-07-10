{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkMerge mkIf;
  inherit (lib.${namespace}) usePreset;
in
mkMerge [
  (mkIf (config |> usePreset "env.dev.vscode-remote") {
    # Setup VSCode Remote
    environment.systemPackages = [ pkgs.wget ];
    programs.nix-ld.enable = true;
  })
]
