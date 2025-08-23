{
  delib,
  homeconfig,
  host,
  ...
}:
let
  # !!! External !!!
  # See ./ollama.nix
  ollamaName = "ollama";
  ollamaNetName = "${ollamaName}-net";
  OLLAMA_BASE_URL = "http://${ollamaName}:11434/";
in
delib.module rec {
  name = "open-webui";

  options = delib.singleEnableOption host.containersFeatured;

  home.ifEnabled = delib.rootlessQuadletModule homeconfig { } (quadletCfg: {
    containers.${name} = {
      serviceConfig.Restart = "on-failure";
      unitConfig = rec {
        Requires = [
          quadletCfg.containers.${ollamaName}.ref
        ];
        After = Requires;
      };
      containerConfig = {
        # NOTE: Use cuda126 tag to support 1050 Ti
        # https://github.com/open-webui/open-webui/pull/14592
        image = "ghcr.io/open-webui/open-webui:v0.6.22-cuda126";
        volumes = [
          "/tank/songpola/open-webui/app-backend-data:/app/backend/data"
        ];
        labels = {
          "caddy" = "${name}.songpola.dev, ai.songpola.dev";
          "caddy.reverse_proxy" = "{{upstreams 8080}}";
        };
        environments = {
          inherit OLLAMA_BASE_URL;
        };
        networks = [
          quadletCfg.networks.caddy-net.ref
          quadletCfg.networks.${ollamaNetName}.ref
        ];
        devices = [ "nvidia.com/gpu=all" ];
      };
    };
  });
}
