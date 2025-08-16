{
  delib,
  homeconfig,
  host,
  username,
  secrets,
  ...
}:
let
  name = "vikunja";

  podName = name;
  serverName = "${podName}-server";
  dbName = "${podName}-db";

  serverImage = "docker.io/vikunja/vikunja:0.24.6";
  dbImage = "docker.io/postgres:17";

  serverVolumes = [
    "/tank/songpola/${name}/server-data:/app/vikunja/files"
  ];
  dbVolumes = [
    "/tank/songpola/db/${name}/db-data:/var/lib/postgresql/data"
  ];

  serverSecretName = "containers/${serverName}/env";
  serverSecretPath = secrets.${serverSecretName}.path;
  dbSecretName = "containers/${dbName}/env";
  dbSecretPath = secrets.${dbSecretName}.path;
in
delib.module {
  inherit name;

  options = delib.singleEnableOption host.containersFeatured;

  myconfig.ifEnabled.secrets.enable = true;

  nixos.ifEnabled.sops.secrets = {
    ${serverSecretName}.owner = username;
    ${dbSecretName}.owner = username;
  };

  home.ifEnabled = delib.rootlessQuadletModule homeconfig { } (
    quadletCfg:
    let
      podRef = quadletCfg.pods.${podName}.ref;
      dbRef = quadletCfg.containers.${dbName}.ref;
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
          unitConfig = rec {
            Requires = [ dbRef ];
            After = Requires;
          };
          containerConfig = {
            pod = podRef;
            image = serverImage;
            volumes = serverVolumes;
            environments = {
              VIKUNJA_SERVICE_PUBLICURL = "https://${name}.songpola.dev";
              VIKUNJA_DATABASE_HOST = dbName;
              VIKUNJA_DATABASE_TYPE = "postgres";
            };
            environmentFiles = [ serverSecretPath ];
            labels = {
              "caddy" = "${name}.songpola.dev";
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
  );
}
