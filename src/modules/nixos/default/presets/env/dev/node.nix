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
  (mkIf (config |> usePreset "env.dev.node") {
    # Node.js Development Environment
    environment.systemPackages = with pkgs; [
      nodejs
      corepack
      bun
    ];
  })
]
