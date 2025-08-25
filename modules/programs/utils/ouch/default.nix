{
  delib,
  packagesPath,
  pkgs,
  ...
}:
delib.mkProgramModule {
  name = "ouch";

  package = pkgs.callPackage "${packagesPath}/ouch.nix" { };
}
