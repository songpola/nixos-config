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
  (mkRootlessQuadletModule config (quadletCfg: {
    containers = {
      int-301-db = {
        serviceConfig = {
          Restart = "on-failure";
        };
        containerConfig = {
          image = "container-registry.oracle.com/database/free:23.8.0.0";
          publishPorts = [ "1521:1521" ];
          volumes = [
            "${quadletCfg.volumes.int-302-db-data.ref}:/opt/oracle/oradata"
          ];
        };
      };
    };
    volumes = {
      int-302-db-data = { };
    };
  }))
  {
    networking.firewall.allowedTCPPorts = [ 1521 ];
  }
]
