{
  # See ./home-manager.md for why `useUserPackages` matters.
  den.default.nixos.home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
  };
}
