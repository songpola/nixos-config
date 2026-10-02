# Starrs stack for media automation. Setup guide: ./starrs.md
# DISABLED: to enable, add `den.aspects."prts".starrs` to `den.aspects."prts".includes`.
{ den, lib, ... }:
let
  baseSiteAddress = "songpola.dev";
  baseConfigDir = "/tank/v2/starrs-stack";
  baseDataDir = "/tank/v2/starrs-data";
  torrentingPort = "6882";

  qbittorrentImage = "lscr.io/linuxserver/qbittorrent:version-5.1.4-r3";
  clonarrImage = "ghcr.io/prophetse7en/clonarr:latest";
  prowlarrImage = "lscr.io/linuxserver/prowlarr:version-2.3.5.5327";
  byparrImage = "ghcr.io/thephaseless/byparr:latest";
  radarrImage = "lscr.io/linuxserver/radarr:version-6.1.1.10360";
  sonarrImage = "lscr.io/linuxserver/sonarr:version-4.0.17.2952";

  podName = "starrs";

  qbittorrentName = "${podName}-qbittorrent";
  clonarrName = "${podName}-clonarr";
  byparrName = "${podName}-byparr";
  prowlarrName = "${podName}-prowlarr";
  radarrName = "${podName}-radarr";
  radarrAnimeName = "${radarrName}-anime";
  sonarrName = "${podName}-sonarr";
  sonarrAnimeName = "${sonarrName}-anime";

  # Internal to containers, rarely change.
  # This will be the same across all Starrs containers,
  # to enable the "Atomic Move" technique (hardlinking instead of copying files).
  containerBaseDataDir = "/mnt/starrs-data";
  containerTorrentsDataDir = "${containerBaseDataDir}/torrents";

  dataVolumeMount = "${baseDataDir}:${containerBaseDataDir}";
  torrentsDataVolumeMount = "${baseDataDir}/torrents:${containerTorrentsDataDir}";

  commonEnvs = {
    TZ = "Asia/Bangkok";
    PUID = "1000";
    PGID = "1000";
  };

  # caddy-docker-proxy labels for multiple sites on the pod
  mkCaddyLabels =
    services:
    services
    |> builtins.attrNames
    |> lib.imap1 (
      i: serviceName: [
        {
          name = "caddy_${toString i}";
          value = "${serviceName}.${baseSiteAddress}";
        }
        {
          name = "caddy_${toString i}.reverse_proxy";
          value = "{{upstreams ${toString services.${serviceName}}}}";
        }
      ]
    )
    |> lib.concatLists
    |> lib.listToAttrs;
in
{
  den.aspects."prts" = {
    _.starrs.nixos =
      { config, ... }:
      let
        inherit (config.virtualisation.quadlet) networks pods;
        podRef = pods.${podName}.ref;
      in
      {
        virtualisation.quadlet = {
          # For starrs-qbittorrent <-> qui integration
          containers."qui".containerConfig.volumes = [ torrentsDataVolumeMount ];

          pods.${podName}.podConfig = {
            publishPorts = [
              # starrs-qbittorrent
              "${torrentingPort}:${torrentingPort}"
              "${torrentingPort}:${torrentingPort}/udp"
            ];
            networks = [
              networks."caddy-reverse-proxy-ingress".ref
              "${networks."qui".ref}:alias=${podName}" # for qui integration
            ];
            labels = mkCaddyLabels {
              ${qbittorrentName} = 8080;
              ${clonarrName} = 6060;
              ${prowlarrName} = 9696;
              ${radarrName} = 7878;
              ${radarrAnimeName} = 7879;
              ${sonarrName} = 8989;
              ${sonarrAnimeName} = 8990;
            };
            # starrs-prowlarr: a little hack for bypassing Cloudflare
            addHosts = [
              "bearbit.org:128.1.35.170"
              "www.bearbit.org:128.1.35.170"
            ];
          };

          # Downloader: qBittorrent (will be used by Radarr/Sonarr)
          #
          # IMPORTANT: See "qBittorrent - Basic Setup (TRaSH Guides)" in ./starrs.md
          containers.${qbittorrentName}.containerConfig = {
            pod = podRef;
            image = qbittorrentImage;
            environments = commonEnvs // {
              TORRENTING_PORT = torrentingPort;
            };
            volumes = [
              "${baseConfigDir}/${qbittorrentName}/config:/config"
              torrentsDataVolumeMount
            ];
            memory = "2G"; # explicitly limit to 2GB of RAM
          };

          # Guide Sync (configuration management)
          containers.${clonarrName}.containerConfig = {
            pod = podRef;
            image = clonarrImage;
            environments = commonEnvs;
            volumes = [
              "${baseConfigDir}/${clonarrName}/config:/config"
            ];
          };

          # Indexer Proxies (for bypassing Cloudflare blocks on indexers)
          containers.${byparrName}.containerConfig = {
            pod = podRef;
            image = byparrImage;
          };

          # Indexer
          containers.${prowlarrName}.containerConfig = {
            pod = podRef;
            image = prowlarrImage;
            environments = commonEnvs;
            volumes = [
              "${baseConfigDir}/${prowlarrName}/config:/config"
            ];
          };

          # Movies (Main)
          containers.${radarrName}.containerConfig = {
            pod = podRef;
            image = radarrImage;
            environments = commonEnvs // {
              RADARR__SERVER__PORT = "7878"; # Radarr default
            };
            volumes = [
              "${baseConfigDir}/${radarrName}/config:/config"
              dataVolumeMount
            ];
          };

          # Movies (Anime)
          containers.${radarrAnimeName}.containerConfig = {
            pod = podRef;
            image = radarrImage;
            environments = commonEnvs // {
              RADARR__SERVER__PORT = "7879"; # Radarr default + 1
            };
            volumes = [
              "${baseConfigDir}/${radarrAnimeName}/config:/config"
              dataVolumeMount
            ];
          };

          # TV Series (Main)
          containers.${sonarrName}.containerConfig = {
            pod = podRef;
            image = sonarrImage;
            environments = commonEnvs // {
              SONARR__SERVER__PORT = "8989"; # Sonarr default
            };
            volumes = [
              "${baseConfigDir}/${sonarrName}/config:/config"
              dataVolumeMount
            ];
          };

          # TV Series (Anime)
          containers.${sonarrAnimeName}.containerConfig = {
            pod = podRef;
            image = sonarrImage;
            environments = commonEnvs // {
              SONARR__SERVER__PORT = "8990"; # Sonarr default + 1
            };
            volumes = [
              "${baseConfigDir}/${sonarrAnimeName}/config:/config"
              dataVolumeMount
            ];
          };
        };
      };
  };
}
