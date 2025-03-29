{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-24.11";
    unstable.url = "nixpkgs/nixos-unstable";

    snowfall-lib = {
      # https://snowfall.org/reference/lib/
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      # https://nix-community.github.io/home-manager/
      url = "home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    haumea = {
      # https://nix-community.github.io/haumea/
      url = "github:nix-community/haumea/v0.2.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      # https://github.com/nix-community/disko
      url = "disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      # https://nix-community.github.io/NixOS-WSL/
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      # https://github.com/Mic92/sops-nix
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    opnix = {
      # https://github.com/brizzbuzz/opnix
      url = "github:brizzbuzz/opnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # https://github.com/nix-community/nixos-facter
    # https://github.com/nix-community/nixos-facter-modules
    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";

    nu_scripts = {
      # https://github.com/nushell/nu_scripts
      url = "github:nushell/nu_scripts";
      flake = false;
    };
  };

  outputs = inputs:
    inputs.snowfall-lib.mkFlake {
      inherit inputs;
      src = ./src;

      channels-config.allowUnfree = true;

      overlays = with inputs; [
        opnix.overlays.default
      ];

      systems.modules.nixos = with inputs;
        (
          map (input: input.nixosModules.default) [
            disko
            nixos-wsl
            sops-nix
            opnix
          ]
        )
        ++ [
          nixos-facter-modules.nixosModules.facter
        ];

      homes.modules = with inputs; [
        sops-nix.homeManagerModules.sops
        opnix.homeManagerModules.default
      ];
    };
}
