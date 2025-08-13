{
  delib,
  pkgs,
  ...
}:
delib.module {
  name = "nodejs.corepack";

  options = delib.singleEnableOption false;

  nixos.ifEnabled = delib.ifParentEnabled "nodejs" {
    environment.systemPackages = [ pkgs.corepack ];
  };
}
