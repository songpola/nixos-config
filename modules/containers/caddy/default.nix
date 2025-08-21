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
  name = "caddy";
  volumeName = "${name}-data";
  networkName = "${name}-net";

  secretName = "containers/${name}/env";

  PORT_TCP_HTTP = "80";
  PORT_TCP_HTTPS = "443";
  PORT_UDP_HTTP3 = "443";
in
delib.module {
  inherit name;

  options = delib.singleEnableOption host.containersFeatured;

  myconfig.ifEnabled.secrets.enable = true;

  nixos.ifEnabled = {
    sops.secrets.${secretName}.owner = username;

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
      containers.${name} = {
        # No need to autostart/restart; will be socket-activated when needed
        autoStart = false;
        serviceConfig.Restart = "no";
        containerConfig = {
          image = "docker.io/homeall/caddy-reverse-proxy-cloudflare:2025.07.29";
          environments = {
            CADDY_INGRESS_NETWORKS = networkName;
            CADDY_DOCKER_CADDYFILE_PATH = "/config/Caddyfile";
            CADDY_DOCKER_NO_SCOPE = "true"; # For podman compatibility
            CADDY_HTTP3_FD = "3";
            CADDY_HTTP_FD = "4";
            CADDY_HTTPS_FD = "5";
          };
          environmentFiles = [ secrets.${secretName}.path ];
          volumes = [
            "%t/podman/podman.sock:/var/run/docker.sock"
            "${quadletCfg.volumes.${volumeName}.ref}:/data"
            "${./Caddyfile}:/config/Caddyfile:ro"
          ];
          networks = [ quadletCfg.networks.${networkName}.ref ];
          # The image don't have HEALTHCHECK
          # but caddy supports sd_notify
          notify = true;
        };
      };
      volumes.${volumeName} = { };
      networks.${networkName} = { };
    }))
    {
      # Use Caddy with socket-activation for native network performance
      # See:
      # - https://github.com/eriksjolund/podman-networking-docs#socket-activation-systemd-user-service
      # - https://github.com/eriksjolund/podman-caddy-socket-activation/tree/main/examples/example4
      systemd.user.sockets.${name} = {
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
    }
  ];
}
