{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  # lib,
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
  # inherit (lib.songpola) make-extraBin-from-packages;
  defaultUser = config.wsl.defaultUser;
in {
  system.stateVersion = "24.05";

  wsl = {
    enable = true;
    docker-desktop.enable = true;
    startMenuLaunchers = true;
  };

  users.users.${defaultUser}.shell = pkgs.nushell;

  programs = {
    nh.flake = config.users.users.${defaultUser}.home + "/nixos-config";
    ssh.package = pkgs.songpola.ssh-wrapper;
    _1password.enable = true;
    _1password-gui = {
      enable = true;
      polkitPolicyOwners = ["${defaultUser}"];
    };
  };

  boot.supportedFilesystems = ["nfs"];
}
