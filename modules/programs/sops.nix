{ inputs, ... }:
{
  # Uncomment when enabling sops
  # flake-file.inputs.sops-nix = {
  #   url = "github:Mic92/sops-nix";
  #   inputs.nixpkgs.follows = "nixpkgs";
  # };

  den.aspects.programs.sops.nixos = {
    imports = [ inputs.sops-nix.nixosModules.default ];
  };
}
