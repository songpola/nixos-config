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

        podman = true;
      };
    };
  }
  (mkRootlessQuadletModule config (quadletCfg: {
    containers = {
      trilium = {
        containerConfig = {
          image = "docker.io/triliumnext/trilium:v0.96.0";
          publishPorts = [ "8080:8080" ];
          volumes = [
            "${quadletCfg.volumes.trilium-data.ref}:/home/node/trilium-data"
            "/etc/localtime:/etc/localtime:ro"
          ];
        };
      };
    };
    volumes = {
      trilium-data = { };
    };
  }))
]
