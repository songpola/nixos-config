{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-24.11";
    unstable.url = "nixpkgs/nixos-unstable";

    # https://snowfall.org/reference/lib/
    snowfall-lib.url = "github:snowfallorg/lib";
    snowfall-lib.inputs.nixpkgs.follows = "nixpkgs";

    # https://nix-community.github.io/home-manager/
    home-manager.url = "home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # https://nix-community.github.io/haumea/
    haumea.url = "github:nix-community/haumea/v0.2.2";
    haumea.inputs.nixpkgs.follows = "nixpkgs";

    # https://github.com/nix-community/disko
    disko.url = "disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    # https://nix-community.github.io/NixOS-WSL/
    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";

    # https://github.com/Mic92/sops-nix
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs:
    inputs.snowfall-lib.mkFlake {
      inherit inputs;
      src = ./src;

      systems.modules.nixos = with inputs;
        map (input: input.nixosModules.default) [
          disko
          nixos-wsl
        ];

      homes.modules = with inputs; [
        sops-nix.homeManagerModules.sops
      ];
    };
}
