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
  ...
}: let
  inherit (lib) mkMerge;
  inherit (lib.${namespace}) mkHomeConfig getHomeConfig mkContainer;
  homeCfg = getHomeConfig config;
  cfg = homeCfg.virtualisation.quadlet;

  mkContainer' = mkContainer cfg;
in
  {
    sops.secrets."containers/caddy".owner = namespace;

    networking.firewall = {
      allowedTCPPorts = [
        80 # HTTP
        443 # HTTPS
      ];
      allowedUDPPorts = [
        443 # HTTP3
      ];
    };
  }
  // mkHomeConfig (mkMerge [
    (
      mkContainer' {
        name = "caddy";
        image = "docker.io/homeall/caddy-reverse-proxy-cloudflare:2025.04.29";
        useCaddyNet = true;
        mountPodmanSocket = true;
        autoStartOnBoot = false;
        socketActivated = true;
      } {
        containerConfig = {
          environments = {
            CADDY_DOCKER_CADDYFILE_PATH = "/config/Caddyfile";
            CADDY_DOCKER_NO_SCOPE = "true"; # for podman compatibility
            CADDY_HTTP3_FD = "3";
            CADDY_HTTP_FD = "4";
            CADDY_HTTPS_FD = "5";
          };
          environmentFiles = [
            config.sops.secrets."containers/caddy".path
          ];
          volumes = [
            "${cfg.volumes.caddy-data.ref}:/data"
            "%h/${homeCfg.xdg.configFile."caddy/Caddyfile".target}:/config/Caddyfile"
          ];
          notify = true; # caddy supports sd_notify
        };
      }
    )
    {
      virtualisation.quadlet = {
        networks = {
          caddy-net = {
            networkConfig.options = "mtu=65520";
          };
        };
        volumes = {
          caddy-data = {};
        };
      };

      xdg.configFile."caddy/Caddyfile".source = ./Caddyfile;

      systemd.user = {
        sockets = {
          caddy = {
            Socket = {
              BindIPv6Only = "both";
              # These are the actual order of the socket units
              ListenDatagram = [
                "[::]:443" # fdgram/3 - HTTP3
              ];
              ListenStream = [
                "[::]:80" # fd/4 - HTTP
                "[::]:443" # fd/5 - HTTPS
              ];
              SocketMode = 0600;
            };
            Install = {
              WantedBy = ["sockets.target"];
            };
          };
        };
      };
    }
  ])
