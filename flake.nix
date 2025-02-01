{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-24.11";

    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    snowfall-flake = {
      url = "github:snowfallorg/flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    inputs.snowfall-lib.mkFlake {
      inherit inputs;
      src = ./.;

      snowfall = {
        namespace = "songpola";
      };

      overlays = with inputs; [
        snowfall-flake.overlays.default
      ];

      systems.hosts = with inputs; {
        prts.modules = [
          disko.nixosModules.default
        ];

        doctor.modules = [
          nixos-wsl.nixosModules.default
        ];
      };
    }
    // {
      deploy.nodes.prts = {
        hostname = "192.168.146.128";
        profiles.system = with inputs; {
          user = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.prts;
        };
      };

      # This is highly advised, and will prevent many possible mistakes
      checks = with inputs; builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    };
}
