{
  delib,
  host,
  ...
}:
delib.module {
  # zoxide - a smarter cd command
  # https://github.com/ajeetdsouza/zoxide
  name = "zoxide";

  options = delib.singleEnableOption host.stdenvFeatured;

  nixos.ifEnabled = {
    programs.zoxide.enable = true;
  };

  home.ifEnabled = {
    programs.zoxide.enable = true;
  };
}
