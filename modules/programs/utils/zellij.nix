{
  delib,
  pkgs,
  ...
}:
delib.module {
  # zellij - A terminal workspace with batteries included
  # https://github.com/zellij-org/zellij
  name = "zellij";

  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    environment.systemPackages = [ pkgs.zellij ];
  };

  home.ifEnabled = {
    programs.zellij.enable = true;
  };
}
