{
  delib,
  homeconfig,
  host,
  ...
}:
delib.module rec {
  name = "pyload";

  options = delib.singleEnableOption host.containersFeatured;

  home.ifEnabled = delib.rootlessQuadletModule homeconfig { } (quadletCfg: {
    containers.${name} = {
      serviceConfig.Restart = "no";
      containerConfig = {
        image = "lscr.io/linuxserver/pyload-ng:0.5.0b3.dev92-ls189";
        volumes = [
          "/tank/songpola/pyload/config:/config"
          "/tank/songpola/pyload/downloads:/downloads"
        ];
        environments = {
          PUID = "0";
          PGID = "0";
          TZ = "Asia/Bangkok";
        };
        networks = [ quadletCfg.networks.caddy-net.ref ];
        labels = {
          "caddy" = "${name}.songpola.dev, dl.songpola.dev";
          "caddy.reverse_proxy" = "{{upstreams 8000}}";
        };
      };
    };
  });
}
