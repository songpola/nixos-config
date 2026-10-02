# Dockge for managing container stacks
# DISABLED: to enable, add `den.aspects."prts".dockge` to `den.aspects."prts".includes`.
{ den, lib, ... }:
let
  dataDir = "/tank/v2/services/dockge/data";
  stacksDir = "/tank/v2/services/dockge/stacks";
in
{
  den.aspects."prts" = {
    _.dockge.nixos =
      { config, ... }:
      let
        caddy = import ./_caddy.nix config;
      in
      {
        virtualisation.quadlet.containers."dockge".containerConfig = lib.mkMerge [
          {
            image = "docker.io/louislam/dockge:1";
            volumes = [
              "%t/podman/podman.sock:/var/run/docker.sock"
              "${dataDir}:/app/data"
              "${stacksDir}:${stacksDir}"
            ];
            environments = {
              TZ = "Asia/Bangkok";
              PUID = "1000";
              PGID = "1000";
              DOCKGE_STACKS_DIR = stacksDir;
            };
          }
          (caddy {
            address = "dockge.songpola.dev";
            port = 5001;
          })
        ];
      };
  };
}
