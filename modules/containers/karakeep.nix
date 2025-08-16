{
  delib,
  homeconfig,
  host,
  username,
  secrets,
  lib,
  ...
}:
let
  name = "karakeep";

  podName = name;
  serverName = "${name}-server";
  crawlerName = "${name}-crawler";
  meilisearchName = "${name}-meilisearch";

  serverSecretName = "containers/${serverName}/env";
  meilisearchSecretName = "containers/${meilisearchName}/env";

  serverVolumes = [ "/tank/songpola/karakeep/server-data:/data" ];
  meilisearchVolumes = [ "/tank/songpola/karakeep/meilisearch-data:/meili_data" ];

  KARAKEEP_VERSION = "0.26.0";

  # !!! External !!!
  # See ./ollama.nix
  ollamaName = "ollama";
  ollamaNetName = "${ollamaName}-net";
  OLLAMA_BASE_URL = "http://${ollamaName}:11434/";
  INFERENCE_TEXT_MODEL = "gemma3:4b"; # gemma3:4b can recieve text input
  INFERENCE_IMAGE_MODEL = "gemma3:4b"; # gemma3:4b can recieve image input
  INFERENCE_CONTEXT_LENGTH = "131072"; # gemma3:4b has 128K context size
in
delib.module {
  inherit name;

  options = delib.singleEnableOption host.containersFeatured;

  myconfig.ifEnabled.secrets.enable = true;

  nixos.ifEnabled.sops.secrets = {
    ${serverSecretName}.owner = username;
    ${meilisearchSecretName}.owner = username;
  };

  home.ifEnabled = delib.rootlessQuadletModule homeconfig { } (
    quadletCfg:
    let
      podRef = quadletCfg.pods.${podName}.ref;
      crawlerRef = quadletCfg.containers.${crawlerName}.ref;
      meilisearchRef = quadletCfg.containers.${meilisearchName}.ref;
      ollamaRef = quadletCfg.containers.${ollamaName}.ref;
      ollamaNetRef = quadletCfg.networks.${ollamaNetName}.ref;
    in
    {
      pods.${podName} = {
        serviceConfig.Restart = "on-failure";
        podConfig = {
          networks = [
            quadletCfg.networks.caddy-net.ref
            ollamaNetRef
          ];
        };
      };
      containers = {
        ${serverName} = {
          serviceConfig.Restart = "on-failure";
          unitConfig = rec {
            Requires = [
              crawlerRef
              meilisearchRef
              ollamaRef
            ];
            After = Requires;
          };
          containerConfig = {
            pod = podRef;
            image = "ghcr.io/karakeep-app/karakeep:${KARAKEEP_VERSION}";
            volumes = serverVolumes;
            environments = {
              DATA_DIR = "/data";
              MEILI_ADDR = "http://${meilisearchName}:7700";
              BROWSER_WEB_URL = "http://${crawlerName}:9222";
              NEXTAUTH_URL = "https://${name}.songpola.dev";
              inherit
                OLLAMA_BASE_URL
                INFERENCE_TEXT_MODEL
                INFERENCE_IMAGE_MODEL
                INFERENCE_CONTEXT_LENGTH
                ;
            };
            environmentFiles = [ secrets.${serverSecretName}.path ];
            labels = {
              "caddy" = "${name}.songpola.dev";
              "caddy.reverse_proxy" = "{{upstreams 3000}}";
            };
          };
        };
        ${crawlerName} = {
          serviceConfig.Restart = "on-failure";
          containerConfig = {
            pod = podRef;
            image = "gcr.io/zenika-hub/alpine-chrome:124";
            exec =
              [
                "--no-sandbox"
                "--disable-gpu"
                "--disable-dev-shm-usage"
                "--remote-debugging-address=0.0.0.0"
                "--remote-debugging-port=9222"
                "--hide-scrollbars"
              ]
              |> lib.concatStringsSep " ";
          };
        };
        ${meilisearchName} = {
          serviceConfig.Restart = "on-failure";
          containerConfig = {
            pod = podRef;
            image = "docker.io/getmeili/meilisearch:v1.13.3";
            volumes = meilisearchVolumes;
            environments = {
              MEILI_NO_ANALYTICS = "true";
            };
            environmentFiles = [ secrets.${meilisearchSecretName}.path ];
          };
        };
      };
    }
  );
}
