{
  inputs = {
    # determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";

    # https://nixos.org/manual/nixpkgs/stable/
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11"; # https://github.com/NixOS/nixpkgs/tree/nixos-24.11
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable"; # https://github.com/NixOS/nixpkgs/tree/nixos-unstable
    # unstable-small.url = "nixpkgs/nixos-unstable-small"; # https://github.com/NixOS/nixpkgs/tree/nixos-unstable-small

    # https://snowfall.org/reference/lib/
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
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
      inputs.nixpkgs.follows = "nixpkgs";
    };

    opnix = {
      url = "github:brizzbuzz/opnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    deploy-rs = {
      url = "github:serokell/deploy-rs";
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
          ];
        homes.modules = [
          opnix.homeManagerModules.default
          sops-nix.homeManagerModules.sops
        ];
      })
      // {
        deploy.nodes = self.lib.machines.prts.mkDeployNodeConfig self;

        checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
      };
}
