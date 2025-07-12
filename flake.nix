{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    snowfall-lib.url = "github:snowfallorg/lib";
    snowfall-lib.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    nixos-facter-modules.url = "github:nix-community/nixos-facter-modules";
  };

  outputs =
    inputs:
    inputs.snowfall-lib.mkFlake {
      inherit inputs;
      src = ./src;

      # Will be used as the default user for all systems
      snowfall.namespace = "songpola";

      # Allow unfree packages in all systems
      channels-config.allowUnfree = true;

      # Add modules to all NixOS systems
      systems.modules.nixos = with inputs; [
        nixos-wsl.nixosModules.default
        disko.nixosModules.default
        nixos-facter-modules.nixosModules.facter
      ];

      templates = {
        devshell.description = "A template for per-project development environments using hercules-ci/flake-parts and numtide/devshell.";
      };

      alias = {
        templates.default = "devshell";
      };
    };
}
