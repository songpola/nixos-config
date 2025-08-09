{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkMerge;
  inherit (lib.${namespace}) mkRootlessQuadletModule;

  podName = "kimai";
  serverName = "${podName}-server";
  dbName = "${podName}-db";

  serverSecretName = "containers/${serverName}/env";
  serverSecretPath = config.sops.secrets.${serverSecretName}.path;
  dbSecretName = "containers/${dbName}/env";
  dbSecretPath = config.sops.secrets.${dbSecretName}.path;
in
mkMerge [
  {
    ${namespace}.presets.secrets = true;
    sops.secrets = {
      ${serverSecretName}.owner = namespace;
      ${dbSecretName}.owner = namespace;
    };
  }
  (mkRootlessQuadletModule config { } (
    quadletCfg:
    let
      podRef = quadletCfg.pods.${podName}.ref;
      dbRef = quadletCfg.containers.${dbName}.ref;

      serverImage = "docker.io/kimai/kimai2:apache-2.38.0";
      dbImage = "docker.io/mysql:8.3";

      serverVolumes = [
        "/tank/songpola/kimai/server-data:/opt/kimai/var/data"
        "/tank/songpola/kimai/server-plugins:/opt/kimai/var/plugins"
      ];
      dbVolumes = [
        "/tank/songpola/db/kimai/db-data:/var/lib/mysql"
      ];
    in
    {
      pods = {
        ${podName} = {
          serviceConfig.Restart = "on-failure";
          podConfig = {
            networks = [ quadletCfg.networks.caddy-net.ref ];
          };
        };
      };
      containers = {
        ${serverName} = {
          unitConfig =
            let
              dependsOn = [ dbRef ];
            in
            {
              Requires = dependsOn;
              After = dependsOn;
            };
          containerConfig = {
            pod = podRef;
            image = serverImage;
            volumes = serverVolumes;
            environmentFiles = [ serverSecretPath ];
            labels = {
              "caddy" = "${podName}.songpola.dev";
              "caddy.reverse_proxy" = "{{upstreams 8001}}";
              "caddy.reverse_proxy.flush_interval" = "-1";
            };
          };
        };
        ${dbName} = {
          containerConfig = {
            pod = podRef;
            image = dbImage;
            volumes = dbVolumes;
            environmentFiles = [ dbSecretPath ];
            exec = "--default-storage-engine innodb";
            notify = "healthy";
            healthCmd = "mysqladmin -p$$MYSQL_ROOT_PASSWORD ping -h localhost";
            healthInterval = "20s";
            healthStartPeriod = "10s";
            healthTimeout = "10s";
            healthRetries = 3;
          };
        };
      };
    }
  ))
]
