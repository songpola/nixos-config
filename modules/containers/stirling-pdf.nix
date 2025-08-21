{
  delib,
  homeconfig,
  host,
  ...
}:
delib.module rec {
  name = "stirling-pdf";

  options = delib.singleEnableOption host.containersFeatured;

  home.ifEnabled = delib.rootlessQuadletModule homeconfig { } (quadletCfg: {
    containers.${name} = {
      serviceConfig.Restart = "on-failure";
      containerConfig = {
        image = "docker.io/stirlingtools/stirling-pdf:0.45.6";
        volumes = [
          "/tank/songpola/stirling-pdf/logs:/logs"
          "/tank/songpola/stirling-pdf/extraConfigs:/configs"
          "/tank/songpola/stirling-pdf/pipeline:/pipeline"
          "/tank/songpola/stirling-pdf/customFiles:/customFiles"
          "/tank/songpola/stirling-pdf/trainingData:/usr/share/tessdata"
        ];
        environments = {
          DOCKER_ENABLE_SECURITY = "false";
          LANGS = "en_US";
        };
        labels = {
          "caddy" = "${name}.songpola.dev, pdf.songpola.dev";
          "caddy.reverse_proxy" = "{{upstreams 8080}}";
        };
        networks = [ quadletCfg.networks.caddy-net.ref ];
      };
    };
  });
}
