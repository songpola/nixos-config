{
  delib,
  homeconfig,
  host,
  username,
  secrets,
  ...
}:
let
  name = "muse";
  secretName = "containers/${name}/env";
in
delib.module rec {
  inherit name;

  options = delib.singleEnableOption host.containersFeatured;

  myconfig.ifEnabled.secrets.enable = true;

  nixos.ifEnabled.sops.secrets.${secretName}.owner = username;

  home.ifEnabled = delib.rootlessQuadletModule homeconfig { } {
    containers.${name} = {
      serviceConfig.Restart = "on-failure";
      containerConfig = {
        # Fix for v2.11.1
        # See: https://github.com/museofficial/muse/pull/1278
        image = "ghcr.io/museofficial/muse:pr-1278";
        volumes = [
          "/tank/songpola/muse/data:/data"
        ];
        environments = {
          ENABLE_SPONSORBLOCK = "true";
        };
        environmentFiles = [ secrets.${secretName}.path ];
      };
    };
  };
}
