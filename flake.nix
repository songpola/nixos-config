{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixos-wsl.url = "github:nix-community/NixOS-WSL";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    haumea.url = "github:nix-community/haumea/v0.2.2";
    haumea.inputs.nixpkgs.follows = "nixpkgs";

    snowfall-lib.url = "github:snowfallorg/lib";
    snowfall-lib.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nixos-wsl,
      home-manager,
      ...
    }:
    {
      nixosConfigurations = {
        nixos = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit self;
          };
          modules = [
            nixos-wsl.nixosModules.default
            home-manager.nixosModules.home-manager

            ./base/wsl.nix

            ./modules/nix-settings.nix

            ./modules/minimal.nix

            ./modules/dev/nix.nix
            ./modules/dev/node.nix
            ./modules/dev/vscode-remote.nix

            ./modules/home-manager.nix
          ];
        };
      };
    }
    // inputs.snowfall-lib.mkFlake {
      inherit inputs;
      src = ./src;

      snowfall.namespace = "songpola";

      # Add modules to all NixOS systems
      systems.modules.nixos = [
        nixos-wsl.nixosModules.default
      ];
    };
}
