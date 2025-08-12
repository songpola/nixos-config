{
  delib,
  pkgs,
  ...
}:
delib.module {
  # Nix LSP
  name = "nil";

  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    environment.systemPackages = [ pkgs.nil ];
  };
}
