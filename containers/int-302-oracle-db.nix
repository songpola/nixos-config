{
  delib,
  lib,
  quadletCfg,
  ...
}:
let
  name = "int-302-oracle-db";

  volData = "${name}-data";

  PORT_TCP_DB = "1521";
in
delib.mkContainerModule {
  inherit name;

  extraNixosConfig = {
    networking.firewall.allowedTCPPorts = map lib.toInt [ PORT_TCP_DB ];
  };

  rootlessQuadletConfig = {
    volumes.${volData} = { };

    containers.${name}.containerConfig = {
      image = "container-registry.oracle.com/database/free:23.8.0.0";
      publishPorts = [ "${PORT_TCP_DB}:1521" ];
      volumes = [ "${quadletCfg.volumes.${volData}.ref}:/opt/oracle/oradata" ];
    };
  };
}
