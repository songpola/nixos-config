{ inputs, ... }:
{
  den.default.nixos =
    { pkgs, ... }:
    {
      nixpkgs.overlays = [
        (final: prev: {
          unstable = inputs.unstable.legacyPackages.${final.stdenv.hostPlatform.system};
        })
      ];
    };
}
