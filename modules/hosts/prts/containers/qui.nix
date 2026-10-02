# qui for managing qBittorrent instances
# DISABLED: to enable, add `den.aspects."prts".qui` to `den.aspects."prts".includes`.
# Other containers may append to `containers."qui".containerConfig.volumes`
# for local filesystem access: https://getqui.com/docs/getting-started/docker#local-filesystem-access
{ den, lib, ... }:
let
  configDir = "/tank/v2/services/qui/config";
in
{
  den.aspects."prts" = {
    _.qui.nixos =
      { config, ... }:
      let
        inherit (config.virtualisation.quadlet) networks;
        caddy = import ./_caddy.nix config;
      in
      {
        virtualisation.quadlet = {
          networks."qui" = { };
          containers."qui".containerConfig = lib.mkMerge [
            {
              # https://hotio.dev/containers/qui/
              image = "ghcr.io/hotio/qui:latest";
              environments = {
                TZ = "Asia/Bangkok";
                PUID = "1000";
                PGID = "1000";
              };
              volumes = [
                "${configDir}:/config"
              ];
              networks = [ networks."qui".ref ];
            }
            (caddy {
              address = "qui.songpola.dev";
              port = 7476;
            })
          ];
        };
      };
  };
}
