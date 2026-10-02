{ den, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      # Exposes flake apps under the name of each host / home for building with nh.
      packages = den.lib.nh.denPackages { fromFlake = true; } pkgs;
    };
}
