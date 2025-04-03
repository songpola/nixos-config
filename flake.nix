{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-24.11";
    unstable.url = "nixpkgs/nixos-unstable";

    # https://snowfall.org/reference/lib/
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # https://nix-community.github.io/home-manager/
    home-manager = {
      url = "home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # https://github.com/nix-community/disko
    disko = {
      url = "disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # https://github.com/nix-community/nixos-facter
    # https://github.com/nix-community/nixos-facter-modules
    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";

    nixos-wsl = {
      # https://nix-community.github.io/NixOS-WSL/
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    inputs.snowfall-lib.mkFlake {
      inherit inputs;
      src = ./.;
      snowfall.namespace = "songpola";
      systems.modules.nixos = with inputs;
        map (input: input.nixosModules.default) [
          disko
          nixos-wsl
        ]
        ++ [
          nixos-facter-modules.nixosModules.facter
        ];
    };
}
