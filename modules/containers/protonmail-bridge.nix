{
  delib,
  homeconfig,
  host,
  lib,
  ...
}:
let
  PORT_TCP_SMTP = "1025";
  PORT_TCP_IMAP = "1143";
in
delib.module rec {
  name = "protonmail-bridge";

  options = delib.singleEnableOption host.containersFeatured;

  nixos.ifEnabled = {
    networking.firewall.allowedTCPPorts =
      [
        PORT_TCP_SMTP
        PORT_TCP_IMAP
      ]
      |> map lib.toInt;
  };

  home.ifEnabled = delib.rootlessQuadletModule homeconfig { } (quadletCfg: {
    containers.protonmail-bridge = {
      serviceConfig.Restart = "on-failure";
      containerConfig = {
        image = "docker.io/shenxn/protonmail-bridge:3.19.0-1";
        volumes = [
          "/tank/songpola/${name}/root:/root"
        ];
        publishPorts = [
          "${PORT_TCP_SMTP}:25"
          "${PORT_TCP_IMAP}:143"
        ];
      };
    };
  });
}
