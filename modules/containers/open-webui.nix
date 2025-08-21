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
        image = "ghcr.io/open-webui/open-webui:v0.6.22-cuda";
        volumes = [
          "/tank/songpola/open-webui/app-backend-data:/app/backend/data"
        ];
        labels = {
          "caddy_1" = "${name}.songpola.dev, ai.songpola.dev";
          "caddy_1.reverse_proxy" = "{{upstreams 8080}}";
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
