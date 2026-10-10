# Dozzle for viewing container logs (https://dozzle.dev)
# Runs as a NixOS oci-containers unit (podman backend) with access to the rootful podman socket.
# Exposed through services.caddy-reverse-proxy when settings.domain is set, else on settings.port.
# The `forward-auth` sub-aspect puts it behind services.oauth2-proxy and makes Dozzle take the
# user from its headers (Dozzle's forward-proxy mode) instead of its own login.
{ den, lib, ... }:
let
  name = "dozzle";
  # Dozzle's web UI port inside the container
  containerPort = 8080;
in
{
  den.aspects.services.${name} = {
    includes = [ den.aspects.programs.podman ];

    settings = {
      enableActions = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Allow starting, stopping and restarting containers from the UI";
      };
      dataVolume = lib.mkOption {
        type = lib.types.str;
        default = "${name}-data";
        description = "Podman volume for Dozzle's /data (users, settings)";
      };
      domain = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "dozzle.example.com";
        description = "Serve Dozzle at this domain through services.caddy-reverse-proxy";
      };
      port = lib.mkOption {
        type = lib.types.nullOr lib.types.port;
        default = null;
        description = "Publish Dozzle on this host port (e.g. without Caddy)";
      };
      image = lib.mkOption {
        type = lib.types.str;
        default = "docker.io/amir20/dozzle:latest";
        description = "Dozzle image";
      };
    };

    nixos =
      { config, host, ... }:
      let
        cfg = host.settings.services.${name};
        caddy = host.settings.services.caddy-reverse-proxy;
        hasCaddy = config.virtualisation.oci-containers.containers ? caddy-reverse-proxy;
      in
      lib.mkMerge [
        {
          assertions = [
            {
              assertion = cfg.domain != null -> hasCaddy;
              message = "services.dozzle.domain needs the services.caddy-reverse-proxy aspect.";
            }
          ];

          virtualisation.oci-containers.containers.${name} = {
            inherit (cfg) image;
            volumes = [
              "/run/podman/podman.sock:/var/run/docker.sock"
              "${cfg.dataVolume}:/data"
            ];
            environment = {
              TZ = if config.time.timeZone == null then "UTC" else config.time.timeZone;
            }
            // lib.optionalAttrs cfg.enableActions { DOZZLE_ENABLE_ACTIONS = "true"; };
            ports = lib.optional (cfg.port != null) "${toString cfg.port}:${toString containerPort}";
            labels = den.aspects.programs.podman.meta.autoUpdateLabels;
            # Dozzle's built-in check (not wired into the image). Exec form (JSON array): the image
            # has no shell. The unit is ready only once it passes, so a bad auto-update rolls back.
            extraOptions = [
              ''--health-cmd=["/dozzle","healthcheck"]''
              "--health-interval=10s"
              "--health-start-period=30s"
            ];
            podman.sdnotify = "healthy";
          };
        }

        (lib.mkIf (cfg.domain != null) {
          systemd.services."podman-${name}" = rec {
            wants = [ "podman-network-${caddy.network}.service" ];
            after = wants;
          };

          virtualisation.oci-containers.containers.${name} = {
            networks = [ caddy.network ];
            labels = {
              "caddy" = cfg.domain;
              "caddy.reverse_proxy" = "{{upstreams ${toString containerPort}}}";
              # Dozzle links the container to its web UI
              "dev.dozzle.url" = "https://${cfg.domain}";
            };
          };
        })
      ];

    # Gate the site with `import auth <group>` and trust the identity headers. No roles header is
    # sent, so every user who passes the gate gets all Dozzle roles (actions included).
    _.forward-auth = {
      includes = [ den.aspects.services.oauth2-proxy ];

      settings = {
        group = lib.mkOption {
          type = lib.types.str;
          example = "admins@idm.example.com";
          description = "Group a user needs, as the identity provider sends it";
        };
        logoutUrl = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "https://auth.example.com/oauth2/sign_out";
          description = "Where Dozzle's logout button goes (oauth2-proxy's sign_out ends the session)";
        };
      };

      nixos =
        { host, ... }:
        let
          cfg = host.settings.services.${name};
          auth = cfg.forward-auth;
          headers = den.aspects.services.oauth2-proxy.meta.headers;
        in
        {
          assertions = [
            {
              assertion = cfg.domain != null && cfg.port == null;
              message = "services.dozzle.forward-auth needs services.dozzle.domain, and no port (it would skip the gate).";
            }
          ];

          virtualisation.oci-containers.containers.${name} = {
            labels."caddy.import" = "auth ${auth.group}";
            environment = {
              DOZZLE_AUTH_PROVIDER = "forward-proxy";
              DOZZLE_AUTH_HEADER_USER = headers.preferredUsername;
              DOZZLE_AUTH_HEADER_EMAIL = headers.email;
              DOZZLE_AUTH_HEADER_NAME = headers.preferredUsername;
            }
            // lib.optionalAttrs (auth.logoutUrl != null) { DOZZLE_AUTH_LOGOUT_URL = auth.logoutUrl; };
          };
        };
    };
  };
}
