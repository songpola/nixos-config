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
  nameDb = "${name}-db";

  secretServer = "containers/${nameServer}/env";
  secretDb = "containers/${nameDb}/env";

  PORT_TCP_GITEA_SSH = "2222";

  refPod = quadletCfg.pods.${name}.ref;
  refDb = quadletCfg.containers.${nameDb}.ref;
  refCaddyNet = quadletCfg.networks.caddy-net.ref;
in
delib.mkContainerModule {
  inherit name;

  extraNixosConfig = {
    networking.firewall.allowedTCPPorts = map lib.toInt [
      PORT_TCP_GITEA_SSH
    ];
  };

  rootlessSecrets = [
    secretServer
    secretDb
  ];

  rootlessQuadletConfig = {
    pods.${name}.podConfig = {
      networks = [ refCaddyNet ];
      publishPorts = [
        "${PORT_TCP_GITEA_SSH}:22"
      ];
    };

    containers.${nameServer} = {
      containerConfig = {
        pod = refPod;
        image = "docker.gitea.com/gitea:1.24.5";
        volumes = [
          "/tank/songpola/gitea/server-data:/data"
          "/etc/localtime:/etc/localtime:ro"
        ];
        environments = {
          GITEA__database__DB_TYPE = "postgres";
          GITEA__database__HOST = nameDb;
        };
        environmentFiles = [ secrets.${secretServer}.path ];
        labels = {
          "caddy" = "${name}.songpola.dev";
          "caddy.reverse_proxy" = "{{upstreams 3000}}";
        };
      };
      unitConfig = rec {
        Requires = [ refDb ];
        After = Requires;
      };
    };

    containers.${nameDb}.containerConfig = {
      pod = refPod;
      image = "docker.io/library/postgres:14";
      volumes = [ "/tank/songpola/db/gitea/db-data:/var/lib/postgresql/data" ];
      environmentFiles = [ secrets.${secretDb}.path ];
    };
  };
}
