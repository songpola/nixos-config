{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-wsl.url = "github:nix-community/NixOS-WSL";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
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

            ./modules/enable-flakes.nix

            ./modules/minimal.nix

            ./modules/dev/nix.nix
            ./modules/dev/node.nix
            ./modules/dev/vscode-remote.nix

            # ./modules/alt/userborn.nix

            ./modules/home-manager.nix
          ];
        };
      };
    };
}
