{
  delib,
  quadletCfg,
  secrets,
  lib,
  ...
}:
let
  name = "gitea";

  nameServer = "${name}-server";
  nameServerSecret = "containers/${nameServer}/env";

  nameDb = "${name}-db";
  nameDbSecret = "containers/${nameDb}/env";

  PORT_TCP_GITEA_WEB = "3000";
  PORT_TCP_GITEA_SSH = "2222";
in
delib.mkServiceModule rec {
  inherit name;

  nixos.networking.firewall.allowedTCPPorts = map lib.toInt [
    PORT_TCP_GITEA_WEB
    PORT_TCP_GITEA_SSH
  ];

  rootlessSecrets = [
    nameServerSecret
    nameDbSecret
  ];

  rootlessQuadletConfig = {
    pods.${name}.podConfig = {
      publishPorts = [
        "${PORT_TCP_GITEA_WEB}:3000"
        "${PORT_TCP_GITEA_SSH}:22"
      ];
    };
    containers.${nameServer} = {
      containerConfig = {
        pod = quadletCfg.pods.${name}.ref;
        image = "docker.gitea.com/gitea:1.24.5";
        volumes = [
          "/tank/songpola/gitea/server-data:/data"
          "/etc/localtime:/etc/localtime:ro"
        ];
        environments = {
          GITEA__database__DB_TYPE = "postgres";
          GITEA__database__HOST = nameDb;
        };
        environmentFiles = [ secrets.${nameServerSecret}.path ];
        labels = {
          "caddy" = "${name}.songpola.dev";
          "caddy.reverse_proxy" = "host.containers.internal:${PORT_TCP_GITEA_WEB}";
        };
      };
      unitConfig = rec {
        Requires = [ quadletCfg.containers.${nameDb}.ref ];
        After = Requires;
      };
    };
    containers.${nameDb}.containerConfig = {
      pod = quadletCfg.pods.${name}.ref;
      image = "docker.io/library/postgres:14";
      volumes = [ "/tank/songpola/db/gitea/db-data:/var/lib/postgresql/data" ];
      environmentFiles = [ secrets.${nameDbSecret}.path ];
    };
  };
}
