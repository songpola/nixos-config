{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkMerge;
  inherit (lib.${namespace}) mkRootlessQuadletModule getConfigPath;

  coreSecret = "containers/firefly-iii/env";
  coreSecretPath = config.sops.secrets.${coreSecret}.path;

  dbSecret = "containers/firefly-iii-db/env";
  dbSecretPath = config.sops.secrets.${dbSecret}.path;
in
mkMerge [
  (mkRootlessQuadletModule config { } (quadletCfg: {
    pods = {
      firefly-iii = {
        serviceConfig.Restart = "on-failure";
        podConfig = {
          volumes = [
            "${quadletCfg.volumes.firefly-iii-core-upload.ref}:/var/www/html/storage/upload"
            "${quadletCfg.volumes.firefly-iii-db-data.ref}:/var/lib/mysql"
          ];
          networks = [ quadletCfg.networks.caddy-net.ref ];
        };
      };
    };
    containers = {
      firefly-iii-core = {
        unitConfig = {
          After = quadletCfg.containers.firefly-iii-db.ref;
          Requires = quadletCfg.containers.firefly-iii-db.ref;
        };
        containerConfig = {
          pod = quadletCfg.pods.firefly-iii.ref;
          image = "docker.io/fireflyiii/core:version-6.2.21";
          environmentFiles = [
            (getConfigPath "/firefly-iii/.env")
            coreSecretPath
          ];
          labels = {
            "caddy" = "firefly-iii.songpola.dev";
            "caddy.reverse_proxy" = "{{upstreams 8080}}";
          };
        };
      };
      firefly-iii-db = {
        containerConfig = {
          pod = quadletCfg.pods.firefly-iii.ref;
          image = "docker.io/mariadb:lts";
          environmentFiles = [
            (getConfigPath "/firefly-iii/.db.env")
            dbSecretPath
          ];
        };
      };
      # # TODO: setup cron job
      # # See: https://docs.firefly-iii.org/how-to/firefly-iii/advanced/cron/
      # firefly-iii-cron = {
      #   serviceConfig.Restart = "on-failure";
      #   containerConfig = {
      #     image = "docker.io/alpine:latest";
      #     environmentFiles = [
      #       (getConfigPath "/firefly-iii/.env")
      #       coreSecretPath
      #     ];
      #     exec =
      #       ''
      #         sh -c "
      #         apk add tzdata
      #         && ln -s /usr/share/zoneinfo/''${TZ} /etc/localtime
      #         | echo \"0 3 * * * wget -qO- http://app:8080/api/v1/cron/PLEASE_REPLACE_WITH_32_CHAR_CODE;echo\"
      #         | crontab -
      #         && crond -f -L /dev/stdout
      #         "
      #       ''
      #       |> lib.replaceString "\n" " ";
      #     networks = [ quadletCfg.networks.firefly-iii-net.ref ];
      #   };
      # };
    };
    volumes = {
      firefly-iii-core-upload = { };
      firefly-iii-db-data = { };
    };
  }))
  {
    ${namespace}.presets.secrets = true;

    sops.secrets = {
      ${coreSecret}.owner = namespace;
      ${dbSecret}.owner = namespace;
    };

    i18n.extraLocales = [ "th_TH.UTF-8/UTF-8" ];
  }
]
