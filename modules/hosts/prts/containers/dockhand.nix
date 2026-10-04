# Dockhand for managing containers and compose stacks
# Runs as a NixOS oci-containers unit (podman backend), so it doesn't need quadlet-nix.
{ den, lib, ... }:
let
  dataDir = "/tank/v2/services/dockhand";
  # Reuse the stacks previously managed by Dockge (same `<stacks>/<stack>/compose.yaml` layout)
  stacksDir = "/tank/v2/services/dockge/stacks";
  # Created outside Nix; shared with caddy-docker-proxy (see ./caddy-reverse-proxy.nix)
  ingressNetwork = "caddy-reverse-proxy-ingress";
in
{
  den.aspects."prts" = {
    _.dockhand.nixos =
      { config, ... }:
      let
        uid = toString config.users.users.songpola.uid;
        gid = toString config.users.groups.users.gid;
      in
      {
        # Dynamic GIDs are only assigned at activation, so the config can't read one;
        # pin podman's GID to pass it to the container (--group-add) for socket access
        users.groups.podman.gid = 991;

        systemd.tmpfiles.rules = [ "d ${dataDir} 0755 ${uid} ${gid} -" ];

        virtualisation.oci-containers.containers."dockhand" = {
          image = "docker.io/fnsys/dockhand:latest";
          volumes = [
            "/run/podman/podman.sock:/var/run/docker.sock"
            # Same path inside and outside so stacks with relative bind mounts work
            "${dataDir}:${dataDir}"
            "${stacksDir}:${stacksDir}"
          ];
          environment = {
            TZ = "Asia/Bangkok";
            # Only sets file ownership (songpola:users); not a security boundary,
            # since the podman socket already grants root-equivalent access
            PUID = uid;
            PGID = gid;
            DATA_DIR = dataDir;
            STACKS_DIR = stacksDir;
          };
          extraOptions = [ "--group-add=${toString config.users.groups.podman.gid}" ];
          networks = [ ingressNetwork ];
          labels = {
            "caddy" = "dockhand.songpola.dev";
            "caddy.reverse_proxy" = "{{upstreams 3000}}";
          };
        };
      };
  };
}
