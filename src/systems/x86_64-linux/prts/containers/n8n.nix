{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkMerge;
  inherit (lib.${namespace}) mkRootlessQuadletModule;

  podName = "n8n";
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

      serverImage = "docker.io/n8nio/n8n:1.105.4";
      dbImage = "docker.io/postgres:16";

      serverVolumes = [
        "/tank/songpola/n8n/server-data:/home/node/.n8n"
      ];
      dbVolumes = [
        "/tank/songpola/db/n8n/db-data:/var/lib/postgresql/data"
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
            environments = {
              GENERIC_TIMEZONE = "Asia/Bangkok";
              TZ = "Asia/Bangkok";

              # WARNING: Permissions 0644 for n8n settings file /home/node/.n8n/config are too wide.
              # This is ignored for now, but in the future n8n will attempt to change the permissions automatically.
              # To automatically enforce correct permissions now set N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true (recommended),
              # or turn this check off set N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=false.
              N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS = "true";

              # Running n8n without task runners is deprecated.
              # Task runners will be turned on by default in a future version.
              # Please set `N8N_RUNNERS_ENABLED=true` to enable task runners now and avoid potential issues in the future.
              # Learn more: https://docs.n8n.io/hosting/configuration/task-runners/
              N8N_RUNNERS_ENABLED = "true";
            };
            environmentFiles = [ serverSecretPath ];
            labels = {
              "caddy" = "${podName}.songpola.dev";
              "caddy.reverse_proxy" = "{{upstreams 5678}}";
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
            healthCmd = "pg_isready -h localhost -U $$POSTGRES_USER -d $$POSTGRES_DB";
            healthInterval = "5s";
            healthTimeout = "5s";
            healthRetries = 10;
          };
        };
      };
    }
  ))
]
