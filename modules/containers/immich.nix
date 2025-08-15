{
  delib,
  homeconfig,
  host,
  username,
  secrets,
  ...
}:
let
  name = "immich";

  podName = name;
  serverName = "${podName}-server";
  dbName = "${podName}-db";
  redisName = "${podName}-redis";
  mlName = "${podName}-ml";
  modelCacheName = "${podName}-model-cache";

  serverSecretName = "containers/${serverName}/env";
  serverSecretPath = secrets.${serverSecretName}.path;

  dbSecretName = "containers/${dbName}/env";
  dbSecretPath = secrets.${dbSecretName}.path;

  UPLOAD_LOCATION = "/tank/songpola/${name}/server-data";
  DB_DATA_LOCATION = "/tank/songpola/db/${name}/db-data";

  externalLibraryVolumes = [
    "/tank/songpola/${name}/external:/mnt/external:ro"
  ];

  IMMICH_VERSION = "v1.137.3";
  serverImage = "ghcr.io/immich-app/immich-server:${IMMICH_VERSION}";
  mlImage = "ghcr.io/immich-app/immich-machine-learning:${IMMICH_VERSION}-cuda";
  redisImage = "docker.io/valkey/valkey:8-bookworm@sha256:facc1d2c3462975c34e10fccb167bfa92b0e0dbd992fc282c29a61c3243afb11";
  dbImage = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0@sha256:32324a2f41df5de9efe1af166b7008c3f55646f8d0e00d9550c16c9822366b4a";

  DB_USERNAME = "postgres";
  DB_DATABASE_NAME = "immich";
in
delib.module {
  inherit name;

  options = delib.singleEnableOption (host.containersFeatured && host.nvidiaFeatured);

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
      redisRef = quadletCfg.containers.${redisName}.ref;
      mlRef = quadletCfg.containers.${mlName}.ref;
      modelCacheRef = quadletCfg.volumes.${modelCacheName}.ref;
    in
    {
      pods = {
        ${podName} = {
          serviceConfig.Restart = "on-failure";
          podConfig = {
            addHosts = [
              "immich-machine-learning:127.0.0.1"
              "redis:127.0.0.1"
              "database:127.0.0.1"
            ];
            networks = [ quadletCfg.networks.caddy-net.ref ];
          };
        };
      };
      containers = {
        ${serverName} = {
          unitConfig = rec {
            Requires = [
              mlRef
              redisRef
              dbRef
            ];
            After = Requires;
          };
          containerConfig = {
            pod = podRef;
            image = serverImage;
            volumes = [
              "${UPLOAD_LOCATION}:/data"
              "/etc/localtime:/etc/localtime:ro"
            ]
            ++ externalLibraryVolumes;
            environments = {
              inherit
                DB_USERNAME
                DB_DATABASE_NAME
                ;
              TZ = "Asia/Bangkok";
            };
            environmentFiles = [ serverSecretPath ];
            labels = {
              "caddy" = "${podName}.songpola.dev";
              "caddy.reverse_proxy" = "{{upstreams 2283}}";
            };

            # For Hardware Transcoding using NVENC
            devices = [ "nvidia.com/gpu=all" ];

            # # FIXME: Podman fails to recognize HEALTHCHECK in certain BuildKit images
            # # See:   https://github.com/containers/podman/issues/18904
            # notify = "healthy";
          };
        };
        ${mlName}.containerConfig = {
          pod = podRef;
          image = mlImage;
          volumes = [ "${modelCacheRef}:/cache" ];
          devices = [ "nvidia.com/gpu=all" ];
        };
        ${redisName}.containerConfig = {
          pod = podRef;
          image = redisImage;
          notify = "healthy";
          healthCmd = "redis-cli ping || exit 1";
        };
        ${dbName}.containerConfig = {
          pod = podRef;
          image = dbImage;
          volumes = [ "${DB_DATA_LOCATION}:/var/lib/postgresql/data" ];
          environments = {
            POSTGRES_USER = DB_USERNAME;
            POSTGRES_DB = DB_DATABASE_NAME;
            POSTGRES_INITDB_ARGS = "--data-checksums";
            # # NOTE: The DB_DATA_LOCATION is a ZFS dataset on a HDD,
            # # but with SSD-backed cache (via special_small_blocks).
            # # So the data will be stored on SSD in the end.
            # DB_STORAGE_TYPE = "HDD";
          };
          environmentFiles = [ dbSecretPath ];
          shmSize = "128mb";
          # # FIXME: Podman fails to recognize HEALTHCHECK in certain BuildKit images
          # # See:   https://github.com/containers/podman/issues/18904
          # notify = "healthy";
        };
      };
      volumes.${modelCacheName} = { };
    }
  );
}
