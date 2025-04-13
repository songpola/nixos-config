{
  inputs = {
    # determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";

    # https://nixos.org/manual/nixpkgs/stable/
    nixpkgs.url = "nixpkgs/nixos-24.11"; # https://github.com/NixOS/nixpkgs/tree/nixos-24.11
    unstable.url = "nixpkgs/nixos-unstable"; # https://github.com/NixOS/nixpkgs/tree/nixos-unstable
    # unstable-small.url = "nixpkgs/nixos-unstable-small"; # https://github.com/NixOS/nixpkgs/tree/nixos-unstable-small

    # https://snowfall.org/reference/lib/
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # https://nix-community.github.io/home-manager/
    home-manager = {
      # https://github.com/nix-community/home-manager
      url = "home-manager/release-24.11";
      inputs.nixpkgs.follows = "unstable";
    };

    disko = {
      # https://github.com/nix-community/disko
      url = "disko";
      inputs.nixpkgs.follows = "unstable";
    };

    nixos-facter-modules.url = "github:nix-community/nixos-facter-modules";

    # https://nix-community.github.io/NixOS-WSL/
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    opnix = {
      url = "github:brizzbuzz/opnix";
      inputs.nixpkgs.follows = "unstable";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "unstable";
    };

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "unstable";
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
        deploy = let
          mkDeployNodes = self.lib.deploy.mkDeployNodes self;
        in {
          nodes = mkDeployNodes {
            # nixos-vmw = {
            #   hostname = "192.168.146.128";
            #   fastConnection = true;
            # };
            prts = {
              hostname = "prts.tail7623c.ts.net";
              remoteBuild = true;
            };
          };
        };
        checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
      };
}
