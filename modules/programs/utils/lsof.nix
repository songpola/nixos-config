{
  delib,
  pkgs,
  ...
}:
delib.module {
  name = "lsof";

  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    environment.systemPackages = [ pkgs.lsof ];
  };
}
