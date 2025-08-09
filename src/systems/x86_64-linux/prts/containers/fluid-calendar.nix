{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkMerge;
  inherit (lib.${namespace}) mkRootlessQuadletModule;

  podName = "fluid-calendar";
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

      serverImage = "docker.io/eibrahim/fluid-calendar:1.4.0";
      dbImage = "postgres:16-alpine";

      dbVolumes = [
        "/tank/songpola/db/fluid-calendar/db-data:/var/lib/postgresql/data"
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
            environmentFiles = [ serverSecretPath ];
            labels = {
              "caddy" = "${podName}.songpola.dev";
              "caddy.reverse_proxy" = "{{upstreams 3000}}";
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
            healthCmd = "pg_isready -U fluid -d fluid_calendar";
            healthInterval = "5s";
            healthTimeout = "5s";
            healthRetries = 5;
          };
        };
      };
    }
  ))
]
