{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkMerge;
  inherit (lib.${namespace}) mkRootlessQuadletModule;
in
mkMerge [
  (mkRootlessQuadletModule config { } (quadletCfg: {
    containers = {
      adguardhome = {
        serviceConfig.Restart = "on-failure";
        containerConfig = {
          image = "docker.io/adguard/adguardhome:v0.107.64";
          volumes = [
            "/tank/songpola/adguardhome/conf:/opt/adguardhome/conf" # app configuration
            "/tank/songpola/adguardhome/work:/opt/adguardhome/work" # app working directory
          ];
          # NOTE: Need to use pasta without custom network to preserved source address.
          # See: https://github.com/eriksjolund/podman-networking-docs#source-address-preserved
          publishPorts = [
            "53:53/udp" # DNS
            "5380:80" # Web UI
          ];
          labels = {
            "caddy" = "adguardhome.songpola.dev";
            # Without custom network, caddy need to access AdGuard Home via host network through
            # "host.containers.internal" address and published port.
            "caddy.reverse_proxy" = "host.containers.internal:5380";
          };
        };
      };
    };
  }))
  {
    services.resolved = {
      llmnr = "false"; # no need for LLMNR
      # Free up port 53 for AdGuard Home
      extraConfig = ''
        DNSStubListener=no
      '';
    };

    networking = {
      nameservers = [ "127.0.0.1" ]; # Use AdGuard Home as DNS server
      firewall.allowedUDPPorts = [ 53 ];
    };
  }
]
