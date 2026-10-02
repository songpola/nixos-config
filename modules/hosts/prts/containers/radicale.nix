# Radicale for calendar and contact management
# DISABLED: to enable, add `den.aspects."prts".radicale` to `den.aspects."prts".includes`.
{ lib, ... }:
let
  configDir = "/tank/v1/radicale/config";
  dataDir = "/tank/v1/radicale/data";
in
{
  den.aspects."prts"._.radicale.nixos =
    { config, ... }:
    let
      caddy = import ./_caddy.nix config;
    in
    {
      virtualisation.quadlet.containers."radicale".containerConfig = lib.mkMerge [
        {
          image = "ghcr.io/kozea/radicale:latest";
          volumes = [
            "${configDir}:/etc/radicale:ro"
            "${dataDir}:/var/lib/radicale"
          ];
          environments = {
            TZ = "Asia/Bangkok";
          };
        }
        (caddy {
          address = "radicale.songpola.dev";
          port = 5232;
        })
      ];
    };
}
