{
  delib,
  homeconfig,
  host,
  username,
  secrets,
  lib,
  ...
}:
let
  # NAME
  name = "seafile";
  dbName = "${name}-db";
  memcachedName = "${name}-memcached";
  serverName = "${name}-server";
  seadocName = "${name}-seadoc";
  networkName = "${name}-net";

  # ENV
  SEAFILE_IMAGE = "docker.io/seafileltd/seafile-mc:12.0.14";
  SEAFILE_DB_IMAGE = "docker.io/mariadb:10.11";
  SEAFILE_MEMCACHED_IMAGE = "docker.io/memcached:1.6.29";
  SEADOC_IMAGE = "docker.io/seafileltd/sdoc-server:1.0.5";

  SEAFILE_MYSQL_VOLUME = "/tank/songpola/db/seafile/db-data";
  SEAFILE_VOLUME = "/tank/songpola/seafile/server-data";
  SEADOC_VOLUME = "/tank/songpola/seafile/seadoc-data";

  SEAFILE_MYSQL_DB_HOST = dbName;
  SEAFILE_SERVER_HOSTNAME = "${name}.songpola.dev";
  SEAFILE_SERVER_PROTOCOL = "https";
  TIME_ZONE = "Asia/Bangkok";
in
delib.module {
  inherit name;

  options = delib.singleEnableOption host.containersFeatured;

  myconfig.ifEnabled.secrets.enable = true;

  nixos.ifEnabled.sops.secrets = {
    "containers/${dbName}/env".owner = username;
    "containers/${serverName}/env".owner = username;
    "containers/${seadocName}/env".owner = username;
  };

  home.ifEnabled = delib.rootlessQuadletModule homeconfig { } (quadletCfg: {
    networks.${networkName} = { };
    containers.${dbName} = {
      serviceConfig.Restart = "no";
      containerConfig = {
        image = SEAFILE_DB_IMAGE;
        volumes = [ "${SEAFILE_MYSQL_VOLUME}:/var/lib/mysql" ];
        environments = {
          # MYSQL_ROOT_PASSWORD (secrets)
          MYSQL_LOG_CONSOLE = "true";
          MARIADB_AUTO_UPGRADE = "1";
        };
        environmentFiles = [ secrets."containers/${dbName}/env".path ];
        networks = [ quadletCfg.networks.${networkName}.ref ];
        notify = "healthy";
        healthCmd =
          [
            "/usr/local/bin/healthcheck.sh"
            "--connect"
            "--mariadbupgrade"
            "--innodb_initialized"
          ]
          |> lib.concatStringsSep " ";
        healthInterval = "20s";
        healthStartPeriod = "30s";
        healthTimeout = "5s";
        healthRetries = 10;
      };
    };
    containers.${memcachedName} = {
      serviceConfig.Restart = "no";
      containerConfig = {
        image = SEAFILE_MEMCACHED_IMAGE;
        exec = "memcached -m 256";
        networks = [ quadletCfg.networks.${networkName}.ref ];
        networkAliases = [ "memcached" ];
      };
    };
    containers.${serverName} = {
      serviceConfig.Restart = "no";
      unitConfig = rec {
        Requires = [ quadletCfg.containers.${dbName}.ref ];
        After = Requires;
      };
      containerConfig = {
        image = SEAFILE_IMAGE;
        volumes = [ "${SEAFILE_VOLUME}:/shared" ];
        environments = {
          DB_HOST = SEAFILE_MYSQL_DB_HOST;
          DB_PORT = "3306";
          # DB_USER (secrets)
          # DB_ROOT_PASSWD (secrets)
          # DB_PASSWORD (secrets)
          SEAFILE_MYSQL_DB_CCNET_DB_NAME = "ccnet_db";
          SEAFILE_MYSQL_DB_SEAFILE_DB_NAME = "seafile_db";
          SEAFILE_MYSQL_DB_SEAHUB_DB_NAME = "seahub_db";
          inherit TIME_ZONE;
          # INIT_SEAFILE_ADMIN_EMAIL (secrets)
          # INIT_SEAFILE_ADMIN_PASSWORD (secrets)
          inherit SEAFILE_SERVER_HOSTNAME;
          inherit SEAFILE_SERVER_PROTOCOL;
          SITE_ROOT = "/";
          NON_ROOT = "false";
          # JWT_PRIVATE_KEY
          SEAFILE_LOG_TO_STDOUT = "false";
          ENABLE_SEADOC = "true";
          SEADOC_SERVER_URL = "${SEAFILE_SERVER_PROTOCOL}://${SEAFILE_SERVER_HOSTNAME}/sdoc-server";
        };
        environmentFiles = [ secrets."containers/${serverName}/env".path ];
        networks = [
          quadletCfg.networks.${networkName}.ref
          quadletCfg.networks.caddy-net.ref
        ];
        labels = {
          "caddy" = SEAFILE_SERVER_HOSTNAME;
          "caddy.reverse_proxy" = "{{upstreams 80}}";
        };
      };
    };
    containers.${seadocName} = {
      serviceConfig.Restart = "no";
      unitConfig = rec {
        Requires = [ quadletCfg.containers.${dbName}.ref ];
        After = Requires;
      };
      containerConfig = {
        image = SEADOC_IMAGE;
        volumes = [ "${SEADOC_VOLUME}:/shared" ];
        environments = {
          DB_HOST = SEAFILE_MYSQL_DB_HOST;
          DB_PORT = "3306";
          # DB_USER
          # DB_PASSWORD
          DB_NAME = "seahub_db";
          inherit TIME_ZONE;
          # JWT_PRIVATE_KEY
          NON_ROOT = "false";
          SEAHUB_SERVICE_URL = "${SEAFILE_SERVER_PROTOCOL}://${SEAFILE_SERVER_HOSTNAME}";
        };
        environmentFiles = [ secrets."containers/${seadocName}/env".path ];
        networks = [
          quadletCfg.networks.${networkName}.ref
          quadletCfg.networks.caddy-net.ref
        ];
        labels = {
          "caddy" = SEAFILE_SERVER_HOSTNAME;
          "caddy.@ws.0_header" = "Connection *Upgrade*";
          "caddy.@ws.1_header" = "Upgrade websocket";
          "caddy.0_reverse_proxy" = "@ws {{upstreams 80}}";
          "caddy.1_handle_path" = "/socket.io/*";
          "caddy.1_handle_path.0_rewrite" = "* /socket.io{uri}";
          "caddy.1_handle_path.1_reverse_proxy" = "{{upstreams 80}}";
          "caddy.2_handle_path" = "/sdoc-server/*";
          "caddy.2_handle_path.0_rewrite" = "* {uri}";
          "caddy.2_handle_path.1_reverse_proxy" = "{{upstreams 80}}";
        };
      };
    };
  });
}
