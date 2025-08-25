{
  delib,
  pkgs,
  ...
}:
delib.module {
  name = "duf";

  options = delib.singleEnableOption false;

  nixos.ifEnabled.environment.systemPackages = [ pkgs.duf ];
}
