{
  delib,
  pkgs,
  ...
}:
delib.module {
  name = "ripgrep";

  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    environment.systemPackages = [ pkgs.ripgrep ];
  };
}
