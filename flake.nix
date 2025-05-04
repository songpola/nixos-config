{
  inputs = {
    # determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";

    flake-compat.url = "https://flakehub.com/f/edolstra/flake-compat/1.tar.gz";
    flake-utils.url = "github:numtide/flake-utils";
    flake-utils-plus = {
      url = "github:gytis-ivaskevicius/flake-utils-plus";
      inputs.flake-utils.follows = "flake-utils";
    };

    # https://nixos.org/manual/nixpkgs/stable/
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11"; # https://github.com/NixOS/nixpkgs/tree/nixos-24.11
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable"; # https://github.com/NixOS/nixpkgs/tree/nixos-unstable
    # unstable-small.url = "nixpkgs/nixos-unstable-small"; # https://github.com/NixOS/nixpkgs/tree/nixos-unstable-small

    # https://snowfall.org/reference/lib/
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils-plus.follows = "flake-utils-plus";
        flake-compat.follows = "flake-compat";
      };
    };

    # https://nix-community.github.io/home-manager/
    home-manager = {
      # https://github.com/nix-community/home-manager
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      # https://github.com/nix-community/disko
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-facter-modules.url = "github:nix-community/nixos-facter-modules";

    # https://nix-community.github.io/NixOS-WSL/
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "flake-compat";
      };
    };

    opnix = {
      url = "github:brizzbuzz/opnix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        utils.follows = "flake-utils";
        flake-compat.follows = "flake-compat";
      };
    };

    quadlet-nix = {
      # TODO: waiting for PR to be merged
      # https://github.com/SEIAROTg/quadlet-nix/pull/26
      # https://github.com/SEIAROTg/quadlet-nix/pull/27
      url = "github:songpola/quadlet-nix/merged";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    with inputs;
      (snowfall-lib.mkFlake {
        inherit inputs;
        src = ./.;
        snowfall.namespace = "songpola";
        channels-config.allowUnfree = true;
        systems.modules.nixos =
          map (input: input.nixosModules.default) [
            # determinate
            disko
            nixos-wsl
            opnix
            sops-nix
          ]
          ++ [
            nixos-facter-modules.nixosModules.facter
            quadlet-nix.nixosModules.quadlet
          ];
        homes.modules = [
          opnix.homeManagerModules.default
          sops-nix.homeManagerModules.sops
          quadlet-nix.homeManagerModules.quadlet
        ];
      })
      // {
        deploy.nodes = self.lib.mkDeployNodes self {
          prts = {
            hostname = "prts.tail7623c.ts.net";
            remoteBuild = true;
          };
          podman-lab.hostname = "podman-lab.tail7623c.ts.net";
        };

        checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
      };
}
