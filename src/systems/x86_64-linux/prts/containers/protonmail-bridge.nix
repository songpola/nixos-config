{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkMerge;
  inherit (lib.${namespace}) mkRootlessQuadletModule;
in
mkMerge [
  (mkRootlessQuadletModule config { } (quadletCfg: {
    containers = {
      protonmail-bridge = {
        serviceConfig.Restart = "on-failure";
        containerConfig = {
          image = "docker.io/shenxn/protonmail-bridge:3.19.0-1";
          volumes = [
            "/tank/songpola/protonmail-bridge:/root"
          ];
          publishPorts = [
            "1025:25" # SMTP
            "1143:143" # IMAP
          ];
        };
      };
    };
  }))
  {
    networking.firewall.allowedTCPPorts = [
      1025
      1143
    ];
  }
]
