{
  config,
  inputs,
  lib,
  ...
}:
{
  imports = [
    # Doc: https://flake-file.denful.dev/guides/flake-modules/#flakemodulesdendritic
    inputs.flake-file.flakeModules.dendritic

    # Doc: https://github.com/denful/den/blob/main/nix/dendritic.nix
    inputs.den.flakeModules.dendritic
  ];

  # NixOS release that the stable nixpkgs and release-pinned inputs follow.
  options.stableVersion = lib.mkOption {
    type = lib.types.str;
    default = "26.05";
    description = "NixOS release used by stable nixpkgs and release-pinned inputs.";
  };

  # other inputs may be defined at a module using them.
  config.flake-file.inputs = {
    # Stable Nixpkgs (main)
    stable.url = "github:NixOS/nixpkgs/nixos-${config.stableVersion}";
    # Unstable Nixpkgs (only use for unstable packages)
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Use stable nixpkgs by default for everything
    # NOTE: need mkForce because there's a mkDefault in the flake-file module
    # https://github.com/denful/flake-file/blob/main/modules/dendritic/nixpkgs.nix
    nixpkgs = lib.mkForce { follows = "stable"; };

    home-manager = {
      url = "github:nix-community/home-manager/release-${config.stableVersion}";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
