{
  delib,
  pkgs,
  ...
}:
delib.module {
  # fzf - a command-line fuzzy finder
  # https://github.com/junegunn/fzf
  name = "fzf";

  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    environment.systemPackages = [ pkgs.fzf ];
  };

  home.ifEnabled = {
    programs.fzf.enable = true;
  };
}
