{
  delib,
  pkgs,
  ...
}:
delib.module {
  name = "bun";

  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    environment.systemPackages = [ pkgs.bun ];
  };
}
