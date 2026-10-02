# Jellyfin for media streaming (with NVIDIA GPU)
# DISABLED: to enable, add `den.aspects."prts".jellyfin` to `den.aspects."prts".includes`.
{ den, lib, ... }:
let
  configDir = "/tank/v2/services/jellyfin/config";
  mediaDataDir = "/tank/v2/starrs-data/media";

  # Same as in ./starrs.nix, to enable the "Atomic Move" technique
  # (hardlinking instead of copying files).
  containerMediaDataDir = "/mnt/starrs-data/media";
in
{
  den.aspects."prts" = {
    _.jellyfin.nixos =
      { config, ... }:
      let
        caddy = import ./_caddy.nix config;
      in
      {
        virtualisation.quadlet.containers."jellyfin".containerConfig = lib.mkMerge [
          {
            image = "lscr.io/linuxserver/jellyfin:version-10.11.8ubu2404";
            environments = {
              TZ = "Asia/Bangkok";
              PUID = "1000";
              PGID = "1000";
              #? JELLYFIN_PublishedServerUrl
            };
            volumes = [
              "${configDir}:/config"
              "${mediaDataDir}:${containerMediaDataDir}"
            ];
            devices = [
              "nvidia.com/gpu=all"
            ];
          }
          (caddy {
            address = "jf.songpola.dev";
            port = 8096;
          })
        ];
      };
  };
}
