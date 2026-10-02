# Caddy as reverse proxy for web services (see ./_caddy.nix)
# DISABLED: to enable, add `den.aspects."prts".caddy-reverse-proxy` to `den.aspects."prts".includes`.
{ den, ... }:
let
  ingressNetwork = "caddy-reverse-proxy-ingress";
  dataVolume = "caddy-reverse-proxy-data";
  configDir = "/tank/v2/services/caddy-reverse-proxy/config";
in
{
  den.aspects."prts" = {
    _.caddy-reverse-proxy.nixos =
      { config, pkgs, ... }:
      let
        inherit (config.virtualisation.quadlet) networks volumes;
        inherit (config.sops) secrets;

        secret = "caddy-reverse-proxy/CLOUDFLARE_API_TOKEN";
        secretPath = secrets.${secret}.path;

        caddyfile = pkgs.writeText "Caddyfile" ''
          {
            email songpola@songpola.dev
            acme_dns cloudflare {file.${secretPath}}
          }
        '';
      in
      {
        sops.secrets.${secret}.sopsFile = ./caddy-reverse-proxy.secrets.yaml;

        virtualisation.quadlet = {
          networks.${ingressNetwork} = { };
          volumes.${dataVolume} = { };
          containers."caddy-reverse-proxy".containerConfig = {
            image = "docker.io/homeall/caddy-reverse-proxy-cloudflare:latest";
            publishPorts = [
              "80:80" # HTTP
              "443:443" # HTTPS
              "443:443/udp" # HTTP3
            ];
            networks = [ networks.${ingressNetwork}.ref ];
            environments = {
              CADDY_INGRESS_NETWORKS = ingressNetwork;
              CADDY_DOCKER_NO_SCOPE = "true"; # for podman compatibility
              # Ref: https://github.com/lucaslorentz/caddy-docker-proxy/blob/master/tests/caddyfile%2Bconfig/compose.yaml
              CADDY_DOCKER_CADDYFILE_PATH = "/config/Caddyfile";
            };
            volumes = [
              "%t/podman/podman.sock:/var/run/docker.sock"
              "${configDir}:/config"
              "${volumes.${dataVolume}.ref}:/data"
              "${caddyfile}:/config/Caddyfile"
              "${secretPath}:${secretPath}"
            ];
            # The image don't have HEALTHCHECK
            # but caddy supports sd_notify
            notify = true;
          };
        };
      };
  };
}
