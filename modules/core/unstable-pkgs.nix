{ inputs, ... }:
{
  den.default.nixos =
    { config, ... }:
    {
      nixpkgs.overlays = [
        (final: prev: {
          # Re-import (rather than `legacyPackages`) so unstable inherits the
          # host's nixpkgs config, e.g. `allowUnfree`.
          unstable = import inputs.unstable {
            inherit (final.stdenv.hostPlatform) system;
            inherit (config.nixpkgs) config;
          };
        })
      ];
    };
}
