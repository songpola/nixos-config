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

        remote-build = true;
        binary-cache.client = true;

        services = {
          podman = true;
        };

        tools = {
          sops = true;
        };

        devenv = {
          node = true;
        };
      };
    };

    wsl.startMenuLaunchers = true;

    programs.virt-manager.enable = true;
  }
]
