{
  delib,
  homeconfig,
  host,
  ...
}:
delib.module rec {
  name = "ollama";

  options = delib.singleEnableOption host.containersFeatured;

  home.ifEnabled = delib.rootlessQuadletModule homeconfig { } (quadletCfg: {
    containers.${name} = {
      serviceConfig.Restart = "on-failure";
      containerConfig = {
        image = "docker.io/ollama/ollama:0.11.4";
        volumes = [
          "/tank/songpola/ollama/root-ollama:/root/.ollama"
        ];
        labels = {
          "caddy" = "${name}.songpola.dev";
          "caddy.reverse_proxy" = "{{upstreams 11434}}";
        };
        networks = [
          quadletCfg.networks.caddy-net.ref
          quadletCfg.networks."${name}-net".ref
        ];
        devices = [ "nvidia.com/gpu=all" ];
      };
    };
    networks."${name}-net" = { };
  });
}
