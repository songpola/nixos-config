{
  delib,
  host,
  ...
}:
delib.module {
  name = "carapace";

  options = delib.singleEnableOption host.stdenvFeatured;

  home.ifEnabled = {
    programs.carapace.enable = true;
  };
}
