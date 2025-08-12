{
  delib,
  ...
}:
delib.module {
  name = "nushell";

  options = delib.singleEnableOption false;

  home.ifEnabled = {
    programs.nushell.enable = true;
  };
}
