# Caddy as reverse proxy for web services, configured from container labels (caddy-docker-proxy).
# Certificates via ACME DNS-01 with Cloudflare, from the `security.acme-cloudflare` account.
# Includes the `programs.podman` and `security.acme-cloudflare` aspects it needs.
#
# Containers opt in by joining the ingress network (settings.network), e.g. in a compose stack:
#   networks: [ caddy ]   (external: true)
#   labels:
#     caddy: app.example.com
#     caddy.reverse_proxy: "{{upstreams 8080}}"
#
# Other aspects extend it through quirks (data, collected from every aspect on the host):
#   caddy-sites    sites for upstreams outside the network, e.g. native services (see services.kanidm)
#   caddy-snippets Caddyfile text after the global options, e.g. snippets for labels to `import`
{ den, lib, ... }:
let
  name = "caddy-reverse-proxy";
  unit = "podman-${name}.service";
in
{
  den.quirks.caddy-sites.description = ''
    Sites served by services.caddy-reverse-proxy, as `{ domain, upstream, reverseProxy ? { } }`;
    `reverseProxy` holds `reverse_proxy` subdirectives as label suffixes (e.g. `transport = "http"`).
    Each domain is also a network alias of the proxy, so containers on its network reach the
    site through the proxy directly, instead of looping out via the host's address.
  '';
  den.quirks.caddy-snippets.description = "Caddyfile text for services.caddy-reverse-proxy, appended after the global options";

  den.aspects.services.${name} = {
    includes = [
      den.aspects.programs.podman
      den.aspects.security.acme-cloudflare
    ];

    settings = {
      network = lib.mkOption {
        type = lib.types.str;
        default = "caddy";
        description = "Podman network shared with the proxied containers (created if missing)";
      };
      configDir = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/${name}/config";
        description = "Host directory for Caddy's /config (autosaved config)";
      };
      dataVolume = lib.mkOption {
        type = lib.types.str;
        default = "${name}-data";
        description = "Podman volume for Caddy's /data (certificates)";
      };
      image = lib.mkOption {
        type = lib.types.str;
        default = "docker.io/homeall/caddy-reverse-proxy-cloudflare:latest";
        description = "caddy-docker-proxy image with the Cloudflare DNS module";
      };
      extraGlobalConfig = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = "Extra lines for the Caddyfile's global options block";
      };
    };

    nixos =
      {
        config,
        pkgs,
        host,
        caddy-sites,
        caddy-snippets,
        ...
      }:
      let
        cfg = host.settings.services.${name};
        acme = config.security.acme.defaults;

        tokenSecret = den.aspects.security.acme-cloudflare.meta.tokenSecret;
        tokenPath = acme.credentialFiles.CLOUDFLARE_DNS_API_TOKEN_FILE;

        caddyfile = pkgs.writeText "Caddyfile" ''
          {
            email ${acme.email}
            acme_dns cloudflare {file.${tokenPath}}
            ${cfg.extraGlobalConfig}
          }

          ${lib.concatStringsSep "\n\n" caddy-snippets}
        '';

        # Sorted, so the indexed label prefixes (caddy_0, caddy_1, ...) stay stable
        sites = lib.sort (a: b: a.domain < b.domain) caddy-sites;
        siteLabels = lib.mergeAttrsList (
          lib.imap0 (
            i: site:
            let
              prefix = "caddy_${toString i}";
            in
            {
              ${prefix} = site.domain;
              "${prefix}.reverse_proxy" = site.upstream;
            }
            // lib.mapAttrs' (k: lib.nameValuePair "${prefix}.reverse_proxy.${k}") (site.reverseProxy or { })
          ) sites
        );
        aliases = map (site: site.domain) sites;
      in
      {
        sops.secrets.${tokenSecret}.restartUnits = [ unit ];

        systemd.tmpfiles.rules = [ "d ${cfg.configDir} 0755 root root -" ];

        # oci-containers doesn't manage networks; create the shared one if it's missing
        systemd.services."podman-network-${cfg.network}" = {
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          path = [ config.virtualisation.podman.package ];
          script = "podman network exists ${cfg.network} || podman network create ${cfg.network}";
          requiredBy = [ unit ];
          before = [ unit ];
        };

        virtualisation.oci-containers.containers.${name} = {
          inherit (cfg) image;
          ports = [
            "80:80" # HTTP
            "443:443" # HTTPS
            "443:443/udp" # HTTP3
          ];
          networks = [
            (
              cfg.network
              + lib.optionalString (aliases != [ ]) (
                ":" + lib.concatMapStringsSep "," (alias: "alias=${alias}") aliases
              )
            )
          ];
          # caddy-docker-proxy also reads the proxy's own labels
          labels =
            den.aspects.programs.podman.meta.autoUpdateLabels
            // siteLabels
            // {
              # Dozzle's bundled icon, which it doesn't match to this image on its own
              "dev.dozzle.icon" = "caddy";
            };
          # The image has no HEALTHCHECK, but Caddy speaks sd_notify: the unit is ready only once
          # Caddy has loaded its config, so an auto-update to a Caddy that can't is rolled back.
          podman.sdnotify = "container";
          environment = {
            CADDY_INGRESS_NETWORKS = cfg.network;
            CADDY_DOCKER_NO_SCOPE = "true"; # for podman compatibility
            # Ref: https://github.com/lucaslorentz/caddy-docker-proxy/blob/master/tests/caddyfile%2Bconfig/compose.yaml
            CADDY_DOCKER_CADDYFILE_PATH = "/config/Caddyfile";
          };
          volumes = [
            "/run/podman/podman.sock:/var/run/docker.sock"
            "${cfg.configDir}:/config"
            "${cfg.dataVolume}:/data"
            "${caddyfile}:/config/Caddyfile:ro"
            "${tokenPath}:${tokenPath}:ro"
          ];
        };
      };
  };
}
