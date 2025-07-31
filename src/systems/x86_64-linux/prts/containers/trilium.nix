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
          image = "docker.io/triliumnext/notes:v0.95.0";
          publishPorts = [ "8080:8080" ];
          volumes = [
            "${quadletCfg.volumes.trilium-data.ref}:/opt/oracle/oradata"
            "/etc/localtime:/etc/localtime:ro"
          ];
        };
      };
    };
    volumes = {
      trilium-data = { };
    };
  }))
  {
    networking.firewall.allowedTCPPorts = [ 8080 ];
  }
]
