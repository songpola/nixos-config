{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkMerge;
  inherit (lib.${namespace}) mkRootlessQuadletModule;

  podName = "vikunja";
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

      serverImage = "docker.io/vikunja/vikunja:0.24.6";
      dbImage = "docker.io/postgres:17";

      serverVolumes = [
        "/tank/songpola/vikunja/server-data:/app/vikunja/files"
      ];
      dbVolumes = [
        "/tank/songpola/db/vikunja/db-data:/var/lib/postgresql/data"
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
              dependsOn = [
                dbRef
              ];
            in
            {
              Requires = dependsOn;
              After = dependsOn;
            };
          containerConfig = {
            pod = podRef;
            image = serverImage;
            volumes = serverVolumes;
            environments = {
              VIKUNJA_SERVICE_PUBLICURL = "https://vikunja.songpola.dev";
              VIKUNJA_DATABASE_HOST = dbName;
              VIKUNJA_DATABASE_TYPE = "postgres";
            };
            environmentFiles = [ serverSecretPath ];
            labels = {
              "caddy" = "${podName}.songpola.dev";
              "caddy.reverse_proxy" = "{{upstreams 3456}}";
            };
          };
        };
        ${dbName} = {
          containerConfig = {
            pod = podRef;
            image = dbImage;
            volumes = dbVolumes;
            environmentFiles = [ dbSecretPath ];
            notify = "healthy";
            healthCmd = "pg_isready -h localhost -U $$POSTGRES_USER";
            healthInterval = "2s";
            healthStartPeriod = "30s";
          };
        };
      };
    }
  ))
]
