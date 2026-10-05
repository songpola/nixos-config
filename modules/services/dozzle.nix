# Dozzle for viewing container logs (https://dozzle.dev)
# Runs as a NixOS oci-containers unit (podman backend) with access to the rootful podman socket.
# Exposed through services.caddy-reverse-proxy when settings.domain is set, else on settings.port.
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
            };
          };
        })
      ];
  };
}
