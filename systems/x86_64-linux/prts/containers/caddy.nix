{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib,
  # An instance of `pkgs` with your overlays and packages applied is also available.
  # pkgs,
  # You also have access to your flake's inputs.
  # inputs,
  # Additional metadata is provided by Snowfall Lib.
  namespace, # The namespace used for your flake, defaulting to "internal" if not set.
  # system, # The system architecture for this host (eg. `x86_64-linux`).
  # target, # The Snowfall Lib target for this system (eg. `x86_64-iso`).
  # format, # A normalized name for the system target (eg. `iso`).
  # virtual, # A boolean to determine whether this system is a virtual target using nixos-generators.
  # systems, # An attribute map of your defined hosts.
  # All other arguments come from the system system.
  config,
  utils,
  ...
}: let
  inherit (lib.${namespace}) mkHomeConfig getHomeConfig;
  homeCfg = getHomeConfig config;
  cfg = homeCfg.virtualisation.quadlet;
in
  {
    sops = {
      secrets."containers/caddy" = {
        owner = namespace;
      };
    };
  }
  // mkHomeConfig {
    systemd.user = {
      sockets = {
        caddy = {
          Socket = {
            BindIPv6Only = "both";
            # These are the actual order of the socket units
            ListenDatagram = "[::]:443"; # fdgram/3 - HTTP3
            ListenStream = [
              "[::]:80" # fd/4 - HTTP
              "[::]:443" # fd/5 - HTTPS
              # "%t/caddy.sock" # # fd/6 - Caddy admin API
            ];
            SocketMode = 0600;
          };
          Install = {
            WantedBy = ["sockets.target"];
          };
        };
      };
    };
    virtualisation.quadlet = {
      networks = {
        caddy-net = {};
      };
      volumes = {
        caddy-data = {};
      };
      containers = {
        caddy = {
          serviceConfig = {
            Restart = "no"; # override default; no need to restart socket-activated service
          };
          containerConfig = {
            image = "docker.io/homeall/caddy-reverse-proxy-cloudflare:2025.04.29";
            environments = {
              TZ = "Asia/Bangkok";
              CADDY_DOCKER_NO_SCOPE = "true"; # for podman compatibility
            };
            environmentFiles = [
              config.sops.secrets."containers/caddy".path
            ];
            labels = lib.dropEnd 1 (lib.splitString "\n" ''
              caddy.email=ice.songpola@pm.me
              caddy.acme_dns=cloudflare {env.CLOUDFLARE_API_TOKEN}
              caddy_1=syncthing.songpola.dev
              caddy_1.reverse_proxy=host.containers.internal:8384
            '');
            volumes = [
              "%t/podman/podman.sock:/var/run/docker.sock"
              "${cfg.volumes.caddy-data.ref}:/data"
            ];
            networks = [cfg.networks.caddy-net.ref];
            notify = true; # caddy supports sd_notify
          };
        };
      };
    };
  }
