# ProtonMail Bridge for email integration with Thunderbird
# DISABLED: to enable, add `den.aspects."prts".protonmail-bridge` to `den.aspects."prts".includes`.
{ den, ... }:
let
  dataDir = "/tank/v2/services/protonmail-bridge/root";
  smtpPort = 1025;
  imapPort = 1143;
in
{
  den.aspects."prts" = {
    _.protonmail-bridge.nixos = {
      virtualisation.quadlet.containers."protonmail-bridge".containerConfig = {
        # https://github.com/shenxn/protonmail-bridge-docker/issues/135
        image = "docker.io/dancwilliams/protonmail-bridge:latest";
        volumes = [
          "${dataDir}:/root"
        ];
        environments = {
          TZ = "Asia/Bangkok";
        };
        publishPorts = [
          "${toString smtpPort}:25"
          "${toString imapPort}:143"
        ];
      };
    };
  };
}
