{ delib, quadletCfg, ... }:
delib.mkContainerModule rec {
  name = "super-productivity";

  rootlessQuadletConfig = {
    containers.${name} = {
      containerConfig = {
        image = "docker.io/johannesjo/super-productivity:v14.4.1";
        environments = {
          WEBDAV_BASE_URL = "https://seafile.songpola.dev/seafdav";
          WEBDAV_USERNAME = "songpola@songpola.dev";
          WEBDAV_SYNC_FOLDER_PATH = "super-productivity";
          IS_COMPRESSION_ENABLED = "true";
          IS_ENCRYPTION_ENABLED = "false";
        };
        networks = [ quadletCfg.networks.caddy-net.ref ];
        labels = {
          "caddy" = "${name}.songpola.dev";
          "caddy.reverse_proxy" = "{{upstreams 80}}";
        };
      };
    };
  };
}
