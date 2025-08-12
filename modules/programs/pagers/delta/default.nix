{
  delib,
  pkgs,
  ...
}:
delib.module {
  # delta - a syntax-highlighting pager for git, diff, grep, and blame output
  # https://github.com/dandavison/delta
  name = "delta";

  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    environment.systemPackages = [ pkgs.delta ];
  };
}
