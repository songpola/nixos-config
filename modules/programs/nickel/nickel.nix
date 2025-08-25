{ delib, pkgs, ... }:
delib.module {
  name = "nickel";

  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    environment.systemPackages = [ pkgs.nickel ];
  };
}
