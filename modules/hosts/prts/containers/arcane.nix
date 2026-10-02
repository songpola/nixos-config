# Arcane for managing containers
# DISABLED: to enable, add `den.aspects."prts".arcane` to `den.aspects."prts".includes`.
{ den, lib, ... }:
let
  projectsDir = "/tank/v2/services/arcane/projects";
in
{
  den.aspects."prts" = {
    _.arcane.nixos =
      { config, ... }:
      let
        inherit (config.virtualisation.quadlet) volumes;
        inherit (config.sops) secrets;
        caddy = import ./_caddy.nix config;

        secret = "arcane/secrets.env";
      in
      {
        sops.secrets.${secret} = {
          sopsFile = ./arcane.secrets.env;
          format = "dotenv";
        };

        virtualisation.quadlet = {
          containers."arcane".containerConfig = lib.mkMerge [
            {
              image = "ghcr.io/getarcaneapp/arcane:latest";
              volumes = [
                "%t/podman/podman.sock:/var/run/docker.sock"
                "${volumes."arcane-data".ref}:/app/data"
                "${projectsDir}:${projectsDir}"
              ];
              environmentFiles = [
                secrets.${secret}.path
              ];
              environments = {
                TZ = "Asia/Bangkok";
                PUID = "1000";
                PGID = "1000";
                APP_URL = "https://arcane.songpola.dev";
                PROJECTS_DIRECTORY = projectsDir;
                BASE_SERVER_URL = "https://songpola.dev";
                #! ENCRYPTION_KEY (from secrets)
                #! JWT_SECRET (from secrets)
              };
            }
            (caddy {
              address = "arcane.songpola.dev";
              port = 3552;
            })
          ];
          volumes."arcane-data" = { };
        };
      };
  };
}
