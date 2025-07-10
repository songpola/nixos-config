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
  (mkIf (config |> usePreset "env.dev.nix") {
    # Packages for Nix IDE VSCode extension
    environment.systemPackages = with pkgs; [
      nil # LSP
      nixfmt-rfc-style # NixOS/nixfmt: The official Nix formatter
    ];
  })
]
