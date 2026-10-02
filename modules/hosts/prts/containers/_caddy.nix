# Exposes a quadlet container through ./caddy-reverse-proxy.nix (caddy-docker-proxy labels).
# Usage: containerConfig = lib.mkMerge [ { ... } (caddy config { address = "..."; port = 8080; }) ];
config:
{ address, port }:
{
  networks = [ config.virtualisation.quadlet.networks."caddy-reverse-proxy-ingress".ref ];
  labels = {
    "caddy" = address;
    "caddy.reverse_proxy" = "{{upstreams ${toString port}}}";
  };
}
