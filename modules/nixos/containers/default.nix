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
  inherit (lib) mkIf mkEnableOption mkMerge optionals;
  inherit (lib.${namespace}) mkHomeConfig;
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
      # dockerCompat = mkDefaultEnableOption "Podman as Docker drop-in replacement";
    };

    tools = {
      enable =
        mkEnableOption "tools for managing containers"
        // {
          default = !config.wsl.enable;
        };
      lazydocker =
        mkEnableOption "Lazydocker"
        // {
          default = cfg.docker;
        };
      podman-tui =
        mkEnableOption "Podman Terminal UI"
        // {
          default = cfg.podman.enable;
        };
    };
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
        virtualisation = {
          # Note: When on WSL, configure the Podman client to communicate with the remote Podman machine defined by Podman Desktop.
          # See: https://podman-desktop.io/docs/podman/accessing-podman-from-another-wsl-instance
          podman = {
            enable = true;
            dockerCompat = true;
          };

          containers.storage.settings = mkIf cfg.useZfsStorageDriver {
            storage = {
              driver = "zfs";
            };
            storage.options.zfs = {
              fsname = "tank/podman";
            };
          };
        };

        users = {
          # users.${namespace}.extraGroups = ["podman"];

          # In order for the socket to work when the user is not logged in
          users.${namespace}.linger = mkIf (!config.wsl.enable) true;

          # The communication channel between your WSL distribution and the Podman Machine is a special file (a socket).
          # The Podman Machine creates this file with specific permissions.
          # To communicate with the Podman Machine from your WSL distribution your user must have write permissions for the socket.
          #
          # On the Podman Machine, which runs on a Fedora distribution:
          # Rootful Podman: GID 10 name is wheel.
          # Rootless Podman: GID 1000 name is user.
          groups = mkIf (config.wsl.enable) {
            podman-machine-wheel = {
              gid = 10;
              members = [namespace];
            };
            podman-machine-user = {
              gid = 1000;
              members = [namespace];
            };
          };
        };
      }
      // mkHomeConfig {
        home.packages = with pkgs; [
          podman-compose
        ];
      })
    (mkIf cfg.tools.enable (mkHomeConfig {
      home.packages = with pkgs;
        (optionals cfg.tools.lazydocker [lazydocker])
        ++ (optionals cfg.tools.podman-tui [podman-tui]);
    }))
  ]);
}
