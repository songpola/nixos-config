{
  description = "songpola's NixOS-WSL config";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-24.11";
    unstable.url = "nixpkgs/nixos-unstable";
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
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
  };

  outputs = inputs:
    inputs.snowfall-lib.mkFlake rec {
      inherit inputs;
      src = ./.;

      snowfall.namespace = "songpola";

      channels-config.allowUnfree = true;

      systems.hosts = with inputs; {
        ada-docker.modules = [disko.nixosModules.disko];
        desktop-nixos.modules = [nixos-wsl.nixosModules.default];
      };

      alias = {
        shells.default = "ssh-wsl";
      };
    };
}
