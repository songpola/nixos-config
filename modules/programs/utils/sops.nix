{
  delib,
  pkgs,
  ...
}:
delib.module {
  name = "sops";

  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    environment.systemPackages = [ pkgs.sops ];
  };
}
