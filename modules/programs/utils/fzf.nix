{
  delib,
  host,
  pkgs,
  ...
}:
delib.module {
  # fzf - a command-line fuzzy finder
  # https://github.com/junegunn/fzf
  name = "fzf";

  options = delib.singleEnableOption host.stdenvFeatured;

  nixos.ifEnabled = {
    environment.systemPackages = [ pkgs.fzf ];
  };

  home.ifEnabled = {
    programs.fzf.enable = true;
  };
}
