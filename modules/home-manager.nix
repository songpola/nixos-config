{ self, ... }:
{
  # Setup Home Manager
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hmbak";
    users = {
      songpola = self + "/home/songpola.nix";
    };
  };
}
