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
  inherit (lib) mkOption;
  inherit (lib.${namespace}) public;
  cfg = config.${namespace};
in {
  options.${namespace} = {
    stateVersions = {
      system = mkOption {
        type = lib.types.str;
        example = "24.11";
        description = "System state version";
      };
      home = mkOption {
        type = lib.types.str;
        example = "24.11";
        description = "Home Manager state version";
      };
    };
  };
  config = {
    system.stateVersion = cfg.stateVersions.system;

    snowfallorg.users.${namespace} = {
      admin = true;
      home.config = {
        home.stateVersion = cfg.stateVersions.home;
        programs.nh.enable = true;
      };
    };

    users.users.${namespace}.openssh.authorizedKeys.keys = [public.ssh];

    time.timeZone = "Asia/Bangkok";

    security.sudo.wheelNeedsPassword = false;

    programs.nix-ld.enable = true;

    nix = {
      # flake-utils-plus
      generateNixPathFromInputs = true;
      generateRegistryFromInputs = true;
      linkInputs = true;

      settings = {
        # To prevent the `error: cannot ... because it lacks a signature by a trusted key`
        trusted-users = ["@wheel"];

        substituters = [
          "https://nix-community.cachix.org"
        ];
        trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
      };
    };
  };
}
