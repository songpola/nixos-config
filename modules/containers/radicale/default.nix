{
  delib,
  homeconfig,
  host,
  ...
}:
delib.module rec {
  name = "radicale";

  options = delib.singleEnableOption host.containersFeatured;

  home.ifEnabled = delib.rootlessQuadletModule homeconfig { } (quadletCfg: {
    containers.${name} = {
      serviceConfig.Restart = "on-failure";
      containerConfig = {
        image = "docker.io/tomsquest/docker-radicale:3.5.4.0";
        volumes = [
          "${quadletCfg.volumes."${name}-data".ref}:/data"
          "${./config}:/config/config:ro"
          "${./users}:/config/users:ro"
        ];
        labels = {
          "caddy" = "${name}.songpola.dev";
          "caddy.reverse_proxy" = "{{upstreams 5232}}";
        };
        networks = [ quadletCfg.networks.caddy-net.ref ];

        # Hardening container security.
        # Based on https://github.com/tomsquest/docker-radicale/issues/122#issuecomment-2323388423
        notify = "healthy";
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
    volumes."${name}-data" = { };
  });
}
