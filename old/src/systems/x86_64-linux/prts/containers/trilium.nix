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
          image = "docker.io/triliumnext/trilium:v0.97.2";
          volumes = [
            "/tank/songpola/trilium/trilium-data:/home/node/trilium-data"
            "/etc/localtime:/etc/localtime:ro"
          ];
          labels = {
            "caddy" = "trilium.songpola.dev";
            "caddy.reverse_proxy" = "{{upstreams 8080}}";
          };
          networks = [ quadletCfg.networks.caddy-net.ref ];
          # # FIXME: Podman fails to recognize HEALTHCHECK in certain BuildKit images
          # # See:   https://github.com/containers/podman/issues/18904
          # notify = "healthy";
        };
      };
    };
  }))
]
