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
  inherit (lib.${namespace}) mkHomeConfig getHomeConfig mkLabels;
  homeCfg = getHomeConfig config;
  cfg = homeCfg.virtualisation.quadlet;
in
  mkHomeConfig {
    virtualisation.quadlet = {
      containers = {
        stirling-pdf = {
          containerConfig = {
            image = "docker.io/stirlingtools/stirling-pdf:0.45.6";
            environments = {
              TZ = "Asia/Bangkok";
              LANGS = "en_US"; # install fonts
            };
            volumes = [
              "/tank/songpola/stirling-pdf/logs:/logs"
              "/tank/songpola/stirling-pdf/extraConfigs:/configs"
              "/tank/songpola/stirling-pdf/pipeline:/pipeline"
              "/tank/songpola/stirling-pdf/customFiles:/customFiles"
              "/tank/songpola/stirling-pdf/trainingData:/usr/share/tessdata"
            ];
            networks = [
              cfg.networks.caddy-net.ref
            ];
            labels = mkLabels ''
              caddy=stirling-pdf.songpola.dev
              caddy.reverse_proxy={{upstreams 8080}}
            '';
          };
        };
      };
    };
  }
