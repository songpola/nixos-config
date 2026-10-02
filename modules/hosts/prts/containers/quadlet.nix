{ inputs, ... }:
{
  # Uncomment when enabling quadlet
  # flake-file.inputs.quadlet-nix.url = "github:SEIAROTg/quadlet-nix";

  den.aspects.programs.quadlet = {
    nixos =
      { pkgs, ... }:
      {
        imports = [ inputs.quadlet-nix.nixosModules.quadlet ];

        virtualisation.quadlet.enable = true;
      };
  };
}
