{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkMerge;
  inherit (lib.${namespace}) mkRootlessQuadletModule mkHomeConfigModule getConfigPath;

  secret = "containers/caddy";
  secretPath = config.sops.secrets.${secret}.path;
in
mkMerge [
  (mkRootlessQuadletModule config { } (quadletCfg: {
    containers = {
      caddy = {
        # No need to autostart/restart; will be socket activated when needed
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
          environmentFiles = [ secretPath ];
          volumes = [
            "%t/podman/podman.sock:/var/run/docker.sock"
            "${quadletCfg.volumes.caddy-data.ref}:/data"
            "${getConfigPath "/caddy/Caddyfile"}:/config/Caddyfile:ro"
          ];
          networks = [ quadletCfg.networks.caddy-net.ref ];
          notify = true; # caddy supports sd_notify
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
    ${namespace}.presets.secrets = true;

    sops.secrets.${secret}.owner = namespace;

    networking.firewall = {
      allowedTCPPorts = [
        80 # HTTP
        443 # HTTPS
      ];
      allowedUDPPorts = [
        443 # HTTP3
      ];
    };

    boot.kernel.sysctl = {
      "net.ipv4.ip_unprivileged_port_start" = 0; # Allow binding to ports < 1024
    };
  }
  # Use Caddy with socket activation for native network performance
  # See:
  # - https://github.com/eriksjolund/podman-networking-docs#socket-activation-systemd-user-service
  # - https://github.com/eriksjolund/podman-caddy-socket-activation/tree/main/examples/example4
  (mkHomeConfigModule {
    systemd.user.sockets = {
      caddy = {
        Socket = {
          # These are the actual order of the socket units
          ListenDatagram = [
            "[::]:443" # fdgram/3 - HTTP3
          ];
          ListenStream = [
            "[::]:80" # fd/4 - HTTP
            "[::]:443" # fd/5 - HTTPS
          ];
        };
        Install.WantedBy = [ "sockets.target" ];
      };
    };
  })
]
