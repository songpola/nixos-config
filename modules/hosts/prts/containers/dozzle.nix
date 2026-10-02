# Dozzle for viewing container logs
# DISABLED: to enable, add `den.aspects."prts".dozzle` to `den.aspects."prts".includes`.
{ den, lib, ... }:
{
  den.aspects."prts" = {
    _.dozzle.nixos =
      { config, ... }:
      let
        inherit (config.virtualisation.quadlet) volumes;
        caddy = import ./_caddy.nix config;
      in
      {
        virtualisation.quadlet = {
          containers."dozzle".containerConfig = lib.mkMerge [
            {
              image = "docker.io/amir20/dozzle:latest";
              volumes = [
                "%t/podman/podman.sock:/var/run/docker.sock"
                "${volumes."dozzle-data".ref}:/data"
              ];
              environments = {
                TZ = "Asia/Bangkok";
                DOZZLE_ENABLE_ACTIONS = "true";
              };
            }
            (caddy {
              address = "dozzle.songpola.dev";
              port = 8080;
            })
          ];
          volumes."dozzle-data" = { };
        };
      };
  };
}
