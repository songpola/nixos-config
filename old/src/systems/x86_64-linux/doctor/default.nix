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
      presets = {
        remote-build = true;
        binary-cache.client = true;

        services = {
          podman = true;
        };
      };
    };
  }
]
