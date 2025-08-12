{
  delib,
  pkgs,
  ...
}:
delib.module {
  name = "just";

  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    environment.systemPackages = [ pkgs.just ];
  };
}
