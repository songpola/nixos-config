{
  delib,
  ...
}:
delib.module {
  name = "carapace";

  options = delib.singleEnableOption false;

  home.ifEnabled = {
    programs.carapace.enable = true;
  };
}
