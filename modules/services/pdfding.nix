{
  delib,
  quadletCfg,
  secrets,
  username,
  ...
}:
let
  name = "pdfding";
  secretName = "containers/${name}/env";
in
delib.mkServiceModule rec {
  inherit name;

  rootlessSecrets = {
    ${secretName}.owner = username;
  };
  rootlessQuadletConfig.containers.${name}.containerConfig = rec {
    image = "docker.io/mrmn/pdfding:v1.3.1";
    volumes = [
      "/tank/songpola/pdfding/media:/home/nonroot/pdfding/media"
      "/tank/songpola/db/pdfding/db:/home/nonroot/pdfding/db"
    ];
    environments = {
      HOST_NAME = labels."caddy";
      DEFAULT_THEME = "dark";
      # SECRET_KEY (secrets)
    };
    environmentFiles = [ secrets.${secretName}.path ];
    networks = [ quadletCfg.networks.caddy-net.ref ];
    labels = {
      "caddy" = "${name}.songpola.dev";
      "caddy.reverse_proxy" = "{{upstreams 8000}}";
    };
  };
}
