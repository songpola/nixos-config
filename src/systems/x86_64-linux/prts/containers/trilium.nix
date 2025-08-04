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
  (mkRootlessQuadletModule config { } (quadletCfg: {
    containers = {
      trilium = {
        serviceConfig.Restart = "on-failure";
        containerConfig = {
          image = "docker.io/triliumnext/notes:v0.95.0";
          volumes = [
            "/tank/songpola/trilium:/home/node/trilium-data"
            "/etc/localtime:/etc/localtime:ro"
          ];
          labels = {
            "caddy" = "trilium.songpola.dev";
            "caddy.reverse_proxy" = "{{upstreams 8080}}";
          };
          networks = [ quadletCfg.networks.caddy-net.ref ];
          notify = "healthy";
        };
      };
    };
  }))
]
