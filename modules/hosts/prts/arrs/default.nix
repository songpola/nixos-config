# arrs for media automation, as quadlets. Setup guide: ./arrs.md
#
# Every app is its own container (unit `quadlet-<container>.service`) on the `arrs` network and
# reaches the others by its old compose service name (prowlarr:9696, qbittorrent:8080, ...),
# a network alias there: the apps store those links. Apps with a web UI also join Caddy's
# network, each with its own labels, behind the Kanidm gate (oauth2-proxy's `auth` snippet),
# so the apps' own logins are off where they allow it (Servarr apps: External; qui: auth
# disabled for the Caddy subnet; qBittorrent: the Caddy subnet skips its login, set in its
# UI as no env var exists). The apps reach each other on `arrs`, never through Caddy, and log
# in to qBittorrent with its password. Servarr APIs still require the API key.
#
# Container paths are fixed. The apps store them in their databases (root folders, every
# series and movie path, qBittorrent's save path, Jellyfin's libraries), so /mnt/starrs-data
# keeps its old name. It is the same in every container (and in Jellyfin) to enable the
# "Atomic Move" technique (hardlinking instead of copying files).
{ den, lib, ... }:
let
  # Host paths: the media library and torrents (one filesystem, for hardlinks), and one
  # <app>/config directory per app. Change these to move the data.
  dataDir = "/tank/v2/arrs-data";
  configDir = "/tank/v2/services/arrs";
  containerDataDir = "/mnt/starrs-data";

  domain = "songpola.dev";
  authGroup = "prts_admins@idm.songpola.dev";

  commonEnv = {
    TZ = "Asia/Bangkok";
    # songpola:users on the host
    PUID = "1000";
    PGID = "100";
  };

  escape = den.aspects.programs.quadlet.meta.escapeSpecifiers;
  readIcon = file: escape (lib.removeSuffix "\n" (builtins.readFile file));

  configVolume = app: "${configDir}/${app}/config:/config";
  dataVolume = "${dataDir}:${containerDataDir}";
  torrentsVolume = "${dataDir}/torrents:${containerDataDir}/torrents";
in
{
  den.aspects."prts" = {
    includes = with den.aspects; [
      programs.quadlet
      services.caddy-reverse-proxy
      services.oauth2-proxy
    ];

    nixos =
      { config, host, ... }:
      let
        quadlet = config.virtualisation.quadlet;
        caddy = host.settings.services.caddy-reverse-proxy;

        # One app: `service` is its alias on the arrs network; `web` exposes it through Caddy
        # at <subdomain>.songpola.dev, behind the gate.
        mkApp =
          {
            service,
            container ? "arrs-${service}",
            image,
            web ? null,
            containerConfig ? { },
          }:
          lib.nameValuePair "quadlet-${container}" {
            containerConfig = lib.mkMerge [
              {
                name = container;
                inherit image;
                networks = [
                  "${quadlet.networks.quadlet-arrs.ref}:alias=${service}"
                ]
                ++ lib.optional (web != null) quadlet.networks."quadlet-${caddy.network}".ref;
                labels = den.aspects.programs.podman.meta.autoUpdateLabels;
              }
              (lib.mkIf (web != null) (
                let
                  site = "${web.subdomain or service}.${domain}";
                in
                {
                  labels = {
                    "caddy" = site;
                    "caddy.reverse_proxy" = "{{upstreams ${toString web.port}}}";
                    "caddy.import" = "auth ${authGroup}";
                    "dev.dozzle.url" = "https://${site}";
                  }
                  // lib.optionalAttrs (web ? icon) { "dev.dozzle.icon" = web.icon; };
                }
              ))
              containerConfig
            ];
          };

        # Radarr and Sonarr instances: the anime ones run on default port + 1, only because
        # Prowlarr and Clonarr store it (it dates from a shared network namespace).
        mkServarr =
          {
            service,
            app,
            image,
            port,
          }:
          mkApp {
            inherit service image;
            web.port = port;
            containerConfig = {
              environments = commonEnv // {
                "${app}__SERVER__PORT" = toString port;
                "${app}__AUTH__METHOD" = "External";
              };
              volumes = [
                (configVolume service)
                dataVolume
              ];
            };
          };
      in
      {
        virtualisation.quadlet.networks.quadlet-arrs.networkConfig.name = "arrs";

        virtualisation.quadlet.containers = lib.listToAttrs [
          # Downloader. IMPORTANT: see "qBittorrent - Basic Setup (TRaSH Guides)" in ./arrs.md
          (mkApp {
            service = "qbittorrent";
            image = "lscr.io/linuxserver/qbittorrent:latest";
            web = {
              port = 8080;
              subdomain = "qbit";
            };
            containerConfig = {
              environments = commonEnv // {
                TORRENTING_PORT = "6882";
              };
              publishPorts = [
                "6882:6882"
                "6882:6882/udp"
              ];
              volumes = [
                (configVolume "qbittorrent")
                torrentsVolume
              ];
              memory = "2g";
            };
          })

          # Guide sync (configuration management). selfh.st icon (CC BY 4.0,
          # https://selfh.st/icons), 64x64 WebP to fit Dozzle's 16 KB limit; Dozzle bundles none
          (mkApp {
            service = "clonarr";
            image = "ghcr.io/prophetse7en/clonarr:latest";
            web = {
              port = 6060;
              icon = readIcon ./icons/clonarr.txt;
            };
            containerConfig = {
              environments = commonEnv;
              volumes = [ (configVolume "clonarr") ];
            };
          })

          # Proxy for indexers behind Cloudflare challenges; only Prowlarr uses it
          (mkApp {
            service = "byparr";
            image = "ghcr.io/thephaseless/byparr:latest";
          })

          # Indexers, with two custom definitions (see the files)
          (mkApp {
            service = "prowlarr";
            image = "lscr.io/linuxserver/prowlarr:latest";
            web.port = 9696;
            containerConfig = {
              environments = commonEnv // {
                PROWLARR__AUTH__METHOD = "External";
              };
              volumes = [
                (configVolume "prowlarr")
                # BearBIT with its download ad gate handled
                "${./prowlarr-bearbit.yml}:/config/Definitions/Custom/bearbit.yml:ro"
                # SeFree with its 90XX anime categories mapped to standard ones
                "${./prowlarr-sefree.yml}:/config/Definitions/Custom/sefree.yml:ro"
              ];
            };
          })

          (mkServarr {
            service = "radarr";
            app = "RADARR";
            image = "lscr.io/linuxserver/radarr:latest";
            port = 7878;
          })
          (mkServarr {
            service = "radarr-anime";
            app = "RADARR";
            image = "lscr.io/linuxserver/radarr:latest";
            port = 7879;
          })
          (mkServarr {
            service = "sonarr";
            app = "SONARR";
            image = "lscr.io/linuxserver/sonarr:latest";
            port = 8989;
          })
          (mkServarr {
            service = "sonarr-anime";
            app = "SONARR";
            image = "lscr.io/linuxserver/sonarr:latest";
            port = 8990;
          })

          # qui for managing qBittorrent and searching through Prowlarr
          # (https://getqui.com/docs/getting-started/docker#local-filesystem-access). Its own
          # login is off: the gate handles it, and qui only accepts requests from Caddy's
          # subnet (refuses everything else) for its own domain. selfh.st icon (CC BY 4.0).
          (mkApp {
            service = "qui";
            container = "qui";
            image = "ghcr.io/hotio/qui:latest";
            web = {
              port = 7476;
              icon = readIcon ./icons/qui.txt;
            };
            containerConfig = {
              environments = commonEnv // {
                QUI__AUTH_DISABLED = "true";
                QUI__I_ACKNOWLEDGE_THIS_IS_A_BAD_IDEA = "true";
                QUI__AUTH_DISABLED_ALLOWED_CIDRS = caddy.subnet;
                QUI__ALLOWED_HOSTS = "qui.${domain}";
              };
              volumes = [
                (configVolume "qui")
                torrentsVolume
              ];
            };
          })
        ];
      };
  };
}
