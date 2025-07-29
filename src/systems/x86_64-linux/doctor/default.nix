{
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkMerge;
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

        podman = true;

        remote-build = true;
      };
    };
  }
]
