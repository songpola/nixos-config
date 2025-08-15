{
  delib,
  homeconfig,
  host,
  lib,
  ...
}:
let
  PORT_TCP_DB = "1521";
in
delib.module rec {
  name = "int-301-db";

  options = delib.singleEnableOption host.containersFeatured;

  nixos.ifEnabled.networking.firewall.allowedTCPPorts = [ (lib.toInt PORT_TCP_DB) ];

  home.ifEnabled = delib.rootlessQuadletModule homeconfig { } (quadletCfg: {
    containers.${name} = {
      serviceConfig.Restart = "on-failure";
      containerConfig = {
        image = "container-registry.oracle.com/database/free:23.8.0.0";
        publishPorts = [ "${PORT_TCP_DB}:1521" ];
        volumes = [
          "${quadletCfg.volumes."${name}-data".ref}:/opt/oracle/oradata"
        ];
      };
    };
    volumes."${name}-data" = { };
  });
}
