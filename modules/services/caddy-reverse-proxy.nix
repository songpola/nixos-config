# Caddy as reverse proxy for web services, configured from container labels (caddy-docker-proxy).
# Certificates via ACME DNS-01 with Cloudflare; the API token comes from sops.
# Includes the `programs.podman` and `programs.sops` aspects it needs.
#
# Containers opt in by joining the ingress network (settings.network), e.g. in a compose stack:
#   networks: [ caddy ]   (external: true)
#   labels:
#     caddy: app.example.com
#     caddy.reverse_proxy: "{{upstreams 8080}}"
{ den, lib, ... }:
let
  name = "caddy-reverse-proxy";
  unit = "podman-${name}.service";

  secret = "${name}/CLOUDFLARE_API_TOKEN";
in
{
  den.aspects.services.${name} = {
    includes = with den.aspects.programs; [
      podman
      sops
    ];

    settings = {
      email = lib.mkOption {
        type = lib.types.str;
        description = "ACME account email";
      };
      cloudflareApiTokenSopsFile = lib.mkOption {
        type = lib.types.path;
        description = "sops file with the Cloudflare API token at `${secret}`";
      };
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
        ...
      }:
      let
        cfg = host.settings.services.${name};

        secretPath = config.sops.secrets.${secret}.path;

        caddyfile = pkgs.writeText "Caddyfile" ''
          {
            email ${cfg.email}
            acme_dns cloudflare {file.${secretPath}}
            ${cfg.extraGlobalConfig}
          }
        '';
      in
      {
        sops.secrets.${secret} = {
          sopsFile = cfg.cloudflareApiTokenSopsFile;
          restartUnits = [ unit ];
        };

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
          networks = [ cfg.network ];
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
            "${secretPath}:${secretPath}:ro"
          ];
        };
      };
  };
}
