{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkMerge;
  inherit (lib.${namespace}) mkRootlessQuadletModule;
in
mkMerge [
  (mkRootlessQuadletModule config (quadletCfg: {
    containers = {
      trilium = {
        serviceConfig = {
          Restart = "on-failure";
        };
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
