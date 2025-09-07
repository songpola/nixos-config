{
  delib,
  secrets,
  lib,
  quadletCfg,
  ...
}:
let
  name = "karakeep";
  nameServer = "${name}-server";
  nameMeilisearch = "${name}-meilisearch";
  nameCrawler = "${name}-crawler";

  secretServer = "containers/${nameServer}/env";
  secretMeilisearch = "containers/${nameMeilisearch}/env";

  KARAKEEP_VERSION = "0.26.0";

  # !!! External !!!
  # See ./ollama.nix
  nameOllama = "ollama";
  nameOllamaNet = "${nameOllama}-net";

  OLLAMA_BASE_URL = "http://${nameOllama}:11434/";
  INFERENCE_TEXT_MODEL = "gemma3:4b"; # gemma3:4b can recieve text input
  INFERENCE_IMAGE_MODEL = "gemma3:4b"; # gemma3:4b can recieve image input
  INFERENCE_CONTEXT_LENGTH = "131072"; # gemma3:4b has 128K context size

  refPod = quadletCfg.pods.${name}.ref;
  refCrawler = quadletCfg.containers.${nameCrawler}.ref;
  refMeilisearch = quadletCfg.containers.${nameMeilisearch}.ref;
  refCaddyNet = quadletCfg.networks.caddy-net.ref;
  refOllama = quadletCfg.containers.${nameOllama}.ref;
  refOllamaNet = quadletCfg.networks.${nameOllamaNet}.ref;
in
delib.mkContainerModule rec {
  inherit name;

  rootlessSecrets = [
    secretServer
    secretMeilisearch
  ];

  rootlessQuadletConfig = {
    pods.${name}.podConfig.networks = [
      refCaddyNet
      refOllamaNet
    ];

    containers.${nameServer} = {
      containerConfig = rec {
        pod = refPod;
        image = "ghcr.io/karakeep-app/karakeep:${KARAKEEP_VERSION}";
        volumes = [ "/tank/songpola/karakeep/server-data:/data" ];
        environments = {
          DATA_DIR = "/data";
          MEILI_ADDR = "http://${nameMeilisearch}:7700";
          BROWSER_WEB_URL = "http://${nameCrawler}:9222";
          NEXTAUTH_URL = "https://${labels."caddy"}";
          inherit
            OLLAMA_BASE_URL
            INFERENCE_TEXT_MODEL
            INFERENCE_IMAGE_MODEL
            INFERENCE_CONTEXT_LENGTH
            ;
        };
        environmentFiles = [ secrets.${secretServer}.path ];
        labels = {
          "caddy" = "${name}.songpola.dev";
          "caddy.reverse_proxy" = "{{upstreams 3000}}";
        };
      };
      unitConfig = rec {
        Requires = [
          refCrawler
          refMeilisearch
          refOllama
        ];
        After = Requires;
      };
    };

    containers.${nameCrawler}.containerConfig = {
      pod = refPod;
      image = "gcr.io/zenika-hub/alpine-chrome:124";
      exec = lib.concatStringsSep (" ") [
        "--no-sandbox"
        "--disable-gpu"
        "--disable-dev-shm-usage"
        "--remote-debugging-address=0.0.0.0"
        "--remote-debugging-port=9222"
        "--hide-scrollbars"
      ];
    };

    containers.${nameMeilisearch}.containerConfig = {
      pod = refPod;
      image = "docker.io/getmeili/meilisearch:v1.13.3";
      volumes = [ "/tank/songpola/karakeep/meilisearch-data:/meili_data" ];
      environments.MEILI_NO_ANALYTICS = "true";
      environmentFiles = [ secrets.${secretMeilisearch}.path ];
    };
  };
}
