{
  delib,
  quadletCfg,
  secrets,
  lib,
  ...
}:
let
  name = "int-105-wordpress";

  nameServer = "${name}-server";
  nameServerVol = "${nameServer}-data";
  nameServerSecret = "containers/${nameServer}/env";

  nameDb = "${name}-db";
  nameDbVol = "${nameDb}-data";
  nameDbSecret = "containers/${nameDb}/env";

  PORT_TCP_WP_WEB = "8080";
in
delib.mkContainerModule rec {
  inherit name;

  extraNixosConfig = {
    networking.firewall.allowedTCPPorts = map lib.toInt [ PORT_TCP_WP_WEB ];
  };

  rootlessSecrets = [
    nameServerSecret
    nameDbSecret
  ];

  rootlessQuadletConfig = {
    pods.${name} = {
      autoStart = false;
      podConfig.publishPorts = [ "${PORT_TCP_WP_WEB}:80" ];
    };
    volumes.${nameServerVol} = { };
    volumes.${nameDbVol} = { };
    containers.${nameServer} = {
      autoStart = false;
      containerConfig = {
        pod = quadletCfg.pods.${name}.ref;
        image = "docker.io/wordpress:6.8.2";
        volumes = [ "${quadletCfg.volumes.${nameServerVol}.ref}:/var/www/html" ];
        environments = {
          WORDPRESS_DB_HOST = nameDb;
        };
        environmentFiles = [ secrets.${nameServerSecret}.path ];
      };
      unitConfig = rec {
        Requires = [ quadletCfg.containers.${nameDb}.ref ];
        After = Requires;
      };
    };
    containers.${nameDb} = {
      autoStart = false;
      containerConfig = {
        pod = quadletCfg.pods.${name}.ref;
        image = "docker.io/mariadb:12.0.2";
        volumes = [ "${quadletCfg.volumes.${nameDbVol}.ref}:/var/lib/mysql" ];
        environmentFiles = [ secrets.${nameDbSecret}.path ];
      };
    };
  };
}
