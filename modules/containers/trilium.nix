{
  delib,
  homeconfig,
  host,
  ...
}:
delib.module rec {
  name = "trilium";

  options = delib.singleEnableOption host.containersFeatured;

  home.ifEnabled = delib.rootlessQuadletModule homeconfig { } (quadletCfg: {
    containers.${name} = {
      serviceConfig.Restart = "on-failure";
      containerConfig = {
        image = "docker.io/triliumnext/trilium:v0.97.2";
        volumes = [
          "/tank/songpola/${name}/trilium-data:/home/node/trilium-data"
          "/etc/localtime:/etc/localtime:ro"
        ];
        labels = {
          "caddy" = "${name}.songpola.dev";
          "caddy.reverse_proxy" = "{{upstreams 8080}}";
        };
        networks = [ quadletCfg.networks.caddy-net.ref ];
        # # FIXME: Podman fails to recognize HEALTHCHECK in certain BuildKit images
        # # See:   https://github.com/containers/podman/issues/18904
        # notify = "healthy";
      };
    };
  });
}
