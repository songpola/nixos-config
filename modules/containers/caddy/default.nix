{
  delib,
  homeconfig,
  secrets,
  username,
  lib,
  host,
  ...
}:
let
  secret = "containers/caddy/env";

  PORT_TCP_HTTP = "80";
  PORT_TCP_HTTPS = "443";
  PORT_UDP_HTTP3 = "443";
in
delib.module {
  name = "caddy";

  options = delib.singleEnableOption host.containersFeatured;

  myconfig.ifEnabled.secrets.enable = true;

  nixos.ifEnabled = {
    sops.secrets.${secret}.owner = username;

    networking.firewall = {
      allowedTCPPorts =
        [
          PORT_TCP_HTTP
          PORT_TCP_HTTPS
        ]
        |> map lib.toInt;
      allowedUDPPorts =
        [
          PORT_UDP_HTTP3
        ]
        |> map lib.toInt;
    };

    boot.kernel.sysctl = {
      "net.ipv4.ip_unprivileged_port_start" = 0; # Allow binding to ports < 1024
    };
  };

  home.ifEnabled = lib.mkMerge [
    (delib.rootlessQuadletModule homeconfig { } (quadletCfg: {
      autoEscape = true;
      containers = {
        caddy = {
          # No need to autostart/restart; will be socket-activated when needed
          autoStart = false;
          serviceConfig.Restart = "no";
          containerConfig = {
            image = "docker.io/homeall/caddy-reverse-proxy-cloudflare:2025.07.29";
            environments = {
              CADDY_DOCKER_CADDYFILE_PATH = "/config/Caddyfile";
              CADDY_DOCKER_NO_SCOPE = "true"; # For podman compatibility
              CADDY_HTTP3_FD = "3";
              CADDY_HTTP_FD = "4";
              CADDY_HTTPS_FD = "5";
            };
            environmentFiles = [ secrets.${secret}.path ];
            volumes = [
              "%t/podman/podman.sock:/var/run/docker.sock"
              "${quadletCfg.volumes.caddy-data.ref}:/data"
              "${./Caddyfile}:/config/Caddyfile:ro"
            ];
            networks = [ quadletCfg.networks.caddy-net.ref ];
            # The image don't have HEALTHCHECK
            # but caddy supports sd_notify
            notify = true;
          };
        };
      };
      volumes = {
        caddy-data = { };
      };
      networks = {
        caddy-net = { };
      };
    }))
    {
      # Use Caddy with socket-activation for native network performance
      # See:
      # - https://github.com/eriksjolund/podman-networking-docs#socket-activation-systemd-user-service
      # - https://github.com/eriksjolund/podman-caddy-socket-activation/tree/main/examples/example4
      systemd.user.sockets = {
        caddy = {
          Socket = {
            # These are the actual order of the socket units
            ListenDatagram = [
              "[::]:${PORT_UDP_HTTP3}" # fdgram/3
            ];
            ListenStream = [
              "[::]:${PORT_TCP_HTTP}" # fd/4
              "[::]:${PORT_TCP_HTTPS}" # fd/5
            ];
          };
          Install.WantedBy = [ "sockets.target" ];
        };
      };
    }
  ];
}
