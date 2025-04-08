{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib,
  # An instance of `pkgs` with your overlays and packages applied is also available.
  pkgs,
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
  inherit (lib) mkEnableOption mkIf;
  inherit (lib.${namespace}) mkHomeConfig;
  this = builtins.baseNameOf ./.;
  cfg = config.${namespace}.${this};
in {
  options.${namespace}.${this} = {
    enable = mkEnableOption "Syncthing";
  };
  config = mkIf cfg.enable ({
      networking.firewall = {
        allowedTCPPorts = [
          8384 # GUI
          22000 # TCP based sync protocol traffic
        ];
        allowedUDPPorts = [
          # 21027 # for discovery broadcasts on IPv4 and multicasts on IPv6
          22000 # QUIC based sync protocol traffic
        ];
      };
    }
    // mkHomeConfig {
      services.syncthing = {
        enable = true;
        extraOptions = [
          "--gui-address=0.0.0.0:8384"
        ];
      };
    });
}
