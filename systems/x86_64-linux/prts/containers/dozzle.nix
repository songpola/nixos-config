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
  inherit (lib.${namespace}) mkHomeConfig mkLabels mkContainerWithCaddyNet;
in
  mkHomeConfig (
    mkContainerWithCaddyNet config {
      name = "dozzle";
      image = "docker.io/amir20/dozzle:v8.12.14";
      mountPodmanSocket = true;
    } {
      containerConfig = {
        environments = {
          DOZZLE_ENABLE_ACTIONS = "true";
        };
        labels = mkLabels ''
          caddy=dozzle.songpola.dev
          caddy.reverse_proxy={{upstreams 8080}}
          caddy.reverse_proxy.flush_interval=-1
        '';
      };
    }
  )
