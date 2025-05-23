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
  inherit (lib) mkOption mkEnableOption mkIf;
  this = builtins.baseNameOf ./.;
  cfg = config.${namespace}.${this};
in {
  options.${namespace}.${this} = {
    enable = mkEnableOption "ZFS module";
    hostId = mkOption {
      type = lib.types.str;
      # Can be generated with:
      # head -c 8 /etc/machine-id
      # or:
      # head -c 4 /dev/urandom | od -A n -t x4
      example = "9ba97379";
      description = "The host ID for ZFS.";
    };
  };
  config = mkIf cfg.enable {
    networking.hostId = cfg.hostId;
    boot = {
      supportedFilesystems = ["zfs"];
      zfs = {
        devNodes = "/dev/disk/by-partlabel";
        forceImportRoot = false;
        extraPools = ["tank"];
      };
    };
    services.zfs = {
      autoScrub.enable = true;
      trim.enable = true;
    };
  };
}
