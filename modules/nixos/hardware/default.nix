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
  inherit (lib) mkIf mkEnableOption;
  this = builtins.baseNameOf ./.;
  cfg = config.${namespace}.${this};
in {
  options.${namespace}.${this} = {
    nvidia = {
      enable = mkEnableOption "profile for NVIDIA hardwares";
      useProprietaryKernelModule = mkEnableOption "the proprietary kernel module instead of the open-source one";
    };
  };
  config = mkIf cfg.nvidia.enable {
    services.xserver.videoDrivers = ["nvidia"];

    # auto enable by nvidia-container-toolkit if needed
    # https://github.com/NixOS/nixpkgs/blob/5115ec98d541f12b7b14eb0b91626cddaf3ae5b7/nixos/modules/services/hardware/nvidia-container-toolkit/default.nix#L123
    #
    # hardware.graphics.enable = true;

    hardware.nvidia.open = !cfg.nvidia.useProprietaryKernelModule;
  };
}
