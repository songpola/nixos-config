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
      dozzle = {
        containerConfig = {
          image = "docker.io/amir20/dozzle:v8.13.8";
          volumes = [
            "%t/podman/podman.sock:/var/run/docker.sock"
          ];
          environments = {
            DOZZLE_ENABLE_ACTIONS = "true";
          };
          labels = {
            "caddy" = "dozzle.songpola.dev";
            "caddy.reverse_proxy" = "{{upstreams 8080}}";
          };
          networks = [ quadletCfg.networks.caddy-net.ref ];
        };
      };
    };
  }))
]
