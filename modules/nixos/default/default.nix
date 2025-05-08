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
  inherit (lib) mkOption;
  inherit (lib.${namespace}) sshPublicKey mkHomeConfig;
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
  config =
    {
      system.stateVersion = cfg.stateVersions.system;

      snowfallorg.users.${namespace}.admin = true;

      users.users.${namespace}.openssh.authorizedKeys.keys = [sshPublicKey];

      time.timeZone = "Asia/Bangkok";

      security = {
        sudo.wheelNeedsPassword = false;
        polkit.enable = true;
      };

      programs.nix-ld.enable = true;

      nix = {
        channel.enable = false;

        settings = {
          experimental-features = ["nix-command" "flakes" "pipe-operators"];

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

      # https://github.com/DeterminateSystems/determinate/pull/57
      #
      # Push the user's nix.conf into /etc/nix/nix.custom.conf,
      # leaving determinate-nixd to manage /etc/nix/nix.conf
      # environment.etc."nix/nix.conf".target = "nix/nix.custom.conf";
    }
    // mkHomeConfig {
      home.stateVersion = cfg.stateVersions.home;
      xdg.enable = true;
      programs.nh.enable = true;
    };
}
