{
  # # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # # as well as the libraries available from your flake's inputs.
  lib,
  # # An instance of `pkgs` with your overlays and packages applied is also available.
  # pkgs,
  # # You also have access to your flake's inputs.
  # inputs,
  # # Additional metadata is provided by Snowfall Lib.
  namespace, # The namespace used for your flake, defaulting to "internal" if not set.
  # system, # The system architecture for this host (eg. `x86_64-linux`).
  # target, # The Snowfall Lib target for this system (eg. `x86_64-iso`).
  # format, # A normalized name for the system target (eg. `iso`).
  # virtual, # A boolean to determine whether this system is a virtual target using nixos-generators.
  # systems, # An attribute map of your defined hosts.
  # # All other arguments come from the system system.
  config,
  ...
} @ args: let
  getMountpoint = disk: partition:
    config.disko.devices.disk.${disk}.content.partitions.${partition}.content.mountpoint;
  authorizedKeys = [
    lib.${namespace}.sshPublicKey
  ];
in {
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
    ./zramSwap.nix
    ./networking.nix
    ./zfs.nix
    ./services.nix
    (import ./nix.nix args)
  ];

  security.sudo.wheelNeedsPassword = false;

  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = getMountpoint "main" "ESP";
    };
    grub = {
      device = "nodev";
      efiSupport = true;
    };
  };

  time.timeZone = "Asia/Bangkok";

  users.users = {
    root.openssh.authorizedKeys.keys = authorizedKeys;
    songpola = {
      openssh.authorizedKeys.keys = authorizedKeys;
      extraGroups = ["docker" "libvirtd"];
    };
  };

  virtualisation = {
    docker = {
      enable = true;
      storageDriver = "zfs";
    };
    libvirtd.enable = true;
  };

  system.stateVersion = "24.11";
}
