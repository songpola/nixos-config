{
  delib,
  homeconfig,
  host,
  lib,
  ...
}:
let
  # open firewall
  PORT_UDP_DNS = "53";
  PORT_TCP_DNS = "53";
  # local only
  PORT_TCP_DOH = "5380";
  # PORT_TCP_DOHS = "5443";
  # PORT_UDP_DOH3 = "5443";
  PORT_TCP_WEBUI = "8080";
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
      firewall.allowedUDPPorts =
        [
          PORT_UDP_DNS
          PORT_TCP_DNS
        ]
        |> map lib.toInt;
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
          "${PORT_TCP_DNS}:53" # DNS (TCP)
          "${PORT_UDP_DNS}:53/udp" # DNS (UDP)
          "${PORT_TCP_DOH}:80" # DNS-over-HTTP
          # "${PORT_TCP_DOHS}:443" # DNS-over-HTTPS
          # "${PORT_UDP_DOH3}:443/udp" # DNS-over-HTTP3
          "${PORT_TCP_WEBUI}:80" # Web UI
        ];
        labels = {
          # Without custom network, caddy need to access AdGuard Home via host network through
          # "host.containers.internal" address and published port.
          "caddy" = "${name}.songpola.dev";
          "caddy.handle_1" = "/dns-query*";
          "caddy.handle_1.reverse_proxy" = "host.containers.internal:${PORT_TCP_DOH}";
          "caddy.handle_2" = "/*";
          "caddy.handle_2.reverse_proxy" = "host.containers.internal:${PORT_TCP_WEBUI}";
        };
      };
    };
  };
}
