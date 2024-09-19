{
  description = "songpola's NixOS-WSL config";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-24.05";
    unstable.url = "nixpkgs/nixos-unstable";
    snowfall-lib = {
      url = "github:snowfallorg/lib/v3.0.3";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/2405.5.4";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: let
    stateVersion = "24.05";
  in
    inputs.snowfall-lib.mkFlake rec {
      inherit inputs;
      src = ./.;

      homes.users."nixos@nixos".specialArgs = {
        homeStateVersion = stateVersion;
      };

      systems.hosts.nixos = {
        modules = with inputs; [
          nixos-wsl.nixosModules.default
        ];
        specialArgs = {
          systemStateVersion = stateVersion;
        };
      };
    };
}
