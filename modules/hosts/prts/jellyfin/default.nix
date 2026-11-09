# Jellyfin for media streaming (with NVIDIA GPU), as quadlets (`quadlet-jellyfin*.service`).
#
# Plus a private Jikan (MyAnimeList API) for the MyAnimeList plugin. The public Jikan API
# shut down on 2026-10-01 (jikan-me/jikan-rest#613), and the plugin version that loads on
# 10.11.8 (6.6.5.1) hardcodes its endpoints: primary http://jikanapi.freemyip.com:8080/v4/
# (the plugin author's instance, also gone), backup https://api.jikan.moe/v4/. A timed-out
# Jikan call aborts the whole series refresh, so new episodes never appeared. The jikan
# container takes over the primary's name as a network alias (plain HTTP, so no certificate
# needed), and api.jikan.moe maps to 127.0.0.1 so the fallback fails at once instead of
# hanging. Drop all of this for the plugin's Jikan URL setting (6.6.5.5+) once Jellyfin is
# on 10.11.11+.
#
# Keys in ../secrets/jellyfin.secrets.yaml (`just sops-edit`): jikan/APP_KEY
# (`"base64:" + (random binary 32 | encode base64)` in nushell) and jikan/TYPESENSE_API_KEY
# (`random chars --length 32`). Search only covers anime already in Jikan's database: on an
# empty database, fill it once with `podman exec -d jikan php artisan indexer:anime --delay=3`
# (30k entries, about two days; resume an interrupted run with --resume). New seasons are
# then indexed daily by Jikan's own scheduler, and lookups by MAL ID scrape MAL on demand.
{ den, lib, ... }:
let
  # The arrs' media, at the same container path as in ./../arrs (its `dataDir`/media), so the
  # paths the arrs report match Jellyfin's libraries; fixed, because Jellyfin stores it per
  # library and item (watch state is keyed by path)
  mediaVolume = "/tank/v2/arrs-data/media:/mnt/starrs-data/media";

  sopsFile = ../secrets/jellyfin.secrets.yaml;
  appKey = "jikan/APP_KEY";
  typesenseKey = "jikan/TYPESENSE_API_KEY";
in
{
  den.aspects."prts" = {
    includes = with den.aspects; [
      programs.quadlet
      programs.sops
      services.caddy-reverse-proxy
    ];

    nixos =
      { config, host, ... }:
      let
        quadlet = config.virtualisation.quadlet;
        caddy = host.settings.services.caddy-reverse-proxy;
        autoUpdateLabels = den.aspects.programs.podman.meta.autoUpdateLabels;
        # Dozzle groups by compose project, which quadlets lack
        groupLabel."dev.dozzle.group" = "jellyfin";
        placeholder = config.sops.placeholder;
      in
      {
        sops.secrets = {
          ${appKey} = {
            inherit sopsFile;
          };
          ${typesenseKey} = {
            inherit sopsFile;
          };
        };
        sops.templates = {
          "jikan.env" = {
            content = ''
              APP_KEY=${placeholder.${appKey}}
              TYPESENSE_API_KEY=${placeholder.${typesenseKey}}
            '';
            restartUnits = [ "quadlet-jellyfin-jikan.service" ];
          };
          "jikan-typesense.env" = {
            content = ''
              TYPESENSE_API_KEY=${placeholder.${typesenseKey}}
            '';
            restartUnits = [ "quadlet-jellyfin-jikan-typesense.service" ];
          };
        };

        virtualisation.quadlet.networks = {
          # Jellyfin, Jikan and its databases; no internet
          quadlet-jellyfin-jikan.networkConfig = {
            name = "jikan";
            internal = true;
          };
          # Internet access for Jikan, to scrape MyAnimeList
          quadlet-jellyfin-jikan-egress.networkConfig.name = "jikan-egress";
        };

        virtualisation.quadlet.containers = {
          quadlet-jellyfin.containerConfig = {
            name = "jellyfin";
            image = "lscr.io/linuxserver/jellyfin:version-10.11.8ubu2404";
            environments = {
              TZ = "Asia/Bangkok";
              # songpola:users on the host
              PUID = "1000";
              PGID = "100";
            };
            volumes = [
              "/tank/v2/services/jellyfin/config:/config"
              mediaVolume
            ];
            # NVIDIA GPU via CDI (hardware.nvidia-container-toolkit)
            devices = [ "nvidia.com/gpu=all" ];
            addHosts = [
              # The LDAP plugin talks LDAPS to Kanidm on the host (port 636). On the caddy
              # network this domain resolves to Caddy (a network alias), which doesn't carry
              # LDAP; mapping it to the host keeps certificate verification on the real name
              "idm.songpola.dev:host-gateway"
              # The MyAnimeList plugin's backup Jikan, dead: refuse it at once (see the top)
              "api.jikan.moe:127.0.0.1"
            ];
            networks = [
              quadlet.networks."quadlet-${caddy.network}".ref
              quadlet.networks.quadlet-jellyfin-jikan.ref
            ];
            labels =
              autoUpdateLabels
              // groupLabel
              // {
                "caddy" = "jf.songpola.dev";
                "caddy.reverse_proxy" = "{{upstreams 8096}}";
                "dev.dozzle.url" = "https://jf.songpola.dev";
              };
          };

          # Jikan REST API, the plugin author's fork (maintained; the official image dates
          # from 2024). Only `latest` is published, so it's pinned by digest (and left out of
          # auto-update, which needs a tag).
          quadlet-jellyfin-jikan.containerConfig = {
            name = "jikan";
            image = "ghcr.io/ryandash/jikan-rest:latest@sha256:0405dd4a388a2c0c632bb344a8a59491f5ad1445f68e3c36950762fb50abc472";
            environments = {
              # Its own address; the indexers fetch through it (the default lacks the port)
              APP_URL = "http://localhost:8080";
              DB_HOST = "jikan-mongodb";
              # Search needs Typesense: the fork's MongoDB-only mode ("none") fails every write
              SCOUT_DRIVER = "typesense";
              TYPESENSE_HOST = "jikan-typesense";
              TYPESENSE_PORT = "8108";
              GITHUB_REPORTING = "false";
            };
            environmentFiles = [ config.sops.templates."jikan.env".path ];
            labels = groupLabel;
            networks = [
              # Jellyfin reaches it here as the plugin's hardcoded primary (port 8080)
              "${quadlet.networks.quadlet-jellyfin-jikan.ref}:alias=jikanapi.freemyip.com"
              quadlet.networks.quadlet-jellyfin-jikan-egress.ref
            ];
          };

          # MongoDB without auth: reachable only on the internal jikan network, and holds
          # only scraped public data
          quadlet-jellyfin-jikan-mongodb.containerConfig = {
            name = "jikan-mongodb";
            image = "docker.io/library/mongo:8.0.34";
            exec = [
              "--wiredTigerCacheSizeGB"
              "1"
            ];
            # The compose stack's volume, kept by name
            volumes = [ "jellyfin_jikan-mongodb:/data/db" ];
            networks = [ quadlet.networks.quadlet-jellyfin-jikan.ref ];
            labels = autoUpdateLabels // groupLabel;
          };

          quadlet-jellyfin-jikan-typesense.containerConfig = {
            name = "jikan-typesense";
            image = "docker.io/typesense/typesense:30.2";
            environments.TYPESENSE_DATA_DIR = "/data";
            environmentFiles = [ config.sops.templates."jikan-typesense.env".path ];
            volumes = [ "jellyfin_jikan-typesense:/data" ];
            networks = [ quadlet.networks.quadlet-jellyfin-jikan.ref ];
            labels = autoUpdateLabels // groupLabel;
          };
        };

        # Compose's depends_on
        systemd.services.quadlet-jellyfin-jikan = rec {
          requires = [
            "quadlet-jellyfin-jikan-mongodb.service"
            "quadlet-jellyfin-jikan-typesense.service"
          ];
          after = requires;
        };
      };
  };
}
