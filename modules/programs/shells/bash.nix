{
  delib,
  host,
  ...
}:
delib.module {
  name = "bash";

  options = delib.singleEnableOption host.minienvFeatured;

  home.ifEnabled = {
    programs.bash.enable = true;
  };
}
