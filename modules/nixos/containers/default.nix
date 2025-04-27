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
  inherit (lib) mkIf mkEnableOption mkMerge;
  inherit (lib.${namespace}) mkHomeConfig mkDefaultEnableOption;
  this = builtins.baseNameOf ./.;
  cfg = config.${namespace}.${this};
in {
  options.${namespace}.${this} = {
    enable = mkEnableOption "Container support";

    enableNvidiaGPU =
      mkEnableOption "NVIDIA GPU support for containers"
      // {
        default = config.${namespace}.hardware.nvidia.enable;
      };

    useZfsStorageDriver = mkEnableOption "ZFS as the storage driver for containers";

    docker = mkEnableOption "Docker support";

    podman = {
      enable = mkEnableOption "Podman support";
      dockerCompat = mkDefaultEnableOption "Podman as Docker drop-in replacement";
    };

    lazydocker = mkDefaultEnableOption "Lazydocker tool";
  };
  config = mkIf cfg.enable (mkMerge [
    (mkIf cfg.enableNvidiaGPU {
      hardware.nvidia-container-toolkit.enable = true;
    })
    (mkIf cfg.docker {
      # Don't install Docker on WSL
      virtualisation.docker.enable = mkIf (!config.wsl.enable) true;
      # Use Docker Desktop instead
      wsl.docker-desktop.enable = true;

      users.users.${namespace}.extraGroups = ["docker"];

      virtualisation.docker.storageDriver = mkIf cfg.useZfsStorageDriver "zfs";
    })
    (mkIf cfg.podman.enable {
      # TODO: Add WSL support
      virtualisation.podman.enable = true;

      environment.systemPackages = [
        pkgs.passt # rootless networking tool (pasta)
      ];

      # users.users.${namespace}.extraGroups = ["podman"];

      virtualisation.containers.storage.settings = mkIf cfg.useZfsStorageDriver {
        storage = {
          driver = "zfs";
        };
        storage.options.zfs = {
          fsname = "tank/podman";
        };
      };
    })
    (mkIf cfg.lazydocker (
      mkHomeConfig {
        home.packages = [pkgs.lazydocker];
      }
    ))
  ]);
}
