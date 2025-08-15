{
  delib,
  pkgs,
  ...
}:
delib.module {
  # NixOS/nixfmt: The official Nix formatter
  name = "nixfmt";

  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    environment.systemPackages = [ pkgs.nixfmt-rfc-style ];
  };
}
