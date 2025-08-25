{ delib, pkgs, ... }:
delib.module {
  name = "nls";

  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    environment.systemPackages = [ pkgs.nls ];
  };
}
