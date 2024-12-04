{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib,
  # An instance of `pkgs` with your overlays and packages applied is also available.
  pkgs,
  # You also have access to your flake's inputs.
  # inputs,
  # Additional metadata is provided by Snowfall Lib.
  # system, # The system architecture for this host (eg. `x86_64-linux`).
  # target, # The Snowfall Lib target for this system (eg. `x86_64-iso`).
  # format, # A normalized name for the system target (eg. `iso`).
  # virtual, # A boolean to determine whether this system is a virtual target using nixos-generators.
  # systems, # An attribute map of your defined hosts.
  # All other arguments come from the system system.
  config,
  ...
}: let
  get-mountpoint = name: config.disko.devices.disk.main.content.partitions.${name}.content.mountpoint;
in {
  system.stateVersion = "24.05";

  # Disable nh for this host; use another host to update configuration
  # programs.nh = {
  #   enable = true;
  #   flake = with config; users.users.songpola.home + "/nixos-config";
  # };

  networking.hostName = lib.snowfall.system.get-inferred-system-name ./.;

  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
  ];

  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = get-mountpoint "ESP";
    };
    grub = {
      efiSupport = true;
      device = "nodev";
    };
  };

  time.timeZone = "Asia/Bangkok";

  services = {
    openssh.enable = true;
    qemuGuest.enable = true;
    # resolved = {
    #   enable = true;
    #   fallbackDns = ["10.0.0.1"];
    # };
    tailscale = {
      enable = true;
      openFirewall = true;
    };
  };

  users.users = {
    # root.openssh.authorizedKeys.keys = [lib.songpola.ssh-key];
    songpola = {
      isNormalUser = true;
      extraGroups = ["wheel" "docker"];
      openssh.authorizedKeys.keys = [lib.songpola.ssh-key];
      shell = pkgs.nushell;
    };
  };

  security.sudo.wheelNeedsPassword = false;

  virtualisation.docker.enable = true;

  fileSystems."/mnt/ada-truenas" = {
    device = "ada-truenas:/mnt/main/home/songpola/nfs/ada-docker";
    fsType = "nfs";
    options = [
      # NFSv4.2
      "nfsvers=4.2"
      # Lazy-mounting
      "x-systemd.automount"
      "noauto"
      # Disconnects after 10 minutes (i.e. 600 seconds)
      "x-systemd.idle-timeout=600"
    ];
  };
}
