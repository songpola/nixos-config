{
  delib,
  pkgs,
  ...
}:
delib.module {
  name = "dust";

  options = delib.singleEnableOption false;

  nixos.ifEnabled.environment.systemPackages = [ pkgs.dust ];
}
