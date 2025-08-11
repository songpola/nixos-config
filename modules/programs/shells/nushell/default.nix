{
  delib,
  host,
  ...
}:
delib.module {
  name = "nushell";

  options = delib.singleEnableOption host.minienvFeatured;

  home.ifEnabled = {
    programs.nushell.enable = true;
  };
}
