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
  inherit (lib.${namespace}) mkHomeConfig mkLabels;
in
  {
    services.resolved = {
      llmnr = "false"; # no need for LLMNR
      extraConfig = ''
        DNSStubListener=no
      '';
    };
    networking = {
      nameservers = ["127.0.0.1"]; # Use AdGuard Home as DNS server
      firewall = {
        allowedTCPPorts = [
          53 # DNS
          853 # DoT
        ];
        allowedUDPPorts = [
          53 # DNS
          853 # DoQ
        ];
      };
    };
  }
  // mkHomeConfig {
    virtualisation.quadlet = {
      containers = {
        adguardhome = {
          containerConfig = {
            image = "docker.io/adguard/adguardhome:v0.107.61";
            publishPorts = [
              "53:53" # DNS
              "53:53/udp" # DNS
              "853:853" # DoT
              "853:853/udp" # DoQ
              "8080:80" # Web UI
            ];
            environments = {
              TZ = "Asia/Bangkok";
            };
            volumes = [
              "/tank/songpola/adguardhome/conf:/opt/adguardhome/conf" # app configuration
              "/tank/songpola/adguardhome/work:/opt/adguardhome/work" # app working directory
            ];
            labels = mkLabels ''
              caddy=adguardhome.songpola.dev
              caddy.reverse_proxy=host.containers.internal:8080
            '';
          };
        };
      };
    };
  }
