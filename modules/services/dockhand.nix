# Dockhand for managing containers and compose stacks (https://dockhand.pro)
# Runs as a NixOS oci-containers unit (podman backend) with access to the rootful podman socket.
# Exposed through services.caddy-reverse-proxy when settings.domain is set, else on settings.port.
{ den, lib, ... }:
let
  name = "dockhand";
  # Dockhand's web UI port inside the container
  containerPort = 3000;
in
{
  den.aspects.services.${name} = {
    includes = [ den.aspects.programs.podman ];

    settings = {
      dataDir = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/${name}";
        description = "Dockhand's data directory (database, settings)";
      };
      stacksDir = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Compose stacks directory (`<stacksDir>/<stack>/compose.yaml`); null means `<dataDir>/stacks`";
      };
      user = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          User (and its primary group) Dockhand runs as, which owns the files it writes.
          Not a security boundary: the podman socket already grants root-equivalent access.
          null keeps the image's default.
        '';
      };
      podmanGid = lib.mkOption {
        type = lib.types.int;
        default = 991;
        description = ''
          GID to pin the podman group to. Dynamic GIDs are only assigned at activation,
          so the config can't read one; the container needs it (--group-add) to use the socket.
        '';
      };
      domain = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "dockhand.example.com";
        description = "Serve Dockhand at this domain through services.caddy-reverse-proxy";
      };
      port = lib.mkOption {
        type = lib.types.nullOr lib.types.port;
        default = null;
        description = "Publish Dockhand on this host port (e.g. without Caddy)";
      };
      image = lib.mkOption {
        type = lib.types.str;
        default = "docker.io/fnsys/dockhand:latest";
        description = "Dockhand image";
      };
    };

    nixos =
      { config, host, ... }:
      let
        cfg = host.settings.services.${name};
        stacksDir = if cfg.stacksDir == null then "${cfg.dataDir}/stacks" else cfg.stacksDir;
        caddy = host.settings.services.caddy-reverse-proxy;
        hasCaddy = config.virtualisation.oci-containers.containers ? caddy-reverse-proxy;

        owner = if cfg.user == null then "root" else cfg.user;
        group = if cfg.user == null then "root" else config.users.users.${cfg.user}.group;
      in
      lib.mkMerge [
        {
          assertions = [
            {
              assertion = cfg.domain != null -> hasCaddy;
              message = "services.dockhand.domain needs the services.caddy-reverse-proxy aspect.";
            }
          ];

          users.groups.podman.gid = cfg.podmanGid;

          systemd.tmpfiles.rules = [
            "d ${cfg.dataDir} 0755 ${owner} ${group} -"
            "d ${stacksDir} 0755 ${owner} ${group} -"
          ];

          virtualisation.oci-containers.containers.${name} = {
            inherit (cfg) image;
            volumes = [
              "/run/podman/podman.sock:/var/run/docker.sock"
              # Same path inside and outside so stacks with relative bind mounts work
              "${cfg.dataDir}:${cfg.dataDir}"
            ]
            # Already mounted when it's inside dataDir
            ++ lib.optional (!lib.hasPrefix "${cfg.dataDir}/" stacksDir) "${stacksDir}:${stacksDir}";
            environment = {
              TZ = if config.time.timeZone == null then "UTC" else config.time.timeZone;
              DATA_DIR = cfg.dataDir;
              STACKS_DIR = stacksDir;
            }
            // lib.optionalAttrs (cfg.user != null) {
              PUID = toString config.users.users.${cfg.user}.uid;
              PGID = toString config.users.groups.${group}.gid;
            };
            extraOptions = [ "--group-add=${toString cfg.podmanGid}" ];
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
