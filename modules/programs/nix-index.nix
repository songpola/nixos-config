{ inputs, ... }:
{
  # Needs a new release to support Nushell (Latest check: 2026-09-30)
  # https://github.com/nix-community/nix-index/issues/287
  flake-file.inputs.nix-index-database = {
    url = "github:nix-community/nix-index-database/";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.programs.nix-index = {
    nixos = {
      imports = [ inputs.nix-index-database.nixosModules.default ];

      programs.nix-index.enable = true;
    };

    homeManager = {
      imports = [ inputs.nix-index-database.homeModules.default ];

      programs.nix-index.enable = true;
    };
  };
}
