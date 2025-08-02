{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkMerge;
  inherit (lib.${namespace}) mkRootlessQuadletModule getConfigPath;
in
mkMerge [
  (mkRootlessQuadletModule config { } (quadletCfg: {
    containers = {
      radicale = {
        containerConfig = {
          image = "docker.io/tomsquest/docker-radicale:3.5.4.0";
          volumes = [
            "${quadletCfg.volumes.radicale-data.ref}:/data"
            "${getConfigPath "/radicale"}:/config:ro"
          ];
          labels = {
            "caddy" = "radicale.songpola.dev";
            "caddy.reverse_proxy" = "{{upstreams 5232}}";
          };
          networks = [ quadletCfg.networks.caddy-net.ref ];

          # Hardening container security.
          # Based on https://github.com/tomsquest/docker-radicale/issues/122#issuecomment-2323388423
          healthCmd = "curl -f http://127.0.0.1:5232 || exit 1";
          healthInterval = "30s";
          healthRetries = 3;
          runInit = true;
          readOnly = true;
          noNewPrivileges = true;
          dropCapabilities = [ "ALL" ];
          addCapabilities = [
            "SETUID"
            "SETGID"
            "KILL"
          ];

          # Skip chown when using volumes instead of bind mounts.
          # See https://github.com/tomsquest/docker-radicale#volumes-versus-bind-mounts
          environments = {
            TAKE_FILE_OWNERSHIP = "false";
          };
        };
        serviceConfig = {
          TasksMax = 50;
          MemoryHigh = "256M";
        };
      };
    };
    volumes = {
      radicale-data = { };
    };
  }))
]
