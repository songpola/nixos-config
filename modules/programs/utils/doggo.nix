{
  delib,
  pkgs,
  ...
}:
delib.module {
  name = "doggo";

  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    environment.systemPackages = [ pkgs.doggo ];
  };
}
