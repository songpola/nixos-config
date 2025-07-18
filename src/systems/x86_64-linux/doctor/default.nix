{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkMerge;
  inherit (lib.${namespace}) mkHomeConfigModule mkRootlessQuadletModule;
in
mkMerge [
  {
    ${namespace} = {
      stateVersions = {
        system = "25.05";
        home = "25.05";
      };
      base = "wsl";
      presets = {
        stdenv.full = true;
      };
    };
  }
]
