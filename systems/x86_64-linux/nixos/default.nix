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
  inherit (lib.songpola) make-extraBin-from-packages;
in {
  system.stateVersion = "24.05";

  programs.nh = {
    enable = true;
    flake = with config; users.users.${wsl.defaultUser}.home + "/nixos-config";
  };

  wsl = {
    enable = true;
    docker-desktop.enable = true;
    extraBin = make-extraBin-from-packages (with pkgs; [uutils-coreutils-noprefix]);
  };
}
