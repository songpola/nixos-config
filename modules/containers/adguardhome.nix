{
  delib,
  homeconfig,
  host,
  lib,
  ...
}:
let
  PORT_UDP_DNS = "53";
  PORT_TCP_WEBUI = "5380"; # local only
in
delib.module rec {
  name = "adguardhome";

  options = delib.singleEnableOption host.containersFeatured;

  nixos.ifEnabled = {
    services.resolved = {
      llmnr = "false"; # no need for LLMNR
      # Free up port 53 for AdGuard Home
      extraConfig = ''
        DNSStubListener=no
      '';
    };

    networking = {
      nameservers = [ "127.0.0.1" ]; # Use AdGuard Home as DNS server
      firewall.allowedUDPPorts = [ (lib.toInt PORT_UDP_DNS) ];
    };
  };

  home.ifEnabled = delib.rootlessQuadletModule homeconfig { } {
    containers.${name} = {
      serviceConfig.Restart = "on-failure";
      containerConfig = {
        image = "docker.io/adguard/adguardhome:v0.107.64";
        volumes = [
          "/tank/songpola/${name}/conf:/opt/adguardhome/conf" # app configuration
          "/tank/songpola/${name}/work:/opt/adguardhome/work" # app working directory
        ];
        # NOTE: Need to use pasta without custom network to preserved source address.
        # See: https://github.com/eriksjolund/podman-networking-docs#source-address-preserved
        publishPorts = [
          "${PORT_UDP_DNS}:53/udp" # DNS
          "${PORT_TCP_WEBUI}:80" # Web UI
        ];
        labels = {
          "caddy" = "${name}.songpola.dev";
          # Without custom network, caddy need to access AdGuard Home via host network through
          # "host.containers.internal" address and published port.
          "caddy.reverse_proxy" = "host.containers.internal:${PORT_TCP_WEBUI}";
        };
      };
    };
  };
}
