{
  delib,
  pkgs,
  ...
}:
delib.module {
  # isd – interactive systemd
  # https://github.com/kainctl/isd
  name = "isd";

  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    environment.systemPackages = [ pkgs.isd ];
  };
}
