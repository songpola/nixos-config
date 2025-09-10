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
  nameDb = "${name}-db";

  volServerData = "${nameServer}-data";
  volDbData = "${nameDb}-data";

  secretServer = "containers/${nameServer}/env";
  secretDb = "containers/${nameDb}/env";

  PORT_TCP_WP_WEB = "8080";
in
delib.mkContainerModule rec {
  inherit name;

  extraNixosConfig = {
    networking.firewall.allowedTCPPorts = map lib.toInt [
      PORT_TCP_WP_WEB
    ];
  };

  rootlessSecrets = [
    secretServer
    secretDb
  ];

  rootlessQuadletConfig = {
    pods.${name} = {
      autoStart = false;
      podConfig.publishPorts = [ "${PORT_TCP_WP_WEB}:80" ];
    };

    volumes.${volServerData} = { };

    volumes.${volDbData} = { };

    containers.${nameServer} = {
      autoStart = false;
      containerConfig = {
        pod = quadletCfg.pods.${name}.ref;
        image = "docker.io/wordpress:6.8.2";
        volumes = [ "${quadletCfg.volumes.${volServerData}.ref}:/var/www/html" ];
        environments = {
          WORDPRESS_DB_HOST = nameDb;
        };
        environmentFiles = [ secrets.${secretServer}.path ];
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
        volumes = [ "${quadletCfg.volumes.${volDbData}.ref}:/var/lib/mysql" ];
        environmentFiles = [ secrets.${secretDb}.path ];
      };
    };
  };
}
