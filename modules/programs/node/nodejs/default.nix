{
  delib,
  pkgs,
  ...
}:
delib.module {
  name = "nodejs";

  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    environment.systemPackages = [ pkgs.nodejs ];
  };
}
