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
  # All other arguments come from the module system.
  config,
  ...
}: let
  inherit (lib) mkOption mkEnableOption mkIf mkMerge types;
  this = builtins.baseNameOf ./.;
  cfg = config.${namespace}.${this};
in {
  options.${namespace}.${this} = {
    enable = mkEnableOption "network module";
    bridge = {
      enable = mkEnableOption "br0 bridge network";
      interfaces = mkOption {
        type = types.listOf types.str;
        description = "The interfaces to be connected to the bridge.";
      };
    };
  };
  config = mkIf cfg.enable (mkMerge [
    {
      networking.nftables.enable = true;
    }
    (mkIf cfg.bridge.enable {
      # These are defaulted to true by nixos-facter-modules
      networking = {
        useDHCP = false;
        useNetworkd = false;
      };
      systemd.network = {
        enable = true;
        netdevs = {
          "25-br0" = {
            netdevConfig = {
              Name = "br0";
              Kind = "bridge";
              MACAddress = "b4:2e:99:91:b1:10"; # eno1
            };
          };
        };
        networks = {
          "25-br0" = {
            matchConfig = {
              Name = "br0";
            };
            networkConfig = {
              DHCP = "yes";
              UseDomains = "yes";
            };
            linkConfig = {
              RequiredForOnline = "routable";
            };
          };
          "25-br0-interfaces" = {
            matchConfig = {
              Name = cfg.bridge.interfaces;
            };
            networkConfig = {
              Bridge = "br0";
            };
            linkConfig = {
              RequiredForOnline = "enslaved";
            };
          };
        };
        links = {
          "25-br0" = {
            matchConfig = {
              OriginalName = "br0";
            };
            linkConfig = {
              MACAddressPolicy = "none";
            };
          };
        };
      };
    })
  ]);
}
